import SwiftUI
import SwiftData
import WebKit

@main
struct StreamMacApp: App {
    @State private var tmdbClient = TMDbClient()
    @State private var watchManager = WatchHistoryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(tmdbClient)
                .environment(watchManager)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct ContentView: View {
    @Environment(TMDbClient.self) private var tmdbClient
    @State private var selection: SidebarItem? = .home

    enum SidebarItem: Hashable {
        case home
        case search
        case about
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.home) {
                    Label("Home", systemImage: "house.fill")
                }
                NavigationLink(value: SidebarItem.search) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                NavigationLink(value: SidebarItem.about) {
                    Label("About", systemImage: "info.circle")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("StreamMac")
        } detail: {
            switch selection {
            case .home:
                HomeView()
            case .search:
                SearchView()
            case .about:
                AboutView()
            case .none:
                Text("Select an item")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - App State for Player
class PlayerState: ObservableObject {
    @Published var selectedItem: MediaItem?
    @Published var initialSeason: Int?
    @Published var initialEpisode: Int?
    @Published var isPresented = false
    
    func play(_ item: MediaItem, season: Int? = nil, episode: Int? = nil) {
        selectedItem = item
        initialSeason = season
        initialEpisode = episode
        isPresented = true
    }
}

struct HomeView: View {
    @Environment(TMDbClient.self) private var tmdbClient
    @Environment(WatchHistoryManager.self) private var watchManager
    @StateObject private var playerState = PlayerState()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Hero Section
                ZStack(alignment: .bottomLeading) {
                    if let heroItem = tmdbClient.trendingItems.first {
                        AsyncImage(url: heroItem.backdropURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 400)
                        .clipped()
                        .overlay {
                            LinearGradient(colors: [.black, .clear, .black.opacity(0.7)], startPoint: .bottom, endPoint: .top)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(heroItem.displayTitle)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if let overview = heroItem.overview {
                                Text(overview)
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(3)
                                    .frame(maxWidth: 600, alignment: .leading)
                            }
                            
                            Button(action: {
                                playerState.play(heroItem)
                            }) {
                                Label("Play", systemImage: "play.fill")
                                    .font(.headline)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 10)
                        }
                        .padding(40)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 400)
                    }
                }

                // Carousels
                if !watchManager.history.isEmpty {
                    ContinueWatchingCarousel(items: watchManager.history, playerState: playerState)
                }
                
                MediaCarousel(title: "Trending Now", items: tmdbClient.trendingItems, playerState: playerState)
                MediaCarousel(title: "Popular Movies", items: tmdbClient.popularMovies, playerState: playerState)
                MediaCarousel(title: "Popular TV Series", items: tmdbClient.popularSeries, playerState: playerState)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .task {
            if tmdbClient.trendingItems.isEmpty {
                await tmdbClient.fetchHomeData()
            }
        }
        .sheet(isPresented: $playerState.isPresented) {
            if let item = playerState.selectedItem {
                MediaDetailView(item: item, initialSeason: playerState.initialSeason, initialEpisode: playerState.initialEpisode)
            }
        }
    }
}

struct ContinueWatchingCarousel: View {
    let items: [WatchProgress]
    @ObservedObject var playerState: PlayerState
    @Environment(WatchHistoryManager.self) private var watchManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Continue Watching")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 40)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { progress in
                        let item = MediaItem(id: progress.id, title: progress.title, name: nil, overview: nil, posterPath: progress.posterPath, backdropPath: nil, mediaType: progress.mediaType, voteAverage: nil)
                        
                        ZStack(alignment: .topTrailing) {
                            MediaCard(item: item)
                                .onTapGesture {
                                    playerState.play(item, season: progress.lastWatchedSeason, episode: progress.lastWatchedEpisode)
                                }
                                
                            Button(action: {
                                watchManager.removeProgress(id: progress.id)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

struct MediaCarousel: View {
    let title: String
    let items: [MediaItem]
    @ObservedObject var playerState: PlayerState

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 40)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        MediaCard(item: item)
                            .onTapGesture {
                                playerState.play(item)
                            }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

struct MediaCard: View {
    let item: MediaItem
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: item.posterURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 160, height: 240)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            
            Text(item.displayTitle)
                .font(.headline)
                .lineLimit(1)
                .frame(width: 160, alignment: .leading)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct SearchView: View {
    @Environment(TMDbClient.self) private var tmdbClient
    @State private var searchText = ""
    @StateObject private var playerState = PlayerState()

    var body: some View {
        VStack {
            TextField("Search for movies, TV series...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title2)
                .padding(40)
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        await tmdbClient.search(query: newValue)
                    }
                }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 30) {
                    ForEach(tmdbClient.searchResults) { item in
                        MediaCard(item: item)
                            .onTapGesture {
                                playerState.play(item)
                            }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $playerState.isPresented) {
            if let item = playerState.selectedItem {
                MediaDetailView(item: item, initialSeason: playerState.initialSeason, initialEpisode: playerState.initialEpisode)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("About FLIXAWAY")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                Text("Created by.... ABISHEK....")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("AND Created for.... I was fuckin bored... and streaming websites SUCKASS")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
