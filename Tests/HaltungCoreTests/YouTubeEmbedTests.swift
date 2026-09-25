import Foundation
import Testing
@testable import HaltungCore

@Suite("YouTubeEmbed")
struct YouTubeEmbedTests {

    @Test("ID aus youtu.be-Kurzlink")
    func shortLink() {
        let url = URL(string: "https://youtu.be/7rnlAVhAK-8")!
        #expect(YouTubeEmbed.videoID(from: url) == "7rnlAVhAK-8")
    }

    @Test("ID aus watch?v=-Link")
    func watchLink() {
        let url = URL(string: "https://www.youtube.com/watch?v=7rnlAVhAK-8&t=42")!
        #expect(YouTubeEmbed.videoID(from: url) == "7rnlAVhAK-8")
    }

    @Test("ID aus embed-Link")
    func embedLink() {
        let url = URL(string: "https://www.youtube.com/embed/7rnlAVhAK-8")!
        #expect(YouTubeEmbed.videoID(from: url) == "7rnlAVhAK-8")
    }

    @Test("ID aus shorts-Link")
    func shortsLink() {
        let url = URL(string: "https://www.youtube.com/shorts/7rnlAVhAK-8")!
        #expect(YouTubeEmbed.videoID(from: url) == "7rnlAVhAK-8")
    }

    @Test("Fremd-URL liefert keine ID")
    func foreignURL() {
        let url = URL(string: "https://vimeo.com/123456789")!
        #expect(YouTubeEmbed.videoID(from: url) == nil)
    }

    @Test("youtu.be ohne ID liefert nil")
    func missingID() {
        let url = URL(string: "https://youtu.be/")!
        #expect(YouTubeEmbed.videoID(from: url) == nil)
    }

    @Test("Embed-URL enthaelt ID und Autoplay")
    func embedURLWithAutoplay() {
        let url = URL(string: "https://youtu.be/7rnlAVhAK-8")!
        let embed = YouTubeEmbed.embedURL(from: url)
        #expect(embed?.absoluteString == "https://www.youtube.com/embed/7rnlAVhAK-8?autoplay=1")
    }

    @Test("Embed-URL ohne Autoplay")
    func embedURLWithoutAutoplay() {
        let url = URL(string: "https://www.youtube.com/watch?v=7rnlAVhAK-8")!
        let embed = YouTubeEmbed.embedURL(from: url, autoplay: false)
        #expect(embed?.absoluteString == "https://www.youtube.com/embed/7rnlAVhAK-8")
    }

    @Test("Embed-URL fuer Fremd-URL ist nil")
    func embedURLForeign() {
        let url = URL(string: "https://example.com/video")!
        #expect(YouTubeEmbed.embedURL(from: url) == nil)
    }

    @Test("Player-HTML nutzt IFrame-API mit Video-ID, Autoplay und Origin")
    func playerHTMLUsesIframeAPI() {
        let html = YouTubeEmbed.playerHTML(videoID: "7rnlAVhAK-8", origin: "http://127.0.0.1:54123")
        #expect(html.contains("https://www.youtube.com/iframe_api"))
        #expect(html.contains("videoId: '7rnlAVhAK-8'"))
        #expect(html.contains("autoplay: 1"))
        #expect(html.contains("origin: 'http://127.0.0.1:54123'"))
    }

    @Test("Player-HTML ohne Autoplay")
    func playerHTMLWithoutAutoplay() {
        let html = YouTubeEmbed.playerHTML(videoID: "7rnlAVhAK-8", origin: "http://127.0.0.1:1", autoplay: false)
        #expect(html.contains("autoplay: 0"))
    }
}
