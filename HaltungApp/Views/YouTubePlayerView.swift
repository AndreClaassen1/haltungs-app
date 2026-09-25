import SwiftUI
import WebKit
import HaltungCore

/// Bettet ein YouTube-Video als Inline-Player ein. Laedt die Player-Seite ueber einen
/// lokalen Loopback-Server (`YouTubeLocalServer`), damit das Dokument eine echte
/// `http://127.0.0.1`-Origin hat. Wuerde man das HTML per `loadHTMLString` laden, waere
/// die Origin `null` und YouTube lehnt die Wiedergabe mit Fehler 152 ab — unabhaengig
/// von der gesetzten `baseURL`.
struct YouTubePlayerView: NSViewRepresentable {
    /// Quelle des Videos (beliebige YouTube-URL-Form).
    let videoURL: URL

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Inline-Wiedergabe ohne erzwungenes Vollbild, Start per Autoplay-Param.
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        load(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    private func load(into webView: WKWebView) {
        guard let id = YouTubeEmbed.videoID(from: videoURL),
              let url = YouTubeLocalServer.shared.playerURL(videoID: id) else { return }
        webView.load(URLRequest(url: url))
    }
}
