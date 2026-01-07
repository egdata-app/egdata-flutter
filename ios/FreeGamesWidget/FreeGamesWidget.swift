import WidgetKit
import SwiftUI

// MARK: - Design Constants

struct WidgetColors {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.04)      // #0A0A0A
    static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.1)     // #1A1A1A
    static let accent = Color(red: 0, green: 0.83, blue: 1)                 // #00D4FF (Cyan)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.87)                           // #DDDDDD
    static let textMuted = Color.gray
}

// MARK: - Models

struct WidgetData: Codable {
    let games: [WidgetFreeGame]
    let lastUpdate: String
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

// MARK: - Timeline Entry

struct GameEntry: TimelineEntry {
    let date: Date
    let games: [WidgetFreeGame]
    let processedImages: [String: UIImage]
}

// MARK: - Provider

struct Provider: TimelineProvider {
    let appGroupId = "group.com.ignacioaldama.egdata"
    let userDefaultsKey = "widget_data"

    func placeholder(in context: Context) -> GameEntry {
        GameEntry(date: Date(), games: [], processedImages: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (GameEntry) -> ()) {
        let games = loadGames()
        let entry = GameEntry(date: Date(), games: games, processedImages: [:])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let games = loadGames()

        Task {
            var processedImages: [String: UIImage] = [:]

            for game in games.prefix(6) {
                if let urlString = game.thumbnailUrl,
                   let url = URL(string: urlString),
                   let processedImage = await loadAndProcessImage(from: url) {
                    processedImages[game.id] = processedImage
                }
            }

            let entry = GameEntry(date: Date(), games: games, processedImages: processedImages)

            // Refresh every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            DispatchQueue.main.async {
                completion(timeline)
            }
        }
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

    // MARK: - Image Processing with Blur Effect

    private func loadAndProcessImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let originalImage = UIImage(data: data) else { return nil }
            return applyBottomBlurAndGradient(to: originalImage)
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }

    private func applyBottomBlurAndGradient(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        // Split point: blur bottom 43.5% (matching Android's 56.5% splitY)
        let splitY = height * 0.565
        let blurSectionHeight = height - splitY

        // Create rendering context
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return image }

        // Flip coordinate system for UIKit
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1, y: -1)

        // Draw full original image first
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Extract and blur the bottom section
        if let bottomSection = cgImage.cropping(to: CGRect(x: 0, y: Int(splitY), width: Int(width), height: Int(blurSectionHeight))) {
            let ciImage = CIImage(cgImage: bottomSection)

            // Apply blur
            if let blurFilter = CIFilter(name: "CIGaussianBlur") {
                blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                blurFilter.setValue(15.0, forKey: kCIInputRadiusKey)

                if let blurredOutput = blurFilter.outputImage {
                    let ciContext = CIContext(options: [.useSoftwareRenderer: false])

                    // Clamp to extent to avoid edge artifacts
                    let clampedOutput = blurredOutput.clampedToExtent().cropped(to: ciImage.extent)

                    if let blurredCGImage = ciContext.createCGImage(clampedOutput, from: ciImage.extent) {
                        // Draw blurred bottom section (remember coordinate system is flipped)
                        context.draw(blurredCGImage, in: CGRect(x: 0, y: 0, width: width, height: blurSectionHeight))
                    }
                }
            }
        }

        // Draw gradient overlay on bottom section
        let gradientColors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        let gradientLocations: [CGFloat] = [0.0, 1.0]

        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: gradientColors as CFArray,
            locations: gradientLocations
        ) {
            // Draw gradient from splitY down to bottom
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: blurSectionHeight),
                end: CGPoint(x: 0, y: 0),
                options: []
            )
        }

        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resultImage
    }
}

// MARK: - Main Entry View

struct FreeGamesWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.games.isEmpty {
            EmptyStateView()
        } else {
            switch family {
            case .systemSmall:
                SmallWidgetView(game: entry.games[0], processedImage: entry.processedImages[entry.games[0].id])
            case .systemMedium:
                MediumWidgetView(games: entry.games, processedImages: entry.processedImages)
            case .systemLarge:
                LargeWidgetView(games: entry.games, processedImages: entry.processedImages)
            default:
                SmallWidgetView(game: entry.games[0], processedImage: entry.processedImages[entry.games[0].id])
            }
        }
    }
}

// MARK: - Header Component

