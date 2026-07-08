import SwiftUI
import WebKit

struct PlayerView: View {
    let item: MediaItem
    @State private var season: Int
    @State private var episode: Int
    let server: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(WatchHistoryManager.self) private var watchManager
    
    init(item: MediaItem, season: Int?, episode: Int?, server: String) {
        self.item = item
        self._season = State(initialValue: season ?? 1)
        self._episode = State(initialValue: episode ?? 1)
        self.server = server
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VidSrcWebView(item: item, season: season, episode: episode, server: server)
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)
            
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            
            if item.mediaType == "tv" {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            episode += 1
                            watchManager.logProgress(item: item, season: season, episode: episode)
                        }) {
                            Label("Next Episode", systemImage: "forward.fill")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }
                    Spacer()
                }
            }
        }
        .frame(width: 1000, height: 650)
    }
}

struct VidSrcWebView: NSViewRepresentable {
    let item: MediaItem
    let season: Int
    let episode: Int
    let server: String
    
    func makeNSView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        config.allowsAirPlayForMediaPlayback = true
        
        // Fix for autoplay and fullscreen
        config.mediaTypesRequiringUserActionForPlayback = []
        if #available(macOS 12.0, *) {
            config.preferences.isElementFullscreenEnabled = true
        }
        
        let webView = WKWebView(frame: .zero, configuration: config)
        // Pretend to be standard Safari to avoid WebView blocks
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        var urlString = ""
        
        if server == "VidKing (Primary)" {
            if item.mediaType == "tv" {
                urlString = "https://www.vidking.net/embed/tv/\(item.id)/\(season)/\(episode)?color=e50914&autoPlay=true"
            } else {
                urlString = "https://www.vidking.net/embed/movie/\(item.id)?color=e50914&autoPlay=true"
            }
        } else if server == "VidFast (Secondary)" {
            if item.mediaType == "tv" {
                urlString = "https://vidfast.pro/tv/\(item.id)/\(season)/\(episode)"
            } else {
                urlString = "https://vidfast.pro/movie/\(item.id)"
            }
        } else {
            // Fallback to VidSrc
            if item.mediaType == "tv" {
                urlString = "https://vidsrc.me/embed/tv?tmdb=\(item.id)&season=\(season)&episode=\(episode)"
            } else {
                urlString = "https://vidsrc.me/embed/movie?tmdb=\(item.id)"
            }
        }
        
        if let url = URL(string: urlString) {
            if server == "VidKing (Primary)" {
                let html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                    <style>
                        body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: black; overflow: hidden; }
                        iframe { width: 100%; height: 100%; border: none; }
                    </style>
                </head>
                <body>
                    <iframe src="\(url.absoluteString)" width="100%" height="100%" frameborder="0" allowfullscreen allow="autoplay; fullscreen"></iframe>
                </body>
                </html>
                """
                nsView.loadHTMLString(html, baseURL: URL(string: "https://flixtv.app/"))
            } else {
                var request = URLRequest(url: url)
                // Set a Referer to bypass hotlink protection without needing an iframe
                request.setValue("https://flixtv.app/", forHTTPHeaderField: "Referer")
                nsView.load(request)
            }
        }
    }
}
