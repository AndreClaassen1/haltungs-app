import Foundation

/// Reine, testbare Logik rund um YouTube-Videos: extrahiert die Video-ID aus den
/// gaengigen URL-Formen und baut daraus die Embed-URL fuer einen Inline-Player.
public enum YouTubeEmbed {

    /// Extrahiert die elfstellige YouTube-Video-ID aus den ueblichen URL-Formen:
    /// `youtu.be/<id>`, `youtube.com/watch?v=<id>`, `youtube.com/embed/<id>` und
    /// `youtube.com/shorts/<id>`. Liefert nil, wenn keine ID erkennbar ist.
    public static func videoID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let host = (components.host ?? "").lowercased()

        // youtu.be/<id> — die ID steht im ersten Pfadsegment.
        if host.hasSuffix("youtu.be") {
            return firstPathSegment(components.path)
        }

        guard host.hasSuffix("youtube.com") else { return nil }

        // youtube.com/watch?v=<id>
        if let v = components.queryItems?.first(where: { $0.name == "v" })?.value,
           isValidID(v) {
            return v
        }

        // youtube.com/embed/<id> oder youtube.com/shorts/<id>
        let segments = components.path.split(separator: "/").map(String.init)
        if let marker = segments.firstIndex(where: { $0 == "embed" || $0 == "shorts" }),
           segments.indices.contains(marker + 1),
           isValidID(segments[marker + 1]) {
            return segments[marker + 1]
        }

        return nil
    }

    /// Embed-URL fuer den Inline-Player. `autoplay` startet das Video direkt nach
    /// dem Laden (passt zum Play-Button im Overlay).
    public static func embedURL(from url: URL, autoplay: Bool = true) -> URL? {
        guard let id = videoID(from: url) else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube.com"
        components.path = "/embed/\(id)"
        if autoplay {
            components.queryItems = [URLQueryItem(name: "autoplay", value: "1")]
        }
        return components.url
    }

    /// HTML-Seite mit dem YouTube-Player, erzeugt ueber die **IFrame Player API**.
    ///
    /// Wichtig: Diese Seite muss von einer echten `http(s)`-Origin ausgeliefert werden
    /// (lokaler Loopback-Server), nicht per `WKWebView.loadHTMLString`. Bei
    /// `loadHTMLString` ist die Dokument-Origin `null` — egal welche `baseURL` gesetzt
    /// ist — und YouTube quittiert das mit „Dieses Video ist nicht verfuegbar"
    /// (Fehler 152). Mit einer echten Origin (z.B. `http://127.0.0.1:<port>`), die als
    /// `origin`-PlayerVar wiederholt wird, autorisiert die API die Wiedergabe.
    ///
    /// - Parameter origin: Die Seiten-Origin, unter der das HTML ausgeliefert wird,
    ///   z.B. `http://127.0.0.1:54123`. Wird als `origin`-PlayerVar gesetzt.
    public static func playerHTML(videoID id: String, origin: String, autoplay: Bool = true) -> String {
        let autoplayParam = autoplay ? 1 : 0
        return """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>html,body{margin:0;padding:0;background:transparent;height:100%;overflow:hidden}
        #player{position:absolute;top:0;left:0;width:100%;height:100%}</style></head>
        <body><div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
        function onYouTubeIframeAPIReady() {
          new YT.Player('player', {
            videoId: '\(id)',
            playerVars: {
              autoplay: \(autoplayParam),
              playsinline: 1,
              rel: 0,
              origin: '\(origin)'
            }
          });
        }
        </script></body></html>
        """
    }

    private static func firstPathSegment(_ path: String) -> String? {
        guard let segment = path.split(separator: "/").first.map(String.init),
              isValidID(segment) else { return nil }
        return segment
    }

    /// YouTube-IDs sind elf Zeichen aus `[A-Za-z0-9_-]`.
    private static let idCharacters = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-")

    private static func isValidID(_ candidate: String) -> Bool {
        candidate.count == 11 && candidate.allSatisfy(idCharacters.contains)
    }
}
