//
//  WordGuessGameView.swift
//  ChordLab
//
//  Wordle-style word guessing: six tries to find a five-letter word.
//

import SwiftUI

struct WordGuessGameView: View {
    private enum LetterStatus: Int {
        case unknown = 0
        case absent = 1
        case present = 2
        case correct = 3

        var color: Color {
            switch self {
            case .unknown: return Color.appSecondaryBackground
            case .absent: return Color.gray.opacity(0.55)
            case .present: return Color.yellow.opacity(0.85)
            case .correct: return Color.green.opacity(0.85)
            }
        }
    }

    private static let answers: [String] = [
        "ABOUT", "ABOVE", "ACTOR", "ADMIT", "ADOPT", "AFTER", "AGAIN", "AGENT", "AGREE", "AHEAD",
        "ALARM", "ALBUM", "ALERT", "ALIEN", "ALIVE", "ALLOW", "ALONE", "ALONG", "ANGEL", "ANGER",
        "ANGLE", "ANGRY", "APART", "APPLE", "APPLY", "ARENA", "ARGUE", "ARISE", "ARRAY", "ASIDE",
        "ASSET", "AUDIO", "AVOID", "AWARD", "AWARE", "BADGE", "BAKER", "BASIC", "BEACH", "BEGAN",
        "BEGIN", "BEING", "BELOW", "BENCH", "BERRY", "BIRTH", "BLACK", "BLADE", "BLAME", "BLANK",
        "BLAST", "BLEND", "BLESS", "BLIND", "BLOCK", "BLOOD", "BLOOM", "BOARD", "BONUS", "BOOST",
        "BOOTH", "BOUND", "BRAIN", "BRAND", "BRAVE", "BREAD", "BREAK", "BRICK", "BRIDE", "BRIEF",
        "BRING", "BROAD", "BROWN", "BRUSH", "BUILD", "BUNCH", "BURST", "BUYER", "CABIN", "CABLE",
        "CANDY", "CARGO", "CARRY", "CATCH", "CAUSE", "CHAIN", "CHAIR", "CHALK", "CHAOS", "CHARM",
        "CHART", "CHASE", "CHEAP", "CHECK", "CHEEK", "CHEER", "CHESS", "CHEST", "CHIEF", "CHILD",
        "CHILL", "CHOIR", "CHOSE", "CIVIL", "CLAIM", "CLASS", "CLEAN", "CLEAR", "CLIMB", "CLOCK",
        "CLOSE", "CLOTH", "CLOUD", "COACH", "COAST", "COLOR", "COMET", "COMIC", "CORAL", "COUCH",
        "COULD", "COUNT", "COURT", "COVER", "CRACK", "CRAFT", "CRANE", "CRASH", "CRAZY", "CREAM",
        "CRIME", "CROSS", "CROWD", "CROWN", "CRUSH", "CURVE", "CYCLE", "DAILY", "DAIRY", "DANCE",
        "DEALT", "DEATH", "DEBUT", "DELAY", "DELTA", "DENSE", "DEPTH", "DERBY", "DIARY", "DIRTY",
        "DONOR", "DOUBT", "DOZEN", "DRAFT", "DRAIN", "DRAMA", "DREAM", "DRESS", "DRIFT", "DRILL",
        "DRINK", "DRIVE", "DROVE", "DYING", "EAGER", "EAGLE", "EARLY", "EARTH", "EIGHT", "ELBOW",
        "ELDER", "EMPTY", "ENEMY", "ENJOY", "ENTER", "ENTRY", "EQUAL", "ERROR", "EVENT", "EVERY",
        "EXACT", "EXIST", "EXTRA", "FAITH", "FALSE", "FANCY", "FAULT", "FAVOR", "FEAST", "FENCE",
        "FEVER", "FIBER", "FIELD", "FIFTH", "FIFTY", "FIGHT", "FINAL", "FIRST", "FLAME", "FLASH",
        "FLEET", "FLESH", "FLOAT", "FLOOD", "FLOOR", "FLOUR", "FLUID", "FLUTE", "FOCUS", "FORCE",
        "FORGE", "FORTH", "FORTY", "FORUM", "FOUND", "FRAME", "FRAUD", "FRESH", "FRONT", "FROST",
        "FRUIT", "FUNNY", "GHOST", "GIANT", "GIVEN", "GLASS", "GLOBE", "GLORY", "GLOVE", "GOING",
        "GRACE", "GRADE", "GRAIN", "GRAND", "GRANT", "GRAPE", "GRAPH", "GRASP", "GRASS", "GRAVE",
        "GREAT", "GREEN", "GREET", "GRIEF", "GRILL", "GROUP", "GROVE", "GROWN", "GUARD", "GUESS",
        "GUEST", "GUIDE", "HAPPY", "HEART", "HEAVY", "HELLO", "HENCE", "HOBBY", "HONEY", "HONOR",
        "HORSE", "HOTEL", "HOUSE", "HUMAN", "HUMOR", "IDEAL", "IMAGE", "INDEX", "INNER", "INPUT",
        "ISSUE", "IVORY", "JEANS", "JOINT", "JUDGE", "JUICE", "KNIFE", "KNOCK", "KNOWN", "LABEL",
        "LABOR", "LARGE", "LASER", "LATER", "LAUGH", "LAYER", "LEARN", "LEASE", "LEAST", "LEAVE",
        "LEGAL", "LEMON", "LEVEL", "LIGHT", "LIMIT", "LINEN", "LIVER", "LOCAL", "LOGIC", "LOOSE",
        "LOWER", "LOYAL", "LUCKY", "LUNAR", "LUNCH", "LYING", "MAGIC", "MAJOR", "MAKER", "MANGO",
        "MAPLE", "MARCH", "MATCH", "MAYBE", "MAYOR", "MEANT", "MEDAL", "MEDIA", "MELON", "MERCY",
        "MERGE", "MERIT", "METAL", "METER", "MIGHT", "MINOR", "MINUS", "MIXED", "MODEL", "MONEY",
        "MONTH", "MORAL", "MOTOR", "MOUNT", "MOUSE", "MOUTH", "MOVIE", "MUSIC", "NAVAL", "NERVE",
        "NEVER", "NIGHT", "NOBLE", "NOISE", "NORTH", "NOVEL", "NURSE", "OCCUR", "OCEAN", "OFFER",
        "OFTEN", "OLIVE", "ONION", "ORBIT", "ORDER", "ORGAN", "OTHER", "OUGHT", "OUNCE", "OUTER",
        "OWNER", "PAINT", "PANEL", "PANIC", "PAPER", "PARTY", "PASTA", "PATCH", "PAUSE", "PEACE",
        "PEACH", "PEARL", "PENNY", "PHASE", "PHONE", "PHOTO", "PIANO", "PIECE", "PILOT", "PITCH",
        "PIZZA", "PLACE", "PLAIN", "PLANE", "PLANT", "PLATE", "PLAZA", "POINT", "POLAR", "PORCH",
        "POUND", "POWER", "PRESS", "PRICE", "PRIDE", "PRIME", "PRINT", "PRIZE", "PROOF", "PROUD",
        "PROVE", "PULSE", "PUNCH", "PUPIL", "QUEEN", "QUEST", "QUICK", "QUIET", "QUITE", "QUOTE",
        "RADAR", "RADIO", "RAISE", "RALLY", "RANCH", "RANGE", "RAPID", "RATIO", "REACH", "REACT",
        "READY", "REALM", "REBEL", "REFER", "RELAX", "REPLY", "RIDGE", "RIGHT", "RIGID", "RIVAL",
        "RIVER", "ROAST", "ROBIN", "ROBOT", "ROCKY", "ROMAN", "ROUGH", "ROUND", "ROUTE", "ROYAL",
        "RURAL", "SALAD", "SAUCE", "SCALE", "SCENE", "SCOPE", "SCORE", "SCOUT", "SENSE", "SERVE",
        "SEVEN", "SHADE", "SHAKE", "SHALL", "SHAPE", "SHARE", "SHARK", "SHARP", "SHEEP", "SHEET",
        "SHELF", "SHELL", "SHIFT", "SHINE", "SHIRT", "SHOCK", "SHORE", "SHORT", "SHOUT", "SHOWN",
        "SIGHT", "SILLY", "SINCE", "SIXTH", "SIXTY", "SKILL", "SKIRT", "SLEEP", "SLICE", "SLIDE",
        "SLOPE", "SMALL", "SMART", "SMILE", "SMOKE", "SNACK", "SNAKE", "SOLAR", "SOLID", "SOLVE",
        "SORRY", "SOUND", "SOUTH", "SPACE", "SPARE", "SPARK", "SPEAK", "SPEED", "SPEND", "SPICE",
        "SPINE", "SPLIT", "SPOKE", "SPORT", "SPRAY", "SQUAD", "STAFF", "STAGE", "STAIR", "STAKE",
        "STAMP", "STAND", "START", "STATE", "STEAK", "STEAM", "STEEL", "STEEP", "STICK", "STILL",
        "STOCK", "STONE", "STOOD", "STORE", "STORM", "STORY", "STOVE", "STRAP", "STRAW", "STRIP",
        "STUCK", "STUDY", "STUFF", "STYLE", "SUGAR", "SUITE", "SUNNY", "SUPER", "SWEEP", "SWEET",
        "SWIFT", "SWING", "TABLE", "TAKEN", "TASTE", "TEACH", "TEETH", "TEMPO", "TENTH", "THANK",
        "THEFT", "THEME", "THERE", "THESE", "THICK", "THING", "THINK", "THIRD", "THOSE", "THREE",
        "THREW", "THROW", "THUMB", "TIGER", "TIGHT", "TIMER", "TITLE", "TOAST", "TODAY", "TOKEN",
        "TOPIC", "TORCH", "TOTAL", "TOUCH", "TOUGH", "TOWER", "TRACE", "TRACK", "TRADE", "TRAIL",
        "TRAIN", "TREAT", "TREND", "TRIAL", "TRIBE", "TRICK", "TRIED", "TRUCK", "TRULY", "TRUNK",
        "TRUST", "TRUTH", "TWICE", "UNCLE", "UNDER", "UNION", "UNITE", "UNITY", "UNTIL", "UPPER",
        "UPSET", "URBAN", "USAGE", "USUAL", "VALID", "VALUE", "VAPOR", "VENUE", "VERSE", "VIDEO",
        "VIRUS", "VISIT", "VITAL", "VIVID", "VOCAL", "VOICE", "VOTER", "WAGON", "WASTE", "WATCH",
        "WATER", "WHALE", "WHEAT", "WHEEL", "WHERE", "WHICH", "WHILE", "WHITE", "WHOLE", "WHOSE",
        "WIDTH", "WOMAN", "WORLD", "WORRY", "WORSE", "WORST", "WORTH", "WOULD", "WOUND", "WRIST",
        "WRITE", "WRONG", "WROTE", "YACHT", "YIELD", "YOUNG", "YOUTH"
    ]

