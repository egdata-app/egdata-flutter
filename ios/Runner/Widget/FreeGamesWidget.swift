import WidgetKit
import SwiftUI

// MARK: - Models

struct WidgetData: Codable {
    let games: [WidgetFreeGame]
    let lastUpdate: String // ISO String
}

struct WidgetFreeGame: Codable, Identifiable {
    let id: String
    let title: String
    let thumbnailUrl: String?
    let endDate: String
    
    var endDateTime: Date? {
        ISO8601DateFormatter.shared.date(from: endDate)
    }
}

extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

// MARK: - Provider

struct Provider: TimelineProvider {
    let appGroupId = "group.com.ignacioaldama.egdata"
    let userDefaultsKey = "widget_data"
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), games: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), games: loadGames())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let games = loadGames()
        let entry = SimpleEntry(date: Date(), games: games)
        
        // Refresh every hour or when app updates
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadGames() -> [WidgetFreeGame] {
        guard let userDefaults = UserDefaults(suiteName: appGroupId),
              let jsonString = userDefaults.string(forKey: userDefaultsKey),
              let jsonData = jsonString.data(using: .utf8) else {
            return []
        }
        
        do {
            let data = try JSONDecoder().decode(WidgetData.self, from: jsonData)
            return data.games
        } catch {
            print("Widget Error: \(error)")
            return []
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let games: [WidgetFreeGame]
}

// MARK: - Views

struct FreeGamesWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.games.isEmpty {
            EmptyStateView()
        } else {
            switch family {
            case .systemSmall:
                SmallWidgetView(game: entry.games[0])
            case .systemMedium:
                MediumWidgetView(games: entry.games)
            default:
                SmallWidgetView(game: entry.games[0])
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.04)
            Text("No active offers")
                .foregroundColor(.white)
                .font(.caption)
        }
    }
}

struct SmallWidgetView: View {
    let game: WidgetFreeGame
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background Image
                if let urlString = game.thumbnailUrl, let url = URL(string: urlString) {
                    NetworkImage(url: url)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Color(red: 0.1, green: 0.1, blue: 0.1)
                }
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.8), .transparent]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("FREE NOW")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    Text(game.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(radius: 2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 0.04, green: 0.04, blue: 0.04))
        }
    }
}

struct MediumWidgetView: View {
    let games: [WidgetFreeGame]
    
    var body: some View {
        HStack(spacing: 0) {
            // Featured Game (Left)
            if let firstGame = games.first {
                GeometryReader { geo in
                    ZStack(alignment: .bottomLeading) {
                        if let urlString = firstGame.thumbnailUrl, let url = URL(string: urlString) {
                            NetworkImage(url: url)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }
                        
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.9), .black.opacity(0.0)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FREE NOW")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            Text(firstGame.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        .padding(12)
                    }
                }
                .frame(width: 140)
            }
            
            // List (Right)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(games.dropFirst().prefix(2)) { game in
                    HStack(spacing: 8) {
                        if let urlString = game.thumbnailUrl, let url = URL(string: urlString) {
                            NetworkImage(url: url)
                                .frame(width: 40, height: 53)
                                .cornerRadius(4)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 53)
                                .cornerRadius(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            if let endDate = game.endDateTime {
                                Text("Ends \(formatDate(endDate))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                if games.count == 1 {
                    Text("More offers coming soon")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .background(Color(red: 0.04, green: 0.04, blue: 0.04))
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// Simple Async Image wrapper for iOS 14+
struct NetworkImage: View {
    let url: URL
    
    var body: some View {
        if #available(iOSApplicationExtension 15.0, *) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure(_):
                    Color.gray.opacity(0.3)
                case .empty:
                    Color.gray.opacity(0.3)
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
        } else {
            // Fallback for iOS 14 (Simplified, no actual network fetch in View without iOS 15)
            // In a real app, you'd download the image in Provider or use a library.
            // For now, we assume iOS 15+ target.
            Color.gray
        }
    }
}

extension Color {
    static let transparent = Color(white: 0, opacity: 0)
}

// MARK: - Widget Configuration

@main
struct FreeGamesWidget: Widget {
    let kind: String = "FreeGamesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FreeGamesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Free Games")
        .description("See the current free games on Epic Games Store.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
