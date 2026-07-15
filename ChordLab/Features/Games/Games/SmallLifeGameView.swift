//
//  SmallLifeGameView.swift
//  ChordLab
//
//  A Small Life: one procedurally generated villager, narrated day by
//  day in a slow ambient feed. Moods drift, routines wobble, tiny arcs
//  unfold (a cat may be adopted). The life persists between visits.
//

import SwiftUI

struct SmallLifeGameView: View {
    // MARK: - Model

    private struct SLEntry: Codable, Identifiable, Equatable {
        var id: Int
        var day: Int
        var time: String
        var icon: String
        var text: String
        var isDayHeader: Bool
    }

    private struct SLState: Codable {
        var name: String
        var job: String
        var traits: [String]
        var mood: Double
        var money: Int
        var day: Int
        var nextEntryId: Int
        var lonelyStreak: Int
        var catName: String?
        var hasPlant: Bool
        var learningViolin: Bool
        var friendName: String
        var friendRole: String
        var entries: [SLEntry]
    }

    /// Everything a visit needs to resume exactly where it left off —
    /// including the half-revealed day (pending + stagedLife), so dismissing
    /// mid-day never re-rolls the day with different content.
    private struct SLSession: Codable {
        var life: SLState
        var pending: [SLEntry]
        var stagedLife: SLState?
        var moodHistory: [Double]
        var kindnessDay: Int
        var lastSavedAt: Date?

        init(life: SLState, pending: [SLEntry], stagedLife: SLState?,
             moodHistory: [Double], kindnessDay: Int, lastSavedAt: Date?) {
            self.life = life
            self.pending = pending
            self.stagedLife = stagedLife
            self.moodHistory = moodHistory
            self.kindnessDay = kindnessDay
            self.lastSavedAt = lastSavedAt
        }

