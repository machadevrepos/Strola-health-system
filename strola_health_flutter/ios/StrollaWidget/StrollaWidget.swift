// StrollaWidget.swift
// iOS WidgetKit extension for Strolla Health.
//
// ── XCODE SETUP (one-time, done in Xcode) ──────────────────────────────────
//  1. File → New → Target → Widget Extension, named "StrollaWidget"
//  2. Both targets (Runner + StrollaWidget) → Signing & Capabilities
//     → + Capability → App Groups → add "group.com.machadev.strola_health"
//  3. Runner target → Build Settings → PRODUCT_BUNDLE_IDENTIFIER verify it is
//     "com.machadev.strola_health"
//  4. StrollaWidget target bundle id: "com.machadev.strola_health.StrollaWidget"
//  5. Add this file to the StrollaWidget target.
// ───────────────────────────────────────────────────────────────────────────

import SwiftUI
import WidgetKit

// ── Shared UserDefaults (App Group) bridge from Flutter ──────────────────────
// home_widget Flutter plugin writes to this group via HomeWidget.saveWidgetData()

private let appGroup = "group.com.machadev.strola_health"

struct StrollaEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let goal: Int
    let distance: String
    let calories: Int
    let activeMin: Int

    // Clamped — feeds .trim()/frame-width visuals below, which can't
    // visually exceed full. `percent` is the displayed text and should
    // reflect steps actually going over goal rather than capping at 100.
    var progress: Double { (Double(steps) / Double(max(goal, 1))).clamped(to: 0...1) }
    var percent: Int { Int((Double(steps) / Double(max(goal, 1))) * 100) }
    var motivationText: String {
        if steps >= goal { return "Goal achieved! 🎉" }
        let remaining = goal - steps
        if remaining <= 500 { return "Almost there! \(remaining) more" }
        return "Keep going, you've got this!"
    }
}

// ── Timeline provider ─────────────────────────────────────────────────────────

struct StrollaProvider: TimelineProvider {
    func placeholder(in context: Context) -> StrollaEntry {
        StrollaEntry(date: .now, steps: 6842, goal: 10_000,
                     distance: "5.2 km", calories: 412, activeMin: 60)
    }

    func getSnapshot(in context: Context, completion: @escaping (StrollaEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StrollaEntry>) -> Void) {
        // Refresh every 30 min; real updates triggered by Flutter app via
        // WidgetCenter.shared.reloadAllTimelines() (called by home_widget).
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry()], policy: .after(nextRefresh)))
    }

    private func entry() -> StrollaEntry {
        let defaults = UserDefaults(suiteName: appGroup)
        return StrollaEntry(
            date: .now,
            steps:     defaults?.integer(forKey: "steps")       ?? 0,
            goal:      defaults?.integer(forKey: "goal")        ?? 10_000,
            distance:  defaults?.string(forKey: "distance")     ?? "0.0 km",
            calories:  defaults?.integer(forKey: "calories")    ?? 0,
            activeMin: defaults?.integer(forKey: "activeMin")   ?? 0
        )
    }
}

// ── Coral brand color ─────────────────────────────────────────────────────────

private extension Color {
    static let strollaAccent      = Color(red: 0.878, green: 0.478, blue: 0.478) // #E07A7A
    static let strollaBlush       = Color(red: 0.965, green: 0.694, blue: 0.694) // #F6B1B1
    static let strollaTextPrimary = Color(red: 0.200, green: 0.200, blue: 0.200) // #333333
    static let strollaTextMuted   = Color(red: 0.200, green: 0.200, blue: 0.200).opacity(0.40)
}

// ── Medium widget view (home screen, 2×2) ─────────────────────────────────────

struct StrollaMediumWidgetView: View {
    let entry: StrollaEntry

    var body: some View {
        ZStack {
            Color.strollaAccent
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("strolla")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "figure.walk")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(6)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
                .padding(.bottom, 8)

                // Step count
                Text("\(entry.steps)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("of \(entry.goal) steps")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.top, 1)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.28))
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: geo.size.width * entry.progress, height: 7)
                    }
                }
                .frame(height: 7)
                .padding(.vertical, 10)

                // Stats row
                HStack(spacing: 0) {
                    statColumn(value: entry.distance, unit: "km")
                    Divider().frame(height: 24).background(Color.white.opacity(0.3))
                    statColumn(value: "\(entry.calories)", unit: "kcal")
                    Divider().frame(height: 24).background(Color.white.opacity(0.3))
                    statColumn(value: "\(entry.activeMin)", unit: "min")
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statColumn(value: String, unit: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}

// ── Lock-screen / rectangular accessory widget (iOS 16+) ─────────────────────
// Maps to WidgetFamily.accessoryRectangular — appears on the lock screen.

struct StrollaLockScreenView: View {
    let entry: StrollaEntry

    var body: some View {
        HStack(spacing: 10) {
            // Mini ring
            ZStack {
                Circle()
                    .stroke(Color.strollaBlush.opacity(0.35), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.strollaAccent,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "shoeprints.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.strollaAccent)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.steps)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.strollaTextPrimary)
                Text("/ \(entry.goal) steps · \(entry.percent)%")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.strollaTextMuted)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                    .foregroundColor(.strollaAccent)
                Text("Every step\ncounts!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.strollaTextPrimary)
                    .lineLimit(2)
                Text(entry.motivationText)
                    .font(.system(size: 9))
                    .foregroundColor(.strollaAccent)
                    .lineLimit(2)
            }
            .frame(maxWidth: 90)
        }
        .padding(.horizontal, 4)
    }
}

// ── Small widget (home screen, 1×1) ──────────────────────────────────────────

struct StrollaSmallWidgetView: View {
    let entry: StrollaEntry

    var body: some View {
        ZStack {
            Color.strollaAccent
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(Color.white,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "figure.walk")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)

                Text("\(entry.steps)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("steps")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// ── Widget bundle ─────────────────────────────────────────────────────────────

@main
struct StrollaWidgetBundle: WidgetBundle {
    var body: some Widget {
        StrollaWidget()
    }
}

struct StrollaWidget: Widget {
    let kind = "StrollaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StrollaProvider()) { entry in
            StrollaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Strolla")
        .description("Your daily steps at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular, // iOS 16+ lock screen
        ])
    }
}

struct StrollaWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StrollaEntry

    var body: some View {
        switch family {
        case .systemSmall:
            StrollaSmallWidgetView(entry: entry)
        case .systemMedium:
            StrollaMediumWidgetView(entry: entry)
        case .accessoryRectangular:
            StrollaLockScreenView(entry: entry)
        default:
            StrollaMediumWidgetView(entry: entry)
        }
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
