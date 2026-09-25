import Foundation
import Network
import HaltungCore

/// Winziger Loopback-HTTP-Server, der die YouTube-Player-Seite ausliefert.
///
/// Hintergrund: YouTube verweigert die Embed-Wiedergabe (Fehler 152), wenn die Seite
/// per `WKWebView.loadHTMLString` geladen wird, weil die Dokument-Origin dann `null`
/// ist. Wird dieselbe Seite ueber einen echten `http://127.0.0.1:<port>`-Server
/// ausgeliefert, hat sie eine gueltige Origin und der Player laeuft. Die App ist nicht
/// sandboxed, daher ist ein Loopback-Listener problemlos moeglich.
///
/// Der Server bindet ausschliesslich auf `127.0.0.1`, laeuft als Singleton fuer die
/// gesamte App-Laufzeit und liefert pro Request die Player-Seite zur Video-ID aus dem
/// Pfad (`/v/<id>`).
///
/// `@unchecked Sendable`: Der gesamte veraenderliche Zustand (`listener`, `port`) wird
/// ueber `lock` synchronisiert; die Network-Callbacks laufen auf `queue`.
final class YouTubeLocalServer: @unchecked Sendable {
    static let shared = YouTubeLocalServer()

    private let lock = NSLock()
    private var listener: NWListener?
    private var port: UInt16?
    private let queue = DispatchQueue(label: "de.andreclaassen.haltung.ytserver")

    private init() {}

    /// Startet den Server (idempotent) und liefert die lokale Player-URL fuer die
    /// gegebene Video-ID, z.B. `http://127.0.0.1:54123/v/7rnlAVhAK-8`. Liefert nil,
    /// wenn kein Port gebunden werden konnte.
    func playerURL(videoID id: String) -> URL? {
        startIfNeeded()
        lock.lock()
        let boundPort = port
        lock.unlock()
        guard let boundPort else { return nil }
        return URL(string: "http://127.0.0.1:\(boundPort)/v/\(id)")
    }

    private func startIfNeeded() {
        lock.lock()
        if listener != nil {
            lock.unlock()
            return
        }

        // Nur auf Loopback binden, freien Port automatisch waehlen.
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)

        guard let listener = try? NWListener(using: params) else {
            lock.unlock()
            return
        }
        self.listener = listener
        lock.unlock()

        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.lock.lock()
                self.port = listener.port?.rawValue
                self.lock.unlock()
                ready.signal()
            case .failed, .cancelled:
                self.lock.lock()
                self.listener = nil
                self.port = nil
                self.lock.unlock()
                ready.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] conn in
            self?.handle(conn)
        }
        listener.start(queue: queue)

        // Kurz auf die Portvergabe warten, damit playerURL sofort liefern kann.
        _ = ready.wait(timeout: .now() + 2)
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: queue)
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            let id = self?.videoID(fromRequest: data) ?? ""
            let body = self?.responseBody(forVideoID: id) ?? Data()
            let header = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
            var response = Data(header.utf8)
            response.append(body)
            conn.send(content: response, completion: .contentProcessed { _ in conn.cancel() })
        }
    }

    /// Extrahiert die Video-ID aus der ersten Request-Zeile `GET /v/<id> HTTP/1.1`.
    private func videoID(fromRequest data: Data?) -> String? {
        guard let data, let request = String(data: data, encoding: .utf8),
              let firstLine = request.split(separator: "\r\n").first else { return nil }
        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        let path = parts[1]
        return path.split(separator: "/").last.map(String.init)
    }

    private func responseBody(forVideoID id: String) -> Data {
        lock.lock()
        let boundPort = port
        lock.unlock()
        guard let boundPort, !id.isEmpty else { return Data("<html><body></body></html>".utf8) }
        let origin = "http://127.0.0.1:\(boundPort)"
        return Data(YouTubeEmbed.playerHTML(videoID: id, origin: origin).utf8)
    }
}
