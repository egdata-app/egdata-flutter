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
        SimpleEntry(date: Date(), games: [], currentIndex: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let games = loadGames()
        let entry = SimpleEntry(date: Date(), games: games, currentIndex: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let games = loadGames()
        
        if games.isEmpty {
            let entry = SimpleEntry(date: Date(), games: [], currentIndex: 0)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
            return
        }
        
        // Create timeline entries for carousel effect (rotate every 15 seconds)
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        let rotationInterval: TimeInterval = 15
        
        // Create entries for each game, rotating through them
        for i in 0..<games.count {
            let entryDate = currentDate.addingTimeInterval(TimeInterval(i) * rotationInterval)
            let entry = SimpleEntry(date: entryDate, games: games, currentIndex: i % games.count)
            entries.append(entry)
        }
        
        // Complete the cycle back to first game
        let lastEntryDate = currentDate.addingTimeInterval(TimeInterval(games.count) * rotationInterval)
        entries.append(SimpleEntry(date: lastEntryDate, games: games, currentIndex: 0))
        
        // Refresh every hour or after carousel completes
        let nextUpdate = currentDate.addingTimeInterval(TimeInterval(games.count) * rotationInterval + 3600)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
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
    let currentIndex: Int
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
                SmallWidgetView(
                    game: entry.games[entry.currentIndex],
                    currentIndex: entry.currentIndex,
                    totalGames: entry.games.count
                )
            case .systemMedium:
                MediumWidgetView(games: entry.games)
            case .systemLarge:
                LargeWidgetView(games: entry.games)
            default:
                SmallWidgetView(
                    game: entry.games[entry.currentIndex],
                    currentIndex: entry.currentIndex,
                    totalGames: entry.games.count
                )
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
    let currentIndex: Int
    let totalGames: Int
    
    init(game: WidgetFreeGame, currentIndex: Int = 0, totalGames: Int = 1) {
        self.game = game
        self.currentIndex = currentIndex
        self.totalGames = totalGames
    }
    
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
                
                // Gradient Overlay (from bottom, fading upward)
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.8), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                
                // Position Indicator (top-right)
                HStack {
                    Spacer()
                    Text("\(currentIndex + 1)/\(totalGames)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0, green: 0.83, blue: 1, opacity: 0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(10)
                
                // Content (bottom)
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(alignment: .center, spacing: 4) {
                        if let endDate = game.endDateTime {
                            Text("Ends \(formatDate(endDate))")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                        }
                        
                        Spacer()
                        
                        Text("FREE")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(red: 0, green: 0.83, blue: 1))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                }
                .padding(12)
            }
            .background(Color(red: 0.04, green: 0.04, blue: 0.04))
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct MediumWidgetView: View {
    let games: [WidgetFreeGame]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                if let appIcon = UIImage(named: "AppIcon") {
                    Image(uiImage: appIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .cornerRadius(6)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0, green: 0.83, blue: 1))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("egdata.app")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0.83, blue: 1))
                    
                    Text("Free This Week")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.bottom, 10)
            
            // Games List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(games.prefix(3).enumerated()), id: \.element.id) { index, game in
                        GameCard(game: game)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.04, green: 0.04, blue: 0.04))
    }
}

struct GameCard: View {
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
                    gradient: Gradient(colors: [.black.opacity(0.8), .clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(alignment: .center, spacing: 4) {
                        if let endDate = game.endDateTime {
                            Text("Ends \(formatDate(endDate))")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                        }
                        
                        Spacer()
                        
                        Text("FREE")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(red: 0, green: 0.83, blue: 1))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                }
                .padding(12)
            }
            .background(Color.black.opacity(0.9))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.18, green: 0.18, blue: 0.18, opacity: 0.25), lineWidth: 1)
            )
        }
        .frame(height: 120)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct LargeWidgetView: View {
    let games: [WidgetFreeGame]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (same as medium)
            HStack(spacing: 10) {
                if let appIcon = UIImage(named: "AppIcon") {
                    Image(uiImage: appIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .cornerRadius(6)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0, green: 0.83, blue: 1))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("egdata.app")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0.83, blue: 1))
                    
                    Text("Free This Week")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.bottom, 10)
            
            // Games List (scrollable, more games than medium)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(games, id: \.id) { game in
                        GameCard(game: game)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.04, green: 0.04, blue: 0.04))
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
