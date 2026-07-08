import Foundation
import SwiftUI

struct WatchProgress: Codable, Identifiable, Hashable {
    let id: Int
    var title: String
    var posterPath: String?
    var mediaType: String // "movie" or "tv"
    
    // For TV Series
    var lastWatchedSeason: Int?
    var lastWatchedEpisode: Int?
    
    var lastWatchedDate: Date
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}

@Observable
class WatchHistoryManager {
    var history: [WatchProgress] = []
    
    private let defaultsKey = "StreamMacWatchHistory"
    
    init() {
        load()
    }
    
    func logProgress(item: MediaItem, season: Int?, episode: Int?) {
        var currentHistory = history
        
        // Remove existing if present to update it
        if let index = currentHistory.firstIndex(where: { $0.id == item.id }) {
            currentHistory.remove(at: index)
        }
        
        let newProgress = WatchProgress(
            id: item.id,
            title: item.displayTitle,
            posterPath: item.posterPath,
            mediaType: item.mediaType ?? "movie",
            lastWatchedSeason: season,
            lastWatchedEpisode: episode,
            lastWatchedDate: Date()
        )
        
        // Add to top
        currentHistory.insert(newProgress, at: 0)
        history = currentHistory
        save()
    }
    
    func removeProgress(id: Int) {
        history.removeAll(where: { $0.id == id })
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode([WatchProgress].self, from: data) {
            history = saved
        }
    }
}