        /// Only `life` is load-bearing: every other field decodes with a
        /// default so a future session-schema change can never discard a
        /// long-running life.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            life = try c.decode(SLState.self, forKey: .life)
            pending = try c.decodeIfPresent([SLEntry].self, forKey: .pending) ?? []
            stagedLife = try c.decodeIfPresent(SLState.self, forKey: .stagedLife)
            moodHistory = try c.decodeIfPresent([Double].self, forKey: .moodHistory) ?? []
            kindnessDay = try c.decodeIfPresent(Int.self, forKey: .kindnessDay) ?? 0
            lastSavedAt = try c.decodeIfPresent(Date.self, forKey: .lastSavedAt)
        }
    }

    private static let storageKey = "arcade.smalllife.state"

    private static let names = ["Mara", "Theo", "Juniper", "Sam", "Noor", "Wren", "Felix", "Ida",
                                "Bo", "Priya", "Alba", "Ezra", "Milo", "Suki", "Ren", "Ollie"]
    private static let jobs = ["librarian", "ferry attendant", "baker's assistant", "mapmaker",
                               "greenhouse keeper", "radio operator", "clockmaker's apprentice",
                               "post carrier", "museum guard", "sign painter"]
    private static let traitPool = ["early riser", "chronic doodler", "rain lover", "overthinker",
                                    "soup enthusiast", "hums constantly", "collects pebbles",
                                    "afraid of geese", "reads on stairs", "terrible at names"]
    private static let friendNames = ["Gus", "Petra", "Sol", "Nadia", "Bram", "Effie"]
    private static let friendRoles = ["the barista", "a neighbor", "a coworker", "the newsstand owner"]
    private static let catNames = ["Comma", "Beans", "Turnip", "Static", "Mochi", "Umbrella"]
    private static let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday",
                                   "Friday", "Saturday", "Sunday"]
    private static let weatherKinds: [(name: String, emoji: String)] = [
        ("clear", "☀️"), ("gray", "☁️"), ("rainy", "🌧"), ("windy", "🍃"), ("foggy", "🌫")
    ]

    // MARK: - State

    /// Reveal-interval accumulator in a plain reference box: mutating a
    /// class property does not invalidate the view, so the 0.4s ticks
    /// between reveals stop forcing body re-evaluations.
    private final class RevealClock {
        var accumulated = 0.0
    }

    @State private var life: SLState?
    @State private var pending: [SLEntry] = []
    /// The day's end-state, committed only when its last entry reveals —
    /// otherwise the header card spoils the feed (cat chip before the
    /// adoption entry, pay bump before the workday, next day number).
    @State private var stagedLife: SLState?
    /// Committed end-of-day moods, newest last, capped at 30.
    @State private var moodHistory: [Double] = []
    /// The in-sim day a kindness was last sent (one per day).
    @State private var kindnessDay = 0
    @State private var isPaused = false
    @State private var fastForward = false
    @State private var showNewLifeConfirm = false
    @State private var didLoad = false
    @State private var revealClock = RevealClock()

    @Environment(\.scenePhase) private var scenePhase

    @ScaledMetric(relativeTo: .caption2) private var timeColumnWidth: CGFloat = 40
    @ScaledMetric(relativeTo: .caption2) private var iconColumnWidth: CGFloat = 16

    private let ticker = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "smalllife")!,
                   onRestart: { showNewLifeConfirm = true }) {
            VStack(spacing: 10) {
                if let life {
                    headerCard(life)
                    feed(life)
                    controls
                }
            }
            .padding(.top, 4)
            .overlay {
                if showNewLifeConfirm {
                    newLifeConfirmOverlay
                }
            }
            .onAppear {
                if !didLoad {
                    didLoad = true
                    load()
                }
            }
            .onDisappear {
                save()
            }
            .onChange(of: scenePhase) { _, phase in
                // Mid-day progress must survive backgrounding/jetsam.
                if phase == .background || phase == .inactive {
                    save()
                }
            }
            .onReceive(ticker) { _ in
                tick()
            }
        }
    }

    // MARK: - Subviews

    private func headerCard(_ life: SLState) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(life.name)
                        .font(.title3.weight(.bold))
                    Text("\(life.job) · day \(life.day)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 10) {
                    moodSparkline
                    VStack(spacing: 2) {
                        Text(moodFace(life.mood))
                            .font(.title)
                            .accessibilityLabel("Mood: \(moodWord(life.mood))")
                        Text("$\(life.money)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach(life.traits, id: \.self) { trait in
                    Text(trait)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.teal.opacity(0.15), in: Capsule())
                        .foregroundStyle(.teal)
                }
                if let cat = life.catName {
                    Text("🐈 \(cat)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
    }

    private func feed(_ life: SLState) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(life.entries) { entry in
                        entryRow(entry)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.appSecondaryBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 12)
            .onChange(of: life.entries.last?.id) { _, lastId in
                // Track the last id, not the count: once the 160-entry cap
                // is reached the count stops changing but entries don't.
                if let lastId {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastId = life.entries.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: SLEntry) -> some View {
        if entry.isDayHeader {
            HStack {
                Rectangle().fill(Color.appBorder).frame(height: 1)
                Text(entry.text)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                Rectangle().fill(Color.appBorder).frame(height: 1)
            }
            .padding(.top, 8)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        } else {
            HStack(alignment: .top, spacing: 8) {
                Text(entry.time)
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: timeColumnWidth, alignment: .trailing)
                Image(systemName: entry.icon)
                    .font(.caption2)
                    .foregroundStyle(.teal)
                    .frame(width: iconColumnWidth)
                    .accessibilityHidden(true)
                Text(entry.text)
                    .font(.footnote)
                    .foregroundStyle(.primary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                GameHaptics.tap()
                isPaused.toggle()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 36)
                    .background(Color.appSecondaryBackground, in: Capsule())
            }

            Button {
                GameHaptics.tap()
                fastForward.toggle()
            } label: {
                Text(fastForward ? "3×" : "1×")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(fastForward ? .white : .secondary)
                    .frame(width: 40, height: 36)
                    .background(fastForward ? Color.teal : Color.appSecondaryBackground, in: Capsule())
            }

            Button {
                GameHaptics.tap()
                sendKindness()
            } label: {
                Image(systemName: "heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(kindnessAvailable ? Color.pink : Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 36)
                    .background(Color.appSecondaryBackground, in: Capsule())
            }
            .disabled(!kindnessAvailable)
            .accessibilityLabel("Send a small kindness")
            .accessibilityHint(kindnessAvailable ? "One per day." : "Already sent today.")

            Spacer()

            Text("life goes on…")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var newLifeConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("📖")
                    .font(.system(size: 40))
                Text("Start a new life?")
                    .font(.title3.weight(.bold))
                if let life {
                    Text("\(life.name)'s \(life.day) days will close forever.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 10) {
                    ArcadeButton(title: "Keep Living", tint: .teal) {
                        showNewLifeConfirm = false
                    }
                    ArcadeButton(title: "New Life", tint: .red) {
                        startNewLife()
                        showNewLifeConfirm = false
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 24))
            .padding(32)
        }
    }

    /// Tiny end-of-day mood trace next to the mood face; decorative only.
    @ViewBuilder
    private var moodSparkline: some View {
        if moodHistory.count >= 2 {
            let history = moodHistory
            Path { path in
                let width = 56.0, height = 16.0
                let stepX = width / Double(history.count - 1)
                for (i, mood) in history.enumerated() {
                    let point = CGPoint(x: Double(i) * stepX, y: height - mood * height)
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(Color.teal.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .frame(width: 56, height: 16)
            .accessibilityHidden(true)
        }
    }

    private func moodFace(_ mood: Double) -> String {
        switch mood {
        case ..<0.2: return "😞"
        case ..<0.4: return "😕"
        case ..<0.6: return "🙂"
        case ..<0.8: return "😊"
        default: return "😄"
        }
    }

    private func moodWord(_ mood: Double) -> String {
        switch mood {
        case ..<0.2: return "low"
        case ..<0.4: return "glum"
        case ..<0.6: return "steady"
        case ..<0.8: return "content"
        default: return "bright"
        }
    }

    // MARK: - Persistence

    private func load() {
        if let session = SimPersist.load(SLSession.self, key: Self.storageKey) {
            life = session.life
            pending = session.pending
            stagedLife = session.stagedLife
            moodHistory = session.moodHistory
            kindnessDay = session.kindnessDay
            acknowledgeAwayTime(since: session.lastSavedAt)
        } else if let legacy = SimPersist.load(SLState.self, key: Self.storageKey) {
            // Pre-session save: just the raw life, no mid-day state.
            life = legacy
        } else {
            startNewLife()
        }
    }

    private func save() {
        guard let life else { return }
        SimPersist.save(SLSession(life: life,
                                  pending: pending,
                                  stagedLife: stagedLife,
                                  moodHistory: moodHistory,
                                  kindnessDay: kindnessDay,
                                  lastSavedAt: Date()),
                        key: Self.storageKey)
        // Best-ever days: starting a new life must not wipe the record.
        GameScores.shared.report(score: life.day, for: "smalllife")
    }

    /// Coming back after a full wall-clock day (or more) away earns a
    /// quiet acknowledgment in the feed — the life doesn't simulate while
    /// closed, but it shouldn't feel frozen either.
    private func acknowledgeAwayTime(since lastSaved: Date?) {
        guard let lastSaved, var current = life else { return }
        let days = Int(Date().timeIntervalSince(lastSaved) / 86_400)
        guard days >= 1 else { return }
        let counts = ["", "one", "two", "three", "four", "five", "six", "seven",
                      "eight", "nine", "ten", "eleven", "twelve"]
        let text = days == 1
            ? "· a quiet day passes ·"
            : "· \(days < counts.count ? counts[days] : "\(days)") quiet days pass ·"
        // Ids must clear anything already allocated to pending entries.
        let id = max(current.nextEntryId, stagedLife?.nextEntryId ?? 0)
        let divider = SLEntry(id: id, day: (stagedLife ?? current).day, time: "", icon: "",
                              text: text, isDayHeader: true)
        if pending.isEmpty {
            current.entries.append(divider)
        } else {
            // A day is mid-reveal: queue the divider so it appears after
            // the interrupted day finishes, not in the middle of it.
            pending.append(divider)
        }
        current.nextEntryId = id + 1
        if stagedLife != nil {
            stagedLife?.nextEntryId = id + 1
        }
        life = current
    }

    // MARK: - Kindness

    private var kindnessAvailable: Bool {
        guard let life else { return false }
        return (stagedLife ?? life).day > kindnessDay
    }

    /// One gentle outside nudge per in-sim day: a small mood lift and a
    /// matching feed line, written in the narration's own voice.
    private func sendKindness() {
        guard kindnessAvailable, var current = life else { return }
        let kindnesses: [(icon: String, text: String)] = [
            ("envelope.fill", "A postcard arrives from somewhere warm. No signature, just a doodle of a boat."),
            ("gift.fill", "A paper bag of plums on the doorstep. No note. The good kind of mystery."),
            ("heart.fill", "A folded note under the door: \"saw this and thought of you.\" Inside, a pressed clover.")
        ]
        let kindness = kindnesses.randomElement()!
        let id = max(current.nextEntryId, stagedLife?.nextEntryId ?? 0)
        withAnimation(.easeOut(duration: 0.3)) {
            current.entries.append(SLEntry(id: id, day: current.day, time: "",
                                           icon: kindness.icon, text: kindness.text,
                                           isDayHeader: false))
            if current.entries.count > 160 {
                current.entries.removeFirst(current.entries.count - 160)
            }
            current.nextEntryId = id + 1
            current.mood = min(1, current.mood + 0.05)
            life = current
        }
        // The staged end-of-day state must carry the lift too, or the day
        // commit would quietly erase it.
        if var staged = stagedLife {
            staged.nextEntryId = id + 1
            staged.mood = min(1, staged.mood + 0.05)
            stagedLife = staged
        }
        kindnessDay = (stagedLife ?? current).day
        save()
    }

    private func startNewLife() {
        let traits = Array(Self.traitPool.shuffled().prefix(2))
        var fresh = SLState(name: Self.names.randomElement() ?? "Mara",
                            job: Self.jobs.randomElement() ?? "librarian",
                            traits: traits,
                            mood: 0.6,
                            money: 40,
                            day: 0,
                            nextEntryId: 0,
                            lonelyStreak: 0,
                            catName: nil,
                            hasPlant: false,
                            learningViolin: false,
                            friendName: Self.friendNames.randomElement() ?? "Gus",
                            friendRole: Self.friendRoles.randomElement() ?? "a neighbor",
                            entries: [])
        fresh.entries.append(SLEntry(id: 0, day: 0, time: "", icon: "",
                                     text: "· \(fresh.name) moves to the village ·",
                                     isDayHeader: true))
        fresh.nextEntryId = 1
        life = fresh
        pending = []
        stagedLife = nil
        moodHistory = []
        kindnessDay = 0
        revealClock.accumulated = 0
        isPaused = false
        fastForward = false
        save()
    }

    // MARK: - Ambient engine

    private func tick() {
        // The confirm overlay also pauses the life: it shouldn't keep
        // living (or saving) behind "Start a new life?".
        guard !isPaused, !showNewLifeConfirm, life != nil else { return }
        revealClock.accumulated += 0.4
        let interval = fastForward ? 0.8 : 2.4
        guard revealClock.accumulated >= interval else { return }
        revealClock.accumulated = 0

        if pending.isEmpty {
            generateNextDay()
        }
        guard var current = life, !pending.isEmpty else { return }
        let entry = pending.removeFirst()
        withAnimation(.easeOut(duration: 0.3)) {
            current.entries.append(entry)
            if current.entries.count > 160 {
                current.entries.removeFirst(current.entries.count - 160)
            }
            life = current
        }
        if pending.isEmpty {
            // Day fully revealed: commit its end-state (day counter, mood,
            // money, flags) while keeping the revealed feed, then persist.
            if var staged = stagedLife, let revealed = life {
                staged.entries = revealed.entries
                life = staged
                stagedLife = nil
            }
            if let mood = life?.mood {
                moodHistory.append(mood)
                if moodHistory.count > 30 {
                    moodHistory.removeFirst(moodHistory.count - 30)
                }
            }
            save()
        }
    }

    private func generateNextDay() {
        guard var current = life else { return }
        current.day += 1
        let day = current.day
        let weekdayIndex = (day - 1) % 7
        let weekday = Self.weekdays[weekdayIndex]
        let isWeekend = weekdayIndex >= 5
        let weather = Self.weatherKinds.randomElement() ?? Self.weatherKinds[0]
        var newEntries: [SLEntry] = []
        var hadCompany = false

        func add(_ time: String, _ icon: String, _ text: String, moodDelta: Double = 0) {
            newEntries.append(SLEntry(id: current.nextEntryId, day: day, time: time,
                                      icon: icon, text: text, isDayHeader: false))
            current.nextEntryId += 1
            current.mood = min(1, max(0, current.mood + moodDelta))
        }

        newEntries.append(SLEntry(id: current.nextEntryId, day: day, time: "", icon: "",
                                  text: "Day \(day) — \(weekday) \(weather.emoji)",
                                  isDayHeader: true))
        current.nextEntryId += 1

        // Morning
        let earlyRiser = current.traits.contains("early riser")
        let wakeTime = earlyRiser ? "06:1\(Int.random(in: 0...9))" : "07:4\(Int.random(in: 0...9))"
        var mornings = [
            ("sunrise", "\(current.name) wakes before the alarm and lies there, pleased about it.", 0.03),
            ("cup.and.saucer.fill", "Tea first. Everything else can wait.", 0.02),
            ("alarm", "Snoozed twice. Regretted both.", -0.02)
        ]
        if weather.name == "rainy" {
            mornings.append(("cloud.rain.fill",
                             current.traits.contains("rain lover")
                             ? "Rain on the roof. \(current.name) grins at the ceiling."
                             : "Rain again. The good socks are still damp.",
                             current.traits.contains("rain lover") ? 0.06 : -0.03))
        }
        if let cat = current.catName {
            mornings.append(("pawprint.fill", "\(cat) is sitting on \(current.name)'s chest, staring. Breakfast is demanded.", 0.05))
        }
        let morning = mornings.randomElement()!
        add(wakeTime, morning.0, morning.1, moodDelta: morning.2)

        // Daytime
        if isWeekend {
            let weekendEvents = [
                ("figure.walk", "A long walk with no destination. The village obliges.", 0.05),
                ("book.fill", "Half a novel in one sitting. The couch has won.", 0.04),
                ("cart.fill", "Market day. Came home with three things not on the list.", 0.02),
                ("paintbrush.fill", "Tried sketching the harbor. The boats look like shoes. Kept it anyway.", 0.03)
            ]
            let event = weekendEvents.randomElement()!
            add("11:\(Int.random(in: 10...59))", event.0, event.1, moodDelta: event.2)
        } else {
            current.money += 12
            let workEvents = [
                ("briefcase.fill", "A quiet shift as \(current.job). The clock and \(current.name) reach an understanding.", 0.0),
                ("briefcase.fill", "Work ran long. Somebody's mistake, nobody's apology.", -0.05),
                ("lightbulb.fill", "Solved a small problem at work no one will ever notice. \(current.name) notices.", 0.06),
                ("briefcase.fill", "The kind of workday that evaporates on the walk home.", 0.02)
            ]
            let event = workEvents.randomElement()!
            add("09:0\(Int.random(in: 0...9))", event.0, event.1, moodDelta: event.2)
        }

        // Midday quirk (sometimes)
        if Double.random(in: 0..<1) < 0.6 {
            var quirks = [
                ("sparkles", "A dog on the street chose \(current.name) today. Ten seconds of fame.", 0.06),
                ("cloud.sun.fill", "The light did something strange and golden around noon. Nobody else seemed to see it.", 0.04),
                ("fork.knife", "Lunch was just okay. This will be remembered unreasonably long.", -0.02)
            ]
            if current.traits.contains("afraid of geese") {
                quirks.append(("exclamationmark.triangle.fill", "A goose made eye contact. \(current.name) took the long way around.", -0.04))
            }
            if current.traits.contains("collects pebbles") {
                quirks.append(("circle.fill", "Found a flat gray pebble, nearly a perfect oval. A good day for the collection.", 0.05))
            }
            let quirk = quirks.randomElement()!
            add("13:\(Int.random(in: 10...59))", quirk.0, quirk.1, moodDelta: quirk.2)
        }

        // Afternoon fern impulse (before evening so the feed stays in
        // clock order).
        if !current.hasPlant && Double.random(in: 0..<1) < 0.06 {
            add("17:2\(Int.random(in: 0...9))", "leaf.fill",
                "Bought a small fern on impulse. It has opinions about the windowsill already.",
                moodDelta: 0.04)
            current.hasPlant = true
            current.money -= 6
        }

        // Evening — social or solitary
        if Double.random(in: 0..<1) < (isWeekend ? 0.65 : 0.45) {
            hadCompany = true
            let friend = current.friendName
            let socials = [
                ("person.2.fill", "\(friend), \(current.friendRole), waves \(current.name) over. They talk until the streetlights come on.", 0.08),
                ("cup.and.saucer.fill", "Coffee with \(friend). \(friend) does an impression of the mayor. It's terrible. It's perfect.", 0.09),
                ("person.2.fill", "\(friend) needed help carrying a table. Now there is soup, and company.", 0.07)
            ]
            let social = socials.randomElement()!
            add("18:\(Int.random(in: 10...59))", social.0, social.1, moodDelta: social.2)
        } else {
            let solos = [
                ("moon.stars.fill", "A quiet evening. The radio plays songs older than the house.", 0.02),
                ("book.fill", "Reading by the window until the words swim.", 0.03),
                ("tv.fill", "Fell asleep during a film. Woke up during the credits, weirdly refreshed.", 0.01)
            ]
            let solo = solos.randomElement()!
            add("20:\(Int.random(in: 10...59))", solo.0, solo.1, moodDelta: solo.2)
        }

        // Arcs
        current.lonelyStreak = hadCompany ? 0 : current.lonelyStreak + 1
        if current.catName == nil && current.lonelyStreak >= 3 && Double.random(in: 0..<1) < 0.4 {
            let cat = Self.catNames.randomElement() ?? "Beans"
            add("21:0\(Int.random(in: 0...9))", "pawprint.fill",
                "A small cat has been sitting outside for three evenings. Tonight \(current.name) opens the door. Their name, apparently, is \(cat).",
                moodDelta: 0.15)
            current.catName = cat
            current.lonelyStreak = 0
        }
        if !current.learningViolin && Double.random(in: 0..<1) < 0.04 {
            add("21:3\(Int.random(in: 0...9))", "music.note",
                "There's a violin in the attic. \(current.name) tunes it very badly and decides: lessons.",
                moodDelta: 0.06)
            current.learningViolin = true
        } else if current.learningViolin && Double.random(in: 0..<1) < 0.18 {
            let violins = [
                ("music.note", "Violin practice. The neighbors have stopped complaining, which might be progress.", 0.04),
                ("music.note", "Tonight the scale sounded almost like a scale. Almost.", 0.05)
            ]
            let violin = violins.randomElement()!
            add("21:1\(Int.random(in: 0...9))", violin.0, violin.1, moodDelta: violin.2)
        }
        // Night note
        let nights = [
            ("moon.zzz.fill", "Lights out. Tomorrow can have the rest.", 0.0),
            ("moon.zzz.fill", "Sleep comes easy tonight.", 0.02),
            ("moon.zzz.fill", "Stared at the ceiling a while, cataloguing the day. Verdict: kept.", 0.01)
        ]
        let night = nights.randomElement()!
        add("23:0\(Int.random(in: 0...9))", night.0, night.1, moodDelta: night.2)

        stagedLife = current
        pending = newEntries
    }
}

#Preview {
    SmallLifeGameView()
}
