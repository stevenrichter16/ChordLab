//
//  LemonadeGameView.swift
//  ChordLab
//
//  Lemonade Stand: a 14-day season of imperfect forecasts, pricing
//  psychology, and inventory risk. Cups you make and don't sell are
//  money down the drain.
//

import SwiftUI

struct LemonadeGameView: View {
    private enum Weather: String, CaseIterable {
        case heatwave = "Heatwave"
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rainy = "Rainy"

        var icon: String {
            switch self {
            case .heatwave: return "thermometer.sun.fill"
            case .sunny: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rainy: return "cloud.rain.fill"
            }
        }

        var tint: Color {
            switch self {
            case .heatwave: return .red
            case .sunny: return .yellow
            case .cloudy: return .gray
            case .rainy: return .blue
            }
        }

        /// How many people are out and about.
        var crowdMultiplier: Double {
            switch self {
            case .heatwave: return 1.7
            case .sunny: return 1.2
            case .cloudy: return 0.75
            case .rainy: return 0.4
            }
        }

        /// Average price (in cents) a customer will pay.
        var willingnessMean: Double {
            switch self {
            case .heatwave: return 190
            case .sunny: return 145
            case .cloudy: return 110
            case .rainy: return 85
            }
        }
    }

    private struct DayResult {
        let weather: Weather
        let customers: Int
        let sold: Int
        let prepared: Int
        let revenue: Int      // cents
        let cost: Int         // cents
        let soldOut: Bool
        let repChange: Double
    }

    private enum LemonadePhase {
        case planning
        case results
        case seasonOver
    }

    private static let totalDays = 14
    private static let startingCash = 2000       // cents
    private static let costPerCup = 30           // cents

    @State private var day = 1
    @State private var cash = LemonadeGameView.startingCash
    @State private var reputation = 1.0          // 0.5 ... 1.5
    @State private var forecast: Weather = .sunny
    @State private var priceCents = 100
    @State private var cupsToMake = 20
    @State private var phase: LemonadePhase = .planning
    @State private var lastResult: DayResult? = nil
    @State private var isNewRecord = false

    private var totalProfitCents: Int {
        cash - Self.startingCash
    }

    private var maxAffordableCups: Int {
        max(0, cash / Self.costPerCup)
    }

    // MARK: - Live projection

    /// Total material cost for the cups queued up, in cents.
    private var materialCostCents: Int {
        cupsToMake * Self.costPerCup
    }

    /// Expected foot traffic under tomorrow's forecast — the mean of the
    /// same crowd distribution runDay() samples from, without the noise.
    private var expectedCustomers: Double {
        34.0 * forecast.crowdMultiplier * reputation
    }

    /// Probability a customer's willingness to pay clears `priceCents`,
    /// via a logistic approximation of the normal CDF (same mean/sd as
    /// the willingness-to-pay draw in runDay()).
    private var buyProbability: Double {
        let z = 1.702 * (forecast.willingnessMean - Double(priceCents)) / 42.0
        return 1 / (1 + exp(-z))
    }

    /// Expected cups sold, capped by how many are actually made.
    private var expectedSold: Double {
        min(expectedCustomers * buyProbability, Double(cupsToMake))
    }

    private var expectedRevenueCents: Int {
        Int((expectedSold * Double(priceCents)).rounded())
    }