    private static let keyboardRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["⏎", "Z", "X", "C", "V", "B", "N", "M", "⌫"]
    ]

    @State private var answer = ""
    @State private var guesses: [String] = []
    @State private var currentGuess = ""
    @State private var isWon = false
    @State private var isLost = false
    @State private var shakeRow = false
    @State private var streak = 0
    @State private var isNewRecord = false

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "wordguess")!, onRestart: { newRound(resetStreak: true) }) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatPill(label: "Streak", value: "\(streak)", tint: .green)
                    StatPill(label: "Best", value: "\(GameScores.shared.best(for: "wordguess") ?? 0)")
                }

                Spacer(minLength: 0)

                letterGrid
                    .padding(.horizontal, 32)

                Spacer(minLength: 0)

                keyboard
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .overlay {
                if isWon || isLost {
                    GameOverOverlay(
                        title: isWon ? "Got it!" : "Out of tries",
                        subtitle: isWon
                            ? "\(answer) in \(guesses.count) guess\(guesses.count == 1 ? "" : "es")"
                            : "The word was \(answer)",
                        isVictory: isWon,
                        newRecord: isNewRecord,
                        buttonTitle: "Next Word"
                    ) {
                        newRound(resetStreak: false)
                    }
                }
            }
            .onAppear {
                if answer.isEmpty {
                    newRound(resetStreak: true)
                }
            }
        }
    }

    // MARK: - Grid

    private var letterGrid: some View {
        VStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { col in
                        letterTile(row: row, col: col)
                    }
                }
                .modifier(WordGuessShake(shakes: row == guesses.count && shakeRow ? 2 : 0))
            }
        }
    }

    private func letterTile(row: Int, col: Int) -> some View {
        let letter: String
        let status: LetterStatus

        if row < guesses.count {
            let guess = guesses[row]
            letter = String(Array(guess)[col])
            status = statuses(for: guess)[col]
        } else if row == guesses.count && !isWon && !isLost {
            let chars = Array(currentGuess)
            letter = col < chars.count ? String(chars[col]) : ""
            status = .unknown
        } else {
            letter = ""
            status = .unknown
        }

        return Text(letter)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(status == .unknown ? Color.primary : Color.white)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(status.color, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(letter.isEmpty ? Color.appBorder.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.2), value: status)
    }

    /// Wordle scoring with correct duplicate-letter handling.
    private func statuses(for guess: String) -> [LetterStatus] {
        let guessChars = Array(guess)
        let answerChars = Array(answer)
        var result = Array(repeating: LetterStatus.absent, count: 5)
        var remaining: [Character: Int] = [:]

        for i in 0..<5 {
            if guessChars[i] == answerChars[i] {
                result[i] = .correct
            } else {
                remaining[answerChars[i], default: 0] += 1
            }
        }
        for i in 0..<5 where result[i] != .correct {
            if let count = remaining[guessChars[i]], count > 0 {
                result[i] = .present
                remaining[guessChars[i]] = count - 1
            }
        }
        return result
    }

    // MARK: - Keyboard

    private func keyStatus(_ letter: String) -> LetterStatus {
        var best = LetterStatus.unknown
        for guess in guesses {
            let guessChars = Array(guess)
            let guessStatuses = statuses(for: guess)
            for i in 0..<5 where String(guessChars[i]) == letter {
                if guessStatuses[i].rawValue > best.rawValue {
                    best = guessStatuses[i]
                }
            }
        }
        return best
    }

    private var keyboard: some View {
        VStack(spacing: 7) {
            ForEach(0..<Self.keyboardRows.count, id: \.self) { rowIndex in
                HStack(spacing: 5) {
                    ForEach(Self.keyboardRows[rowIndex], id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
    }

    private func keyButton(_ key: String) -> some View {
        let isSpecial = key == "⏎" || key == "⌫"
        let status = isSpecial ? LetterStatus.unknown : keyStatus(key)

        return Button {
            handleKey(key)
        } label: {
            Text(key)
                .font(.system(size: isSpecial ? 18 : 16, weight: .semibold, design: .rounded))
                .foregroundStyle(status == .unknown ? Color.primary : Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(status.color, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: isSpecial ? 54 : .infinity)
    }

    private func handleKey(_ key: String) {
        guard !isWon && !isLost else { return }
        switch key {
        case "⌫":
            guard !currentGuess.isEmpty else { return }
            GameHaptics.tap()
            currentGuess.removeLast()
        case "⏎":
            submitGuess()
        default:
            guard currentGuess.count < 5 else { return }
            GameHaptics.tap()
            currentGuess.append(key)
        }
    }

    private func submitGuess() {
        guard currentGuess.count == 5 else {
            GameHaptics.warning()
            withAnimation(.default) { shakeRow = true }
            Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                shakeRow = false
            }
            return
        }

        GameHaptics.medium()
        guesses.append(currentGuess)
        let guessed = currentGuess
        currentGuess = ""

        if guessed == answer {
            isWon = true
            streak += 1
            isNewRecord = GameScores.shared.report(score: streak, for: "wordguess")
            GameHaptics.success()
        } else if guesses.count == 6 {
            isLost = true
            streak = 0
            isNewRecord = false
            GameHaptics.error()
        }
    }

    private func newRound(resetStreak: Bool) {
        if resetStreak {
            streak = 0
        }
        answer = Self.answers.randomElement() ?? "PIANO"
        guesses = []
        currentGuess = ""
        isWon = false
        isLost = false
        isNewRecord = false
    }
}

/// Small horizontal shake for invalid submissions.
private struct WordGuessShake: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 4), y: 0))
    }
}

#Preview {
    WordGuessGameView()
}
