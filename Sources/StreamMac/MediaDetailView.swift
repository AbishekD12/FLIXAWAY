import SwiftUI
import SwiftData

struct MediaDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @Environment(WatchHistoryManager.self) private var watchManager
    @Environment(TMDbClient.self) private var tmdbClient
    
    @State private var seriesDetails: TVSeriesDetails?
    @State private var selectedSeason: Int
    @State private var episodes: [TVEpisode] = []
    
    @State private var isPlaying = false
    @State private var episodeToPlay: Int
    
    @State private var selectedServer: String = "VidKing (Primary)"
    let servers = ["VidKing (Primary)", "VidFast (Secondary)", "VidSrc (Fallback)"]
    
    init(item: MediaItem, initialSeason: Int? = nil, initialEpisode: Int? = nil) {
        self.item = item
        self._selectedSeason = State(initialValue: initialSeason ?? 1)
        self._episodeToPlay = State(initialValue: initialEpisode ?? 1)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Main Detail Area
            ZStack(alignment: .topLeading) {
                AsyncImage(url: item.backdropURL ?? item.posterURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(colors: [.black, .clear, .black.opacity(0.8)], startPoint: .bottom, endPoint: .top)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(item.displayTitle)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let overview = item.overview {
                        Text(overview)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(4)
                            .frame(maxWidth: 600, alignment: .leading)
                    }
                    
                    if item.mediaType == "movie" {
                        Button(action: {
                            playMovie()
                        }) {
                            Label("Play Movie", systemImage: "play.fill")
                                .font(.title3)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 20)
                    } else if item.mediaType == "tv" {
                        Button(action: {
                            playEpisode(episodeToPlay)
                        }) {
                            Label("Resume S\(selectedSeason) E\(episodeToPlay)", systemImage: "play.fill")
                                .font(.title3)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 20)
                    }
                    
                    HStack {
                        Text("Server:")
                            .font(.headline)
                            .foregroundColor(.white)
                        Picker("", selection: $selectedServer) {
                            ForEach(servers, id: \.self) { server in
                                Text(server).tag(server)
                            }
                        }
                        .frame(width: 200)
                    }
                    .padding(.top, 10)
                }
                .padding(40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Sidebar for TV Series Episodes
            if item.mediaType == "tv" {
                VStack(spacing: 0) {
                    HStack {
                        Text("Seasons")
                            .font(.headline)
                        Spacer()
                        if let details = seriesDetails {
                            Picker("", selection: $selectedSeason) {
                                ForEach(1...details.numberOfSeasons, id: \.self) { s in
                                    Text("Season \(s)").tag(s)
                                }
                            }
                            .frame(width: 120)
                            .onChange(of: selectedSeason) { _, newSeason in
                                loadEpisodes(for: newSeason)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    
                    List(episodes) { episode in
                        Button(action: {
                            playEpisode(episode.episodeNumber)
                        }) {
                            HStack(alignment: .top, spacing: 12) {
                                AsyncImage(url: episode.stillURL) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 120, height: 68)
                                .cornerRadius(6)
                                .clipped()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(episode.episodeNumber). \(episode.name)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(episode.overview)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.sidebar)
                }
                .frame(width: 350)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(width: 1000, height: 650)
        .task {
            if item.mediaType == "tv" {
                do {
                    seriesDetails = try await tmdbClient.fetchSeriesDetails(id: item.id)
                    // Resume from last watched season if it exists in history
                    // (For simplicity here, just load season 1 or selectedSeason)
                    loadEpisodes(for: selectedSeason)
                } catch {
                    print("Failed to load series details: \(error)")
                }
            }
        }
        .sheet(isPresented: $isPlaying) {
            PlayerView(item: item, season: selectedSeason, episode: episodeToPlay, server: selectedServer)
        }
    }
    
    private func loadEpisodes(for season: Int) {
        Task {
            do {
                let details = try await tmdbClient.fetchSeasonDetails(seriesId: item.id, seasonNumber: season)
                await MainActor.run {
                    self.episodes = details.episodes
                }
            } catch {
                print("Failed to load episodes: \(error)")
            }
        }
    }
    
    private func playMovie() {
        logWatchProgress(season: nil, episode: nil)
        isPlaying = true
    }
    
    private func playEpisode(_ epNum: Int) {
        episodeToPlay = epNum
        logWatchProgress(season: selectedSeason, episode: epNum)
        isPlaying = true
    }
    
    private func logWatchProgress(season: Int?, episode: Int?) {
        watchManager.logProgress(item: item, season: season, episode: episode)
    }
}
