import Foundation

// MARK: - Models

struct TMDbResponse<T: Codable>: Codable {
    let page: Int?
    let results: [T]
    let totalPages: Int?
    let totalResults: Int?
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct MediaItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let mediaType: String? // "movie" or "tv"
    let voteAverage: Double?
    
    var displayTitle: String {
        title ?? name ?? "Unknown"
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case mediaType = "media_type"
        case voteAverage = "vote_average"
    }
}

struct TVSeriesDetails: Codable {
    let id: Int
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
    }
}

struct TVSeasonDetails: Codable {
    let id: Int
    let seasonNumber: Int
    let episodes: [TVEpisode]
    
    enum CodingKeys: String, CodingKey {
        case id
        case seasonNumber = "season_number"
        case episodes
    }
}

struct TVEpisode: Codable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let episodeNumber: Int
    let stillPath: String?
    
    var stillURL: URL? {
        guard let path = stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case episodeNumber = "episode_number"
        case stillPath = "still_path"
    }
}

// MARK: - API Client

@Observable
class TMDbClient {
    private let apiKey = "1fc524ff94eb42ea0c03269e0e169c42"
    private let baseURL = "https://api.themoviedb.org/3"
    
    var trendingItems: [MediaItem] = []
    var popularMovies: [MediaItem] = []
    var popularSeries: [MediaItem] = []
    var searchResults: [MediaItem] = []
    
    var isLoading = false
    var errorMessage: String?
    
    func fetchHomeData() async {
        isLoading = true
        errorMessage = nil
        
        async let trending = fetchEndpoint(endpoint: "/trending/all/day")
        async let movies = fetchEndpoint(endpoint: "/movie/popular")
        async let series = fetchEndpoint(endpoint: "/tv/popular")
        
        do {
            let (trendRes, movRes, serRes) = try await (trending, movies, series)
            
            // UI updates should happen on main thread automatically with @Observable,
            // but just to be safe if not in a view context:
            await MainActor.run {
                self.trendingItems = trendRes
                self.popularMovies = movRes.map {
                    MediaItem(id: $0.id, title: $0.title, name: $0.name, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, mediaType: "movie", voteAverage: $0.voteAverage)
                }
                self.popularSeries = serRes.map {
                    MediaItem(id: $0.id, title: $0.title, name: $0.name, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, mediaType: "tv", voteAverage: $0.voteAverage)
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            await MainActor.run { self.searchResults = [] }
            return
        }
        
        isLoading = true
        do {
            let results = try await fetchEndpoint(endpoint: "/search/multi", queryItems: [URLQueryItem(name: "query", value: query)])
            await MainActor.run {
                self.searchResults = results.filter { $0.mediaType == "movie" || $0.mediaType == "tv" }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchSeriesDetails(id: Int) async throws -> TVSeriesDetails {
        guard var components = URLComponents(string: baseURL + "/tv/\(id)") else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(TVSeriesDetails.self, from: data)
    }
    
    func fetchSeasonDetails(seriesId: Int, seasonNumber: Int) async throws -> TVSeasonDetails {
        guard var components = URLComponents(string: baseURL + "/tv/\(seriesId)/season/\(seasonNumber)") else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(TVSeasonDetails.self, from: data)
    }
    
    private func fetchEndpoint(endpoint: String, queryItems: [URLQueryItem] = []) async throws -> [MediaItem] {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        
        var allQueryItems = queryItems
        allQueryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        components.queryItems = allQueryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TMDbResponse<MediaItem>.self, from: data)
        return response.results
    }
}