struct WidgetHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            // App icon placeholder - using SF Symbol as fallback
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 20))
                .foregroundColor(WidgetColors.accent)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text("egdata.app")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(WidgetColors.accent)

                Text("Free This Week")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(WidgetColors.textPrimary)
            }

            Spacer()
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        ZStack {
            WidgetColors.background
            VStack(spacing: 8) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 32))
                    .foregroundColor(WidgetColors.textMuted)
                Text("No free games right now.")
                    .font(.system(size: 14))
                    .foregroundColor(WidgetColors.textMuted)
                Text("Check back later!")
                    .font(.system(size: 12))
                    .foregroundColor(WidgetColors.textMuted.opacity(0.7))
            }
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let game: WidgetFreeGame
    let processedImage: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background Image with blur effect
                if let image = processedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else if let urlString = game.thumbnailUrl, let url = URL(string: urlString) {
                    AsyncImageView(url: url)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    // Fallback gradient when no processed image
                    LinearGradient(
                        gradient: Gradient(colors: [.black.opacity(0.8), .clear]),
                        startPoint: .bottom,
                        endPoint: .center
                    )
                } else {
                    WidgetColors.cardBackground
                }

                // Content overlay
                VStack(alignment: .leading, spacing: 4) {
                    // FREE badge
                    Text("FREE")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WidgetColors.accent)
                        .foregroundColor(.black)
                        .cornerRadius(4)

                    Spacer()

                    Text(game.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                    if let endDate = game.endDateTime {
                        Text("Ends \(formatDate(endDate))")
                            .font(.system(size: 10))
                            .foregroundColor(WidgetColors.textSecondary)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(WidgetColors.background)
        }
        .widgetURL(URL(string: "egdata://offer/\(game.id)"))
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let games: [WidgetFreeGame]
    let processedImages: [String: UIImage]

    var body: some View {
        HStack(spacing: 0) {
            // Featured Game (Left)
            if let firstGame = games.first {
                Link(destination: URL(string: "egdata://offer/\(firstGame.id)")!) {
                    GeometryReader { geo in
                        ZStack(alignment: .bottomLeading) {
                            if let image = processedImages[firstGame.id] {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            } else if let urlString = firstGame.thumbnailUrl, let url = URL(string: urlString) {
                                AsyncImageView(url: url)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()

                                // Fallback gradient
                                LinearGradient(
                                    gradient: Gradient(colors: [.black.opacity(0.9), .clear]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            } else {
                                WidgetColors.cardBackground
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("FREE")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(WidgetColors.accent)
                                    .foregroundColor(.black)
                                    .cornerRadius(4)

                                Spacer()

                                Text(firstGame.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                                if let endDate = firstGame.endDateTime {
                                    Text("Ends \(formatDate(endDate))")
                                        .font(.system(size: 10))
                                        .foregroundColor(WidgetColors.textSecondary)
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                }
                            }
                            .padding(12)
                        }
                    }
                }
                .frame(width: 155)
            }

            // List (Right)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(games.dropFirst().prefix(2)) { game in
                    Link(destination: URL(string: "egdata://offer/\(game.id)")!) {
                        HStack(spacing: 8) {
                            if let urlString = game.thumbnailUrl, let url = URL(string: urlString) {
                                AsyncImageView(url: url)
                                    .frame(width: 50, height: 66)
                                    .cornerRadius(6)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 66)
                                    .cornerRadius(6)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(game.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)

                                if let endDate = game.endDateTime {
                                    Text("Ends \(formatDate(endDate))")
                                        .font(.system(size: 10))
                                        .foregroundColor(WidgetColors.textMuted)
                                }

                                Text("FREE")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(WidgetColors.accent)
                                    .foregroundColor(.black)
                                    .cornerRadius(3)
                            }

                            Spacer()
                        }
                    }
                }

                if games.count == 1 {
                    Spacer()
                    Text("More offers coming soon")
                        .font(.system(size: 11))
                        .foregroundColor(WidgetColors.textMuted)
                    Spacer()
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WidgetColors.cardBackground)
        }
        .background(WidgetColors.background)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let games: [WidgetFreeGame]
    let processedImages: [String: UIImage]

    var body: some View {
        VStack(spacing: 0) {
            // Header with app branding
            Link(destination: URL(string: "egdata://")!) {
                WidgetHeader()
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
            }

            // Game cards list
            VStack(spacing: 10) {
                ForEach(games.prefix(3)) { game in
                    Link(destination: URL(string: "egdata://offer/\(game.id)")!) {
                        GameCardView(
                            game: game,
                            processedImage: processedImages[game.id]
                        )
                    }
                }
            }
            .padding(.horizontal, 14)

            Spacer(minLength: 0)
        }
        .padding(.bottom, 14)
        .background(WidgetColors.background)
    }
}

// MARK: - Game Card Component (for Large Widget)

struct GameCardView: View {
    let game: WidgetFreeGame
    let processedImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image with blur
            if let image = processedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 90)
                    .clipped()
            } else if let urlString = game.thumbnailUrl, let url = URL(string: urlString) {
                AsyncImageView(url: url)
                    .frame(height: 90)
                    .clipped()

                // Fallback gradient if no processed image
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.8), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
            } else {
                WidgetColors.cardBackground
                    .frame(height: 90)
            }

            // Content overlay
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                    if let endDate = game.endDateTime {
                        Text("Ends \(formatDate(endDate))")
                            .font(.system(size: 11))
                            .foregroundColor(WidgetColors.textSecondary)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }

                Spacer()

                // FREE badge
                Text("FREE")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WidgetColors.accent)
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
            .padding(10)
        }
        .frame(height: 90)
        .cornerRadius(12)
        .clipped()
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Async Image Helper

struct AsyncImageView: View {
    let url: URL

    var body: some View {
        if #available(iOSApplicationExtension 15.0, *) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    WidgetColors.cardBackground
                case .empty:
                    WidgetColors.cardBackground
                @unknown default:
                    WidgetColors.cardBackground
                }
            }
        } else {
            WidgetColors.cardBackground
        }
    }
}

// MARK: - Widget Configuration

@main
struct FreeGamesWidget: Widget {
    let kind: String = "FreeGamesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                FreeGamesWidgetEntryView(entry: entry)
                    .containerBackground(WidgetColors.background, for: .widget)
            } else {
                FreeGamesWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Free Games")
        .description("See the current free games on Epic Games Store.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