    private var expectedProfitCents: Int {
        expectedRevenueCents - materialCostCents
    }

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "lemonade")!, onRestart: { newSeason() }) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatPill(label: "Day", value: "\(min(day, Self.totalDays))/\(Self.totalDays)")
                    StatPill(label: "Cash", value: dollars(cash), tint: .green)
                    StatPill(label: "Reputation", value: repStars, tint: .yellow)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        forecastCard

                        if phase == .planning {
                            planningControls
                        } else if let lastResult {
                            resultsCard(lastResult)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 4)
            .overlay {
                if phase == .seasonOver {
                    GameOverOverlay(
                        title: totalProfitCents >= 0 ? "Season Wrapped! 🍋" : "Went Under 🫠",
                        subtitle: "Total profit: \(dollars(totalProfitCents)) over \(Self.totalDays) days",
                        isVictory: totalProfitCents > 0,
                        newRecord: isNewRecord,
                        buttonTitle: "New Season"
                    ) {
                        newSeason()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var forecastCard: some View {
        HStack(spacing: 14) {
            Image(systemName: forecast.icon)
                .font(.system(size: 34))
                .foregroundStyle(forecast.tint)
                .frame(width: 54, height: 54)
                .background(forecast.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text("Tomorrow's forecast")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(forecast.rawValue)
                    .font(.title3.weight(.bold))
                Text("Forecasts are right about 4 days in 5…")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var planningControls: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                HStack {
                    Text("Price per cup")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(dollars(priceCents))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .contentTransition(.numericText())
                }
                Slider(
                    value: Binding(
                        get: { Double(priceCents) },
                        set: { priceCents = Int(($0 / 5).rounded()) * 5 }
                    ),
                    in: 25...300
                )
                HStack {
                    Text("25¢").font(.caption2).foregroundStyle(.tertiary)
                    Spacer()
                    Text("$3.00").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 6) {
                HStack {
                    Text("Cups to make")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(cupsToMake)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                Slider(
                    value: Binding(
                        get: { Double(cupsToMake) },
                        set: { cupsToMake = Int($0.rounded()) }
                    ),
                    in: 0...Double(max(1, min(80, maxAffordableCups)))
                )
                HStack {
                    Text("Costs \(dollars(cupsToMake * Self.costPerCup)) to make")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Unsold cups are wasted")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 16))

            projectionCard

            // Opening with zero cups is allowed so a broke player can
            // still pass the day instead of soft-locking.
            ArcadeButton(title: cupsToMake == 0 ? "Skip the Day" : "Open the Stand",
                         systemImage: "storefront.fill",
                         tint: .yellow,
                         isEnabled: cupsToMake * Self.costPerCup <= cash) {
                runDay()
            }
        }
    }

    /// Live cost/revenue/profit estimate for the current price and cup
    /// count, so the player can see the trade-off before opening the
    /// stand — not just after the day plays out.
    private var projectionCard: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Today's projection")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("estimate")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            resultRow("Cost of materials", "-\(dollars(materialCostCents))")
            resultRow("Est. cups sold", "~\(Int(expectedSold.rounded())) of \(cupsToMake)")
            resultRow("Est. revenue", "+\(dollars(expectedRevenueCents))")
            Divider()
            resultRow("Est. profit", dollars(expectedProfitCents),
                      emphasized: true,
                      tint: expectedProfitCents >= 0 ? .green : .red)
            Text("Based on tomorrow's forecast — actual weather and customers vary.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private func resultsCard(_ result: DayResult) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: result.weather.icon)
                    .foregroundStyle(result.weather.tint)
                Text("It turned out \(result.weather.rawValue.lowercased())")
                    .font(.headline)
            }

            VStack(spacing: 6) {
                resultRow("Thirsty passersby", "\(result.customers)")
                resultRow("Cups sold", "\(result.sold) of \(result.prepared)")
                resultRow("Revenue", "+\(dollars(result.revenue))")
                resultRow("Supplies", "-\(dollars(result.cost))")
                Divider()
                resultRow("Day profit", dollars(result.revenue - result.cost),
                          emphasized: true,
                          tint: result.revenue >= result.cost ? .green : .red)
            }

            if result.soldOut {
                Label("Sold out! Word spreads, but missed sales sting.", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if result.repChange > 0.001 {
                Label("Your reputation grew.", systemImage: "arrow.up.heart.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if result.repChange < -0.001 {
                Label("Customers grumbled about the price.", systemImage: "arrow.down.heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            ArcadeButton(title: day > Self.totalDays ? "Close the Season" : "Plan Day \(day)",
                         systemImage: "arrow.right.circle.fill",
                         tint: .yellow) {
                advance()
            }
        }
        .padding(16)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private func resultRow(_ label: String, _ value: String,
                           emphasized: Bool = false, tint: Color = .primary) -> some View {
        HStack {
            Text(label)
                .font(emphasized ? .subheadline.weight(.bold) : .subheadline)
                .foregroundStyle(emphasized ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(.system(size: emphasized ? 17 : 15,
                              weight: emphasized ? .bold : .semibold,
                              design: .rounded))
                .foregroundStyle(tint)
        }
    }

    // MARK: - Formatting

    private func dollars(_ cents: Int) -> String {
        let sign = cents < 0 ? "-" : ""
        let absCents = abs(cents)
        return "\(sign)$\(absCents / 100).\(String(format: "%02d", absCents % 100))"
    }

    private var repStars: String {
        let count = max(0, min(5, Int(((reputation - 0.5) * 5).rounded())))
        return String(repeating: "★", count: count) + String(repeating: "☆", count: 5 - count)
    }

    // MARK: - Simulation

    /// Approximate a normal sample by averaging uniforms.
    private func gaussian(mean: Double, sd: Double) -> Double {
        let sum = (0..<6).reduce(0.0) { total, _ in total + Double.random(in: 0...1) }
        return mean + (sum - 3.0) / 1.5 * sd * 2
    }

    private func runDay() {
        GameHaptics.medium()

        // 80%: forecast holds; otherwise the sky does its own thing.
        let actual: Weather
        if Double.random(in: 0..<1) < 0.8 {
            actual = forecast
        } else {
            actual = Weather.allCases.filter { $0 != forecast }.randomElement() ?? forecast
        }

        let cost = cupsToMake * Self.costPerCup
        cash -= cost

        let baseCrowd = 34.0
        let crowd = max(0, gaussian(mean: baseCrowd * actual.crowdMultiplier * reputation,
                                    sd: baseCrowd * 0.12))
        let customers = Int(crowd.rounded())

        // Each customer has a willingness to pay; they buy if the price fits.
        var buyers = 0
        for _ in 0..<customers {
            let willingness = gaussian(mean: actual.willingnessMean, sd: 42)
            if Double(priceCents) <= willingness {
                buyers += 1
            }
        }

        let sold = min(buyers, cupsToMake)
        let revenue = sold * priceCents
        cash += revenue
        let soldOut = buyers > cupsToMake

        // Reputation: fair prices and stock build it; gouging erodes it.
        var repChange = 0.0
        if Double(priceCents) <= actual.willingnessMean - 20 { repChange += 0.05 }
        if Double(priceCents) >= actual.willingnessMean + 60 { repChange -= 0.07 }
        repChange += soldOut ? -0.03 : (sold > 0 ? 0.02 : 0)
        reputation = min(1.5, max(0.5, reputation + repChange))

        lastResult = DayResult(weather: actual, customers: customers, sold: sold,
                               prepared: cupsToMake, revenue: revenue, cost: cost,
                               soldOut: soldOut, repChange: repChange)

        if revenue >= cost {
            GameHaptics.success()
        } else {
            GameHaptics.warning()
        }

        day += 1
        forecast = Weather.allCases.randomElement() ?? .sunny
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            phase = .results
        }
    }

    private func advance() {
        if day > Self.totalDays {
            let profitDollars = totalProfitCents / 100
            isNewRecord = GameScores.shared.report(score: profitDollars, for: "lemonade")
            GameHaptics.success()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                phase = .seasonOver
            }
        } else {
            // Sensible defaults for the new day.
            cupsToMake = min(cupsToMake, max(1, maxAffordableCups))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                phase = .planning
            }
        }
    }

    private func newSeason() {
        day = 1
        cash = Self.startingCash
        reputation = 1.0
        forecast = Weather.allCases.randomElement() ?? .sunny
        priceCents = 100
        cupsToMake = 20
        lastResult = nil
        isNewRecord = false
        phase = .planning
    }
}

#Preview {
    LemonadeGameView()
}
