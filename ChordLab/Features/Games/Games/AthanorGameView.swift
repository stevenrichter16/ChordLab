//
//  AthanorGameView.swift
//  ChordLab
//
//  ATHANOR: a deterministic turn-based tactical roguelite. Descend the
//  Alchemist's furnace-tower as Cinderwick the candle-homunculus, using
//  ten exact chemistry rules as your arsenal. One pure rules engine
//  drives ghost previews, the projection line, and commits alike — the
//  preview can never lie, because it IS the resolution.
//

import SwiftUI

struct AthanorGameView: View {

    // MARK: - Grid geometry & seeded RNG

    struct Pt: Codable, Hashable {
        var x: Int
        var y: Int
        static func + (l: Pt, r: Pt) -> Pt { Pt(x: l.x + r.x, y: l.y + r.y) }
        func dist(_ o: Pt) -> Int { abs(x - o.x) + abs(y - o.y) }
        var inBounds: Bool { x >= 0 && x < 5 && y >= 0 && y < 5 }
        var idx: Int { y * 5 + x }
        static let dirs: [Pt] = [Pt(x: 0, y: -1), Pt(x: 0, y: 1), Pt(x: -1, y: 0), Pt(x: 1, y: 0)]
    }

    /// All RNG lives in floor generation, seeded from the stored run seed —
    /// never SystemRandomNumberGenerator, so resumed runs regenerate
    /// identical future floors. resolve() contains zero randomness.
    struct SplitMix64 {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        mutating func int(_ range: Range<Int>) -> Int {
            range.lowerBound + Int(next() % UInt64(range.count))
        }
    }

    // MARK: - Core enums

    enum Surface: String, Codable {
        case none, water, oil, fire, ice, steam, vat

        var mark: String {
            switch self {
            case .none: return ""
            case .water: return "💧"
            case .oil: return "🛢️"
            case .fire: return "🔥"
            case .ice: return "🧊"
            case .steam: return "☁️"
            case .vat: return "⚫"
            }
        }
    }

    enum DmgType: String, Codable { case phys, fire, shock, frost, collision, vat, burn }

    enum Biome: String, Codable {
        case cisterns, renderingVats, frostGallery, greatWork

        var title: String {
            switch self {
            case .cisterns: return "The Cisterns"
            case .renderingVats: return "The Rendering Vats"
            case .frostGallery: return "The Frost Gallery"
            case .greatWork: return "The Great Work"
            }
        }

        var tint: Color {
            switch self {
            case .cisterns: return .teal
            case .renderingVats: return .orange
            case .frostGallery: return .cyan
            case .greatWork: return .yellow
            }
        }
    }

    enum WeaponKind: String, Codable, CaseIterable {
        case hammer, rapier, spear, sling, alembic, frostKnife

        var emoji: String {
            switch self {
            case .hammer: return "🔨"
            case .rapier: return "🤺"
            case .spear: return "🔱"
            case .sling: return "🪨"
            case .alembic: return "⚗️"
            case .frostKnife: return "🔪"
            }
        }

        var name: String {
            switch self {
            case .hammer: return "Hammer of Sorting"
            case .rapier: return "Rapier of Proof"
            case .spear: return "Longspear"
            case .sling: return "Sling of Weights"
            case .alembic: return "Alembic Staff"
            case .frostKnife: return "Frost Knife"
            }
        }

        var blurb: String {
            switch self {
            case .hammer: return "2 phys adjacent + push 1."
            case .rapier: return "2 phys adjacent; +1 dmg and AP refunded vs any status."
            case .spear: return "1 phys to two tiles in a line, then a free 1-step retreat."
            case .sling: return "1 phys at range 2–4 (never adjacent!) + push 1 away."
            case .alembic: return "1 phys adjacent, +1🔮 on hit."
            case .frostKnife: return "1 phys adjacent; Wet targets freeze solid."
            }
        }

        var baseDamage: Int {
            switch self {
            case .hammer, .rapier: return 2
            default: return 1
            }
        }
    }

    enum SpellKind: String, Codable, CaseIterable {
        case spark, candleflame, gust, undertow, hoarfrost, oilslick,
             fulminate, mirrorwax, transpose, emberWaltz, leyburst

        static let starting: [SpellKind] = [.spark, .candleflame, .gust]
        static let findable: [SpellKind] = allCases.filter { !starting.contains($0) }

        var emoji: String {
            switch self {
            case .spark: return "⚡"
            case .candleflame: return "🔥"
            case .gust: return "💨"
            case .undertow: return "🌊"
            case .hoarfrost: return "❄️"
            case .oilslick: return "🛢️"
            case .fulminate: return "🌩️"
            case .mirrorwax: return "🪞"
            case .transpose: return "🔁"
            case .emberWaltz: return "💃"
            case .leyburst: return "💥"
            }
        }

        var name: String {
            switch self {
            case .spark: return "Spark"
            case .candleflame: return "Candleflame"
            case .gust: return "Gust"
            case .undertow: return "Undertow"
            case .hoarfrost: return "Hoarfrost"
            case .oilslick: return "Oilslick"
            case .fulminate: return "Fulminate"
            case .mirrorwax: return "Mirrorwax"
            case .transpose: return "Transpose"
            case .emberWaltz: return "Ember Waltz"
            case .leyburst: return "Leyburst"
            }
        }

        var ap: Int {
            switch self {
            case .transpose, .leyburst: return 2
            default: return 1
            }
        }

        /// Leyburst's 1 is its minimum X; it spends ALL remaining mana.
        var mp: Int {
            switch self {
            case .hoarfrost, .mirrorwax, .transpose, .emberWaltz: return 2
            case .fulminate: return 3
            default: return 1
            }
        }

        var blurb: String {
            switch self {
            case .spark: return "2 shock, range 3. Electrifies whole pools."
            case .candleflame: return "Set a tile within 3 on fire (occupant burns; water → steam)."
            case .gust: return "Push a unit 2 tiles in a line. Tap a tile beside you to push yourself."
            case .undertow: return "Pull a unit within 4 up to 2 tiles toward you."
            case .hoarfrost: return "1 frost to a unit (Freeze if Wet), or turn a water tile to ice."
            case .oilslick: return "Coat a 3-tile line in oil; units on it become Oiled."
            case .fulminate: return "3 shock, range 3; on kill, arcs to the nearest enemy within 2 for 2."
            case .mirrorwax: return "The next enemy hit on you redirects to a chosen adjacent tile."
            case .transpose: return "Swap positions with any unit in line of sight."
            case .emberWaltz: return "Teleport up to 3 tiles; the tile you left catches fire."
            case .leyburst: return "X = ALL remaining 🔮 (min 1): X shock to every unit within X — you included."
            }
        }
    }

    enum PrecipitateKind: String, Codable, CaseIterable {
        case catalyst, bellows, refundCoil, waxHeart, reservoir, insulatedSole, sharpProof, secondWind

        var emoji: String {
            switch self {
            case .catalyst: return "🧪"
            case .bellows: return "🌬️"
            case .refundCoil: return "🌀"
            case .waxHeart: return "🫀"
            case .reservoir: return "🔮"
            case .insulatedSole: return "🥾"
            case .sharpProof: return "🗡️"
            case .secondWind: return "🕯️"
            }
        }

        var name: String {
            switch self {
            case .catalyst: return "Catalyst"
            case .bellows: return "Long Bellows"
            case .refundCoil: return "Refund Coil"
            case .waxHeart: return "Wax Heart"
            case .reservoir: return "Deep Reservoir"
            case .insulatedSole: return "Insulated Sole"
            case .sharpProof: return "Sharp Proof"
            case .secondWind: return "Second Wind"
            }
        }

        var blurb: String {
            switch self {
            case .catalyst: return "Wet enemies take +1 from all sources."
            case .bellows: return "Gust and Undertow move targets +1 tile."
            case .refundCoil: return "Overchannel HP is refunded if the cast kills."
            case .waxHeart: return "+2 max HP, and heal 2 now."
            case .reservoir: return "+1 max MP (cap 5)."
            case .insulatedSole: return "You never slide on ice; fire tiles don't ignite you at tick."
            case .sharpProof: return "Your weapon deals +1 to statused targets."
            case .secondWind: return "The first death this run leaves you at 1 HP instead."
            }
        }
    }

    enum UnitKind: String, Codable {
        case hero, rat, eel, golem, cherub, fungus, crab, sporeling, regret, queen, docent, remnant

        var emoji: String {
            switch self {
            case .hero: return "🕯️"
            case .rat: return "🐀"
            case .eel: return "🪱"
            case .golem: return "🧈"
            case .cherub: return "🪞"
            case .fungus: return "🍄"
            case .crab: return "🦀"
            case .sporeling: return "🟤"
            case .regret: return "🫧"
            case .queen: return "👑"
            case .docent: return "🗿"
            case .remnant: return "🫠"
            }
        }

        var name: String {
            switch self {
            case .hero: return "Cinderwick"
            case .rat: return "Cinder Rat"
            case .eel: return "Bolt Eel"
            case .golem: return "Wax Golem"
            case .cherub: return "Mirror Cherub"
            case .fungus: return "Grudge Fungus"
            case .crab: return "Undertaker Crab"
            case .sporeling: return "Sporeling"
            case .regret: return "The Alchemist's Regret"
            case .queen: return "Tallow Queen"
            case .docent: return "Clockwork Docent"
            case .remnant: return "Wax Remnant"
            }
        }

        var isEnemy: Bool { self != .hero && self != .remnant }
        var heavy: Bool { self == .golem || self == .queen }
        var flying: Bool { self == .cherub }

        var baseHP: Int {
            switch self {
            case .hero: return 10
            case .rat: return 2
            case .eel: return 3
            case .golem: return 5
            case .cherub: return 2
            case .fungus: return 3
            case .crab: return 4
            case .sporeling: return 1
            case .regret: return 8
            case .queen: return 12
            case .docent: return 14
            case .remnant: return 3
            }
        }

        var moveRange: Int {
            switch self {
            case .rat: return 3
            case .fungus, .remnant, .docent: return 0
            case .golem, .regret, .queen: return 1
            default: return 2
            }
        }

        var gimmick: String {
            switch self {
            case .hero: return "the Alchemist's last homunculus"
            case .rat: return "death: drops fire on its tile"
            case .eel: return "shock-immune; flops (+1 phys, skips turns) if its pool is gone"
            case .golem: return "heavy; +2 from fire; melts while burning (−1 max HP, leaves oil)"
            case .cherub: return "flies; reflects spells targeted at it back at you"
            case .fungus: return "immobile; death: splits into two sporelings unless killed by fire"
            case .crab: return "shell negates the first hit each round; collisions crack it"
            case .sporeling: return "a grudge, in miniature"
            case .regret: return "alternates: flood a 2×2, then spark every water tile"
            case .queen: return "heavy; fire-immune, never Wet; oils every tile she exits"
            case .docent: return "every 🔮 you spend upgrades its queued damage by +1"
            case .remnant: return "strikes the nearest enemy with a dead keeper's weapon"
            }
        }
    }

    // MARK: - Board pieces

    struct Tile: Codable {
        var surface: Surface = .none
        var steamTicks: Int = 0
        var isTransmuter: Bool = false
    }

    enum IntentKind: String, Codable { case strike, poolZap, drag, flood, sparkTiles, igniteTiles, summonRats }

    /// Enemy attacks lock their target TILES here at telegraph time and
    /// resolve against exactly these tiles — step out and they whiff.
    struct Intent: Codable {
        var kind: IntentKind
        var tiles: [Pt]
        var damage: Int
        var summonAlso: [Pt] = []
        var floodFirst: Bool = false
        var text: String
    }

    struct Unit: Codable, Identifiable {
        var id: Int
        var kind: UnitKind
        var pos: Pt
        var hp: Int
        var maxHP: Int
        var wet = false
        var burn = 0
        var frozen = false
        var oiled = false
        var shellActive = true
        var flopping = false
        var phaseCounter = 0
        var intent: Intent? = nil

        var hasStatus: Bool { wet || burn > 0 || frozen || oiled }
        var statusLine: String {
            var s = ""
            if wet { s += "💧" }
            if burn > 0 { s += "🔥" }
            if frozen { s += "❄️" }
            if oiled { s += "🛢️" }
            return s
        }
    }

    /// The whole game as a value type: undo is a snapshot push, preview is
    /// a copy, persistence is one Codable encode.
    struct BoardState: Codable {
        var depth: Int = 1
        var runSeed: UInt64 = 0
        var turn: Int = 1
        var tiles: [Tile] = Array(repeating: Tile(), count: 25)
        var units: [Unit] = []
        var nextId: Int = 1
        var mp: Int = 3
        var maxMP: Int = 3
        var ap: Int = 3
        var kindleUsed = false
        var weapon: WeaponKind = .hammer
        var spells: [SpellKind] = SpellKind.starting
        var precipitates: [PrecipitateKind] = []
        var secondWindUsed = false
        var mirrorTile: Pt? = nil
        var docentBonus = 0
        var overchanneledThisRun = false
        var spearRetreatTo: Pt? = nil
        var remnantWeapon: WeaponKind? = nil
        var heroDead = false
        var lastKillerType: String = "phys"
        // Per-player-phase feat counters live in the snapshot so Undo,
        // mid-turn saves and the enemy-phase replay all stay honest.
        var killsThisTurn = 0
        var freezesThisTurn = 0

        var hero: Unit? { units.first { $0.kind == .hero } }
        var heroIndex: Int? { units.firstIndex { $0.kind == .hero } }
        var enemies: [Unit] { units.filter { $0.kind.isEnemy } }
        func unit(at p: Pt) -> Unit? { units.first { $0.pos == p } }
        func unitIndex(at p: Pt) -> Int? { units.firstIndex { $0.pos == p } }
        func index(of id: Int) -> Int? { units.firstIndex { $0.id == id } }
        func has(_ p: PrecipitateKind) -> Bool { precipitates.contains(p) }

        subscript(_ p: Pt) -> Tile {
            get { tiles[p.idx] }
            set { tiles[p.idx] = newValue }
        }
    }

    // MARK: - Actions & events

    enum Action {
        case move([Pt])                              // step directions
        case strike(Pt)
        case cast(SpellKind, Pt, overHP: Int)
        case kindle
        case spearRetreat
        case enemyAct(Int)
        case tick
        case beginPlayerTurn
    }

    enum Event {
        case hit(Pt, Int, String)                    // pos, amount, victim emoji
        case die(Pt, String, Bool)                   // pos, emoji, isEnemy
        case surface(Pt, Surface)
        case frozen(Pt)
        case status(Pt, String)
        case moved(Int, Pt)
        case note(String)
        case whiff(String)

        var isReaction: Bool {
            switch self {
            case .die, .surface, .frozen, .status: return true
            default: return false
            }
        }

        var brief: String? {
            switch self {
            case .hit(_, let n, let e): return "\(e) −\(n)"
            case .die(_, let e, _): return "\(e)💀"
            case .surface(_, let sf): return sf == .none ? "clears" : sf.mark
            case .frozen: return "❄️ frozen"
            case .status(_, let t): return t
            case .moved: return nil
            case .note(let t): return t
            case .whiff(let w): return "\(w) whiffs"
            }
        }
    }

    // MARK: - Rules engine
    //
    // ONE pure resolve path. Ghost previews run it on a copy; commits run
    // it on the real state; the projection line runs the whole enemy phase
    // on a copy. Zero randomness anywhere below.

    enum Engine {

        static let allTiles: [Pt] = (0..<25).map { Pt(x: $0 % 5, y: $0 / 5) }

        static func resolve(_ action: Action, _ s: inout BoardState) -> [Event] {
            var ev: [Event] = []
            switch action {
            case .move(let steps):
                heroMove(steps, &s, &ev)
            case .strike(let target):
                weaponStrike(at: target, &s, &ev)
            case .cast(let spell, let target, let overHP):
                cast(spell, at: target, overHP: overHP, &s, &ev)
            case .kindle:
                if let h = s.heroIndex, s.units[h].hp > 1, s.mp < s.maxMP, !s.kindleUsed {
                    s.units[h].hp -= 1
                    s.mp += 1
                    s.kindleUsed = true
                    ev.append(.note("kindle: 1❤️ → 1🔮"))
                }
            case .spearRetreat:
                spearRetreat(&s, &ev)
            case .enemyAct(let id):
                enemyAct(id, &s, &ev)
            case .tick:
                tick(&s, &ev)
            case .beginPlayerTurn:
                beginPlayerTurn(&s, &ev)
            }
            return ev
        }

        // MARK: Damage pipeline — every chemistry modifier lives here

        static func damage(_ id: Int, _ base: Int, _ type: DmgType,
                           _ s: inout BoardState, _ ev: inout [Event], chainPools: Bool = true) {
            guard let i = s.index(of: id) else { return }
            let kind = s.units[i].kind
            if kind == .queen && (type == .fire || type == .burn) { ev.append(.note("👑 fire-immune")); return }

            // Rule 2: shock hitting a unit in water electrifies the whole
            // connected pool — every unit standing in it takes the damage.
            // Checked BEFORE eel immunity: shock aimed at the eel still
            // conducts; the eel itself takes 0 in the per-victim pass.
            if type == .shock && chainPools && s[s.units[i].pos].surface == .water {
                let pool = floodFillWater(from: s.units[i].pos, s)
                let victims = s.units.filter { pool.contains($0.pos) }.map(\.id)
                if victims.count > 1 { ev.append(.note("⚡ the pool conducts")) }
                for v in victims { damage(v, base, .shock, &s, &ev, chainPools: false) }
                return
            }
            if kind == .eel && type == .shock { ev.append(.note("🪱 shock-immune")); return }

            var amount = base
            let u = s.units[i]

            // Crab shell: first non-collision hit each round is negated;
            // collision damage cracks it instead (and still lands). Burn
            // ticks bypass it entirely — rule 6's 1/tick is unconditional.
            if kind == .crab && u.shellActive && type != .burn {
                s.units[i].shellActive = false
                if type != .collision && type != .vat {
                    ev.append(.status(u.pos, "🦀 shell absorbs the hit"))
                    return
                }
                ev.append(.status(u.pos, "🦀 shell cracks"))
            }

            if u.wet && type == .shock { amount += 1 }                       // rule 5
            if u.wet && kind.isEnemy && s.has(.catalyst) { amount += 1 }     // precipitate
            if kind == .eel && u.flopping && type == .phys { amount += 1 }

            if type == .fire || type == .burn {
                // Golems take +2 from DIRECT fire only; burn ticks stay
                // the rule-6 flat 1 so the melt attrition is observable.
                if kind == .golem && type == .fire { amount += 2 }
                if u.oiled {                                                  // rule 6
                    amount += 1
                    s.units[i].oiled = false
                    if !u.wet {
                        s.units[i].burn = max(s.units[i].burn, 2)
                        ev.append(.status(u.pos, "oil ignites"))
                    }
                }
            }

            if type == .frost && u.wet && !u.frozen {                         // rule 3
                s.units[i].frozen = true
                if kind.isEnemy { s.freezesThisTurn += 1 }
                ev.append(.frozen(u.pos))
            } else if u.frozen && (type == .phys || type == .collision) {     // rule 7
                amount += 2
                s.units[i].frozen = false
                ev.append(.status(u.pos, "freeze shatters"))
            }

            s.units[i].hp -= amount
            ev.append(.hit(s.units[i].pos, amount, kind.emoji))
            if s.units[i].hp <= 0 { kill(id, by: type, &s, &ev) }
        }

        /// Rule 10: death triggers resolve inside the same cascade, and a
        /// kill cancels the victim's telegraphed action (the unit — and its
        /// locked intent — is simply gone).
        static func kill(_ id: Int, by type: DmgType, _ s: inout BoardState, _ ev: inout [Event]) {
            guard let i = s.index(of: id) else { return }
            let u = s.units[i]
            if u.kind == .hero {
                if s.has(.secondWind) && !s.secondWindUsed {
                    s.secondWindUsed = true
                    s.units[i].hp = 1
                    ev.append(.note("Second Wind — held at 1❤️"))
                    return
                }
                s.units[i].hp = 0
                s.heroDead = true
                s.lastKillerType = type.rawValue
                ev.append(.die(u.pos, u.kind.emoji, false))
                return
            }
            s.units.remove(at: i)
            ev.append(.die(u.pos, u.kind.emoji, u.kind.isEnemy))
            if u.kind.isEnemy { s.killsThisTurn += 1 }
            switch u.kind {
            case .rat:
                ignite(u.pos, &s, &ev)
            case .fungus:
                if type != .fire && type != .burn {
                    var spawned = 0
                    for d in Pt.dirs {
                        let p = u.pos + d
                        guard spawned < 2, p.inBounds, s[p].surface != .vat, s.unit(at: p) == nil else { continue }
                        s.units.append(Unit(id: s.nextId, kind: .sporeling, pos: p,
                                            hp: 1, maxHP: 1))
                        s.nextId += 1
                        spawned += 1
                    }
                    if spawned > 0 { ev.append(.note("🍄 splits into sporelings")) }
                }
            default:
                break
            }
        }

        static func floodFillWater(from p: Pt, _ s: BoardState) -> Set<Pt> {
            guard s[p].surface == .water else { return [] }
            var seen: Set<Pt> = [p]
            var queue = [p]
            while let cur = queue.popLast() {
                for d in Pt.dirs {
                    let n = cur + d
                    if n.inBounds, !seen.contains(n), s[n].surface == .water {
                        seen.insert(n)
                        queue.append(n)
                    }
                }
            }
            return seen
        }

        // MARK: Fire & surfaces

        /// Fire arriving on a tile. Rule 1: water boils to steam. Rule 4:
        /// oil catches. Vats swallow it. Occupants take fire contact.
        static func ignite(_ p: Pt, _ s: inout BoardState, _ ev: inout [Event]) {
            switch s[p].surface {
            case .vat:
                return
            case .water:
                s[p].surface = .steam
                s[p].steamTicks = 2
                ev.append(.surface(p, .steam))
            default:
                s[p].surface = .fire
                ev.append(.surface(p, .fire))
            }
            if s[p].surface == .fire, let i = s.unitIndex(at: p) { fireContact(i, &s, &ev) }
        }

        /// Rule 1/6: a Wet unit sheds wet instead of igniting; an Oiled
        /// unit takes +1 fire and is guaranteed Burning.
        static func fireContact(_ i: Int, _ s: inout BoardState, _ ev: inout [Event]) {
            let u = s.units[i]
            if u.kind.flying || u.kind == .queen { return }
            if u.wet {
                s.units[i].wet = false
                ev.append(.status(u.pos, "wet sizzles away"))
                return
            }
            if u.oiled {
                s.units[i].oiled = false
                damage(u.id, 1, .fire, &s, &ev)
                if let j = s.index(of: u.id) {
                    s.units[j].burn = max(s.units[j].burn, 2)
                    ev.append(.status(s.units[j].pos, "oil ignites"))
                }
                return
            }
            if u.burn == 0 { ev.append(.status(u.pos, "\(u.kind.emoji) burning")) }
            s.units[i].burn = max(s.units[i].burn, 2)
        }

        // MARK: Movement — walking, slides, pushes, collisions

        static func canEnter(_ p: Pt, _ u: Unit, _ s: BoardState) -> Bool {
            guard p.inBounds, s.unit(at: p) == nil else { return false }
            if s[p].surface == .vat && !u.kind.flying { return false }
            if u.kind == .eel && s[p].surface != .water && s[p].surface != .ice { return false }
            return true
        }

        static func slides(_ u: Unit, _ s: BoardState) -> Bool {
            if u.kind.flying { return false }
            if u.kind == .hero && s.has(.insulatedSole) { return false }
            return true
        }

        /// One walking step, rule-9 slide included. Returns false when
        /// walking must end (blocked, or a slide took over).
        static func walkStep(_ id: Int, _ dir: Pt, _ s: inout BoardState, _ ev: inout [Event]) -> Bool {
            guard let i = s.index(of: id) else { return false }
            let dest = s.units[i].pos + dir
            guard canEnter(dest, s.units[i], s) else { return false }
            s.units[i].pos = dest
            enterTile(i, &s, &ev)
            if s[dest].surface == .ice && slides(s.units[i], s) {
                slide(id, dir, &s, &ev)
                return false
            }
            return true
        }

        /// Rule 5: entering water makes a unit Wet and douses Burning.
        static func enterTile(_ i: Int, _ s: inout BoardState, _ ev: inout [Event]) {
            let u = s.units[i]
            if u.kind.flying || u.kind == .queen { return }
            if s[u.pos].surface == .water {
                if !u.wet { ev.append(.status(u.pos, "\(u.kind.emoji) wet")) }
                s.units[i].wet = true
                if s.units[i].burn > 0 {
                    s.units[i].burn = 0
                    ev.append(.status(u.pos, "doused"))
                }
            }
        }

        /// Rule 9: keep going in the entry direction until a non-ice tile
        /// or an obstruction (rule-8 collision), vats included.
        static func slide(_ id: Int, _ dir: Pt, _ s: inout BoardState, _ ev: inout [Event]) {
            var guardCount = 0
            while guardCount < 8 {
                guardCount += 1
                guard let i = s.index(of: id), s[s.units[i].pos].surface == .ice else { return }
                let next = s.units[i].pos + dir
                if !next.inBounds || s.unit(at: next) != nil {
                    collide(id, into: next, &s, &ev)
                    return
                }
                if s[next].surface == .vat && !s.units[i].kind.flying {
                    if s.units[i].kind.heavy {
                        damage(id, 2, .collision, &s, &ev)
                        return
                    }
                    fallInVat(id, from: s.units[i].pos, into: next, &s, &ev)
                    return
                }
                if s.units[i].kind == .eel,
                   s[next].surface != .water, s[next].surface != .ice {
                    return  // eels stop at the pool's edge — never beached
                }
                s.units[i].pos = next
                enterTile(i, &s, &ev)
            }
        }

        /// Vat falls kill (rule 8). If Second Wind saves the hero, the wick
        /// catches the lip — hauled back to the tile before the vat.
        static func fallInVat(_ id: Int, from prev: Pt, into vat: Pt,
                              _ s: inout BoardState, _ ev: inout [Event]) {
            guard let i = s.index(of: id) else { return }
            s.units[i].pos = vat
            ev.append(.moved(id, vat))
            kill(id, by: .vat, &s, &ev)
            if let j = s.index(of: id), s.units[j].hp > 0 {
                s.units[j].pos = prev
                ev.append(.moved(id, prev))
                ev.append(.note("hauled back over the lip"))
            }
        }

        /// Rule 8: collision deals 1 to BOTH parties (walls count as one).
        static func collide(_ id: Int, into p: Pt, _ s: inout BoardState, _ ev: inout [Event]) {
            ev.append(.note("collision"))
            if let other = s.unit(at: p) { damage(other.id, 1, .collision, &s, &ev) }
            damage(id, 1, .collision, &s, &ev)
        }

        /// Push/pull `count` tiles along dir (rule 8), with rule-9 slides
        /// taking over on ice and landing contact at the final tile.
        static func displace(_ id: Int, _ dir: Pt, _ count: Int, _ s: inout BoardState, _ ev: inout [Event]) {
            var remaining = count
            var moved = false
            while remaining > 0 {
                remaining -= 1
                guard let i = s.index(of: id) else { return }
                let u = s.units[i]
                let next = u.pos + dir
                if !next.inBounds || s.unit(at: next) != nil {
                    collide(id, into: next, &s, &ev)
                    break
                }
                if s[next].surface == .vat && !u.kind.flying {
                    if u.kind.heavy {
                        ev.append(.note("\(u.kind.emoji) teeters at the vat"))
                        damage(id, 2, .collision, &s, &ev)
                        break
                    }
                    fallInVat(id, from: u.pos, into: next, &s, &ev)
                    return
                }
                s.units[i].pos = next
                moved = true
                enterTile(i, &s, &ev)
                if s[next].surface == .ice && slides(u, s) {
                    slide(id, dir, &s, &ev)
                    break
                }
            }
            // A fully blocked push is not a "landing" (rule 8) — no contact.
            if moved, let i = s.index(of: id) {
                landContact(i, &s, &ev)
            }
            if let i = s.index(of: id) {
                ev.append(.moved(id, s.units[i].pos))
            }
        }

        /// Rule 8 landing: the surface's contact effect applies where a
        /// pushed/pulled unit comes to rest (water is handled per-step).
        static func landContact(_ i: Int, _ s: inout BoardState, _ ev: inout [Event]) {
            let u = s.units[i]
            if u.kind.flying { return }
            switch s[u.pos].surface {
            case .oil:
                if !u.oiled {
                    s.units[i].oiled = true
                    ev.append(.status(u.pos, "\(u.kind.emoji) oiled"))
                }
            case .fire:
                fireContact(i, &s, &ev)
            default:
                break
            }
        }

        static func pushDirection(from a: Pt, to b: Pt) -> Pt {
            let dx = b.x - a.x
            let dy = b.y - a.y
            if abs(dx) >= abs(dy) && dx != 0 { return Pt(x: dx > 0 ? 1 : -1, y: 0) }
            if dy != 0 { return Pt(x: 0, y: dy > 0 ? 1 : -1) }
            return Pt(x: 1, y: 0)
        }

        static func aligned(_ a: Pt, _ b: Pt) -> Bool { a.x == b.x || a.y == b.y }

        static func clearPath(_ a: Pt, _ b: Pt, _ s: BoardState) -> Bool {
            guard aligned(a, b), a != b else { return false }
            let d = pushDirection(from: a, to: b)
            var p = a + d
            while p != b {
                if s.unit(at: p) != nil { return false }
                p = p + d
            }
            return true
        }

        static func steamBlocks(_ a: Pt, _ b: Pt, _ s: BoardState) -> Bool {
            guard aligned(a, b), a != b else { return false }
            let d = pushDirection(from: a, to: b)
            var p = a + d
            while p != b {
                if s[p].surface == .steam { return true }
                p = p + d
            }
            return false
        }

        // MARK: Hero actions

        static func heroMove(_ steps: [Pt], _ s: inout BoardState, _ ev: inout [Event]) {
            guard s.ap >= 1, let h = s.hero else { return }
            s.ap -= 1
            s.spearRetreatTo = nil
            for d in steps {
                if !walkStep(h.id, d, &s, &ev) { break }
            }
            if let i = s.index(of: h.id) {
                // Walking onto oil does NOT oil you — only rule-8 landings
                // and Oilslick apply Oiled, same as for enemies.
                ev.append(.moved(h.id, s.units[i].pos))
            }
        }

        static func physHit(_ id: Int, _ base: Int, _ s: inout BoardState, _ ev: inout [Event]) {
            var amount = base
            if s.has(.sharpProof), let u = s.units.first(where: { $0.id == id }), u.hasStatus {
                amount += 1
            }
            damage(id, amount, .phys, &s, &ev)
        }

        static func weaponStrike(at target: Pt, _ s: inout BoardState, _ ev: inout [Event]) {
            guard s.ap >= 1, let h = s.hero else { return }
            s.ap -= 1
            s.spearRetreatTo = nil
            let dir = pushDirection(from: h.pos, to: target)
            switch s.weapon {
            case .hammer:
                if let t = s.unit(at: target) {
                    physHit(t.id, 2, &s, &ev)
                    if s.index(of: t.id) != nil { displace(t.id, dir, 1, &s, &ev) }
                } else { ev.append(.whiff("🔨")) }
            case .rapier:
                if let t = s.unit(at: target) {
                    let statused = t.hasStatus
                    physHit(t.id, statused ? 3 : 2, &s, &ev)
                    if statused {
                        s.ap += 1
                        ev.append(.note("🤺 proof holds — AP refunded"))
                    }
                } else { ev.append(.whiff("🤺")) }
            case .spear:
                var landed = false
                for k in 1...2 {
                    let p = Pt(x: h.pos.x + dir.x * k, y: h.pos.y + dir.y * k)
                    guard p.inBounds else { break }
                    if let t = s.unit(at: p) { physHit(t.id, 1, &s, &ev); landed = true }
                }
                if !landed { ev.append(.whiff("🔱")) }
                let back = Pt(x: h.pos.x - dir.x, y: h.pos.y - dir.y)
                if let hi = s.heroIndex, !s.heroDead,
                   canEnter(back, s.units[hi], s) {
                    s.spearRetreatTo = back
                }
            case .sling:
                if let t = s.unit(at: target) {
                    physHit(t.id, 1, &s, &ev)
                    if s.index(of: t.id) != nil { displace(t.id, dir, 1, &s, &ev) }
                } else { ev.append(.whiff("🪨")) }
            case .alembic:
                if let t = s.unit(at: target) {
                    physHit(t.id, 1, &s, &ev)
                    if s.mp < s.maxMP {
                        s.mp += 1
                        ev.append(.note("⚗️ +1🔮"))
                    }
                } else { ev.append(.whiff("⚗️")) }
            case .frostKnife:
                if let t = s.unit(at: target) {
                    let wasWet = t.wet
                    physHit(t.id, 1, &s, &ev)
                    if wasWet, let j = s.index(of: t.id), !s.units[j].frozen {
                        s.units[j].frozen = true
                        if s.units[j].kind.isEnemy { s.freezesThisTurn += 1 }
                        ev.append(.frozen(s.units[j].pos))
                    }
                } else { ev.append(.whiff("🔪")) }
            }
        }

        static func spearRetreat(_ s: inout BoardState, _ ev: inout [Event]) {
            guard let to = s.spearRetreatTo, let hi = s.heroIndex else { return }
            s.spearRetreatTo = nil
            let dir = pushDirection(from: s.units[hi].pos, to: to)
            guard canEnter(to, s.units[hi], s) else { return }
            s.units[hi].pos = to
            enterTile(hi, &s, &ev)
            if s[to].surface == .ice && slides(s.units[hi], s) {
                slide(s.units[hi].id, dir, &s, &ev)
            }
            if let i = s.heroIndex { ev.append(.moved(s.units[i].id, s.units[i].pos)) }
        }

        static func cast(_ spell: SpellKind, at target0: Pt, overHP: Int,
                         _ s: inout BoardState, _ ev: inout [Event]) {
            guard s.ap >= spell.ap, let h = s.hero else { return }
            s.ap -= spell.ap
            // Overchannel is priced from LIVE state at commit — 1 HP per MP
            // actually missing — so mana gained after the long-press (e.g.
            // Kindle) isn't wasted, and the price can't exceed the offer.
            let due = overHP > 0 ? min(overHP, max(0, spell.mp - s.mp)) : 0
            let mpSpent: Int
            if spell == .leyburst {
                mpSpent = s.mp
                s.mp = 0
            } else {
                mpSpent = max(0, spell.mp - due)
                s.mp = max(0, s.mp - mpSpent)
            }
            if due > 0, let hi = s.heroIndex {
                s.units[hi].hp -= due
                s.overchanneledThisRun = true
                ev.append(.note("overchannel: \(due)❤️ burned as mana"))
                if s.units[hi].hp <= 0 {
                    // The price routes through the death pipeline: Second
                    // Wind can catch it; otherwise the candle goes out.
                    kill(s.units[hi].id, by: .burn, &s, &ev)
                    if s.heroDead { return }
                }
            }
            if mpSpent > 0 && s.units.contains(where: { $0.kind == .docent }) {
                s.docentBonus += mpSpent
                // The already-telegraphed action upgrades too, so badge,
                // inspector, queue and resolution agree (tiles stay locked).
                for i in s.units.indices where s.units[i].kind == .docent {
                    guard var intent = s.units[i].intent, intent.damage > 0 else { continue }
                    intent.damage += mpSpent
                    intent.text = intent.kind == .strike
                        ? "strike for \(intent.damage)"
                        : "flood + spark the 2×2 for \(intent.damage)"
                    s.units[i].intent = intent
                }
                ev.append(.note("🗿 drinks \(mpSpent)🔮 — queue +\(mpSpent)"))
            }
            // Kill detection by identity, not count — a fungus that dies
            // and splits into sporelings still counts as a kill.
            let enemyIDsBefore = Set(s.enemies.map(\.id))

            // Mirror Cherub: spells TARGETED at it reflect back at the
            // caster; weapons, pushes, pool chains and spreads bypass it.
            var target = target0
            var reflectedFrom: Pt? = nil
            let reflectable = spell != .mirrorwax && spell != .oilslick && spell != .leyburst
            if reflectable, let t = s.unit(at: target0), t.kind == .cherub {
                ev.append(.note("🪞 reflects \(spell.name) back at you"))
                reflectedFrom = t.pos
                target = h.pos
            }

            switch spell {
            case .spark:
                if let t = s.unit(at: target) { damage(t.id, 2, .shock, &s, &ev) }
                else { ev.append(.whiff("⚡")) }
            case .candleflame:
                ignite(target, &s, &ev)
            case .gust:
                let distance = 2 + (s.has(.bellows) ? 1 : 0)
                if let from = reflectedFrom {
                    displace(h.id, pushDirection(from: from, to: h.pos), distance, &s, &ev)
                } else if let t = s.unit(at: target), t.id != h.id {
                    displace(t.id, pushDirection(from: h.pos, to: target), distance, &s, &ev)
                } else if target != h.pos {
                    displace(h.id, pushDirection(from: h.pos, to: target), distance, &s, &ev)
                }
            case .undertow:
                let distance = 2 + (s.has(.bellows) ? 1 : 0)
                if let from = reflectedFrom {
                    displace(h.id, pushDirection(from: h.pos, to: from), distance, &s, &ev)
                } else if let t = s.unit(at: target), t.id != h.id {
                    displace(t.id, pushDirection(from: target, to: h.pos), distance, &s, &ev)
                }
            case .hoarfrost:
                if let t = s.unit(at: target) { damage(t.id, 1, .frost, &s, &ev) }
                else if s[target].surface == .water {
                    s[target].surface = .ice
                    ev.append(.surface(target, .ice))
                }
            case .oilslick:
                let d = pushDirection(from: h.pos, to: target)
                for k in 1...3 {
                    let p = Pt(x: h.pos.x + d.x * k, y: h.pos.y + d.y * k)
                    guard p.inBounds else { break }
                    if s[p].surface == .none || s[p].surface == .steam || s[p].surface == .ice {
                        s[p].surface = .oil
                        ev.append(.surface(p, .oil))
                    }
                    if let ui = s.unitIndex(at: p), !s.units[ui].kind.flying, !s.units[ui].oiled {
                        s.units[ui].oiled = true
                        ev.append(.status(p, "\(s.units[ui].kind.emoji) oiled"))
                    }
                }
            case .fulminate:
                if let t = s.unit(at: target) {
                    let tid = t.id
                    let tpos = t.pos
                    damage(tid, 3, .shock, &s, &ev)
                    if s.index(of: tid) == nil {
                        let jumps = s.enemies.filter { $0.pos.dist(tpos) <= 2 }
                        if let jump = jumps.min(by: { ($0.pos.dist(tpos), $0.id) < ($1.pos.dist(tpos), $1.id) }) {
                            ev.append(.note("🌩️ arcs to \(jump.kind.emoji)"))
                            damage(jump.id, 2, .shock, &s, &ev)
                        }
                    }
                } else { ev.append(.whiff("🌩️")) }
            case .mirrorwax:
                s.mirrorTile = target
                ev.append(.note("🪞 wax set — next hit on you redirects"))
            case .transpose:
                if let t = s.unit(at: target), t.id != h.id,
                   let hi = s.heroIndex, let ti = s.index(of: t.id) {
                    let a = s.units[hi].pos
                    s.units[hi].pos = s.units[ti].pos
                    s.units[ti].pos = a
                    ev.append(.note("🔁 positions swapped"))
                    enterTile(hi, &s, &ev)
                    landContact(hi, &s, &ev)
                    if let tj = s.index(of: t.id) {
                        enterTile(tj, &s, &ev)
                        landContact(tj, &s, &ev)
                    }
                    // Endpoint ghosts for the preview, like every other
                    // repositioning effect.
                    if let hi2 = s.heroIndex { ev.append(.moved(h.id, s.units[hi2].pos)) }
                    if let tj2 = s.index(of: t.id) { ev.append(.moved(t.id, s.units[tj2].pos)) }
                }
            case .emberWaltz:
                if let hi = s.heroIndex, s.unit(at: target) == nil, s[target].surface != .vat {
                    let from = s.units[hi].pos
                    s.units[hi].pos = target
                    enterTile(hi, &s, &ev)
                    landContact(hi, &s, &ev)
                    ev.append(.moved(h.id, target))
                    ignite(from, &s, &ev)
                }
            case .leyburst:
                let x = max(1, mpSpent + due)
                ev.append(.note("💥 leyburst X=\(x)"))
                let victims = s.units
                    .filter { $0.pos.dist(h.pos) <= x && $0.kind != .remnant }
                    .map(\.id)
                for v in victims { damage(v, x, .shock, &s, &ev) }
            }

            if due > 0, s.has(.refundCoil),
               enemyIDsBefore.contains(where: { s.index(of: $0) == nil }),
               let hi = s.heroIndex {
                s.units[hi].hp = min(s.units[hi].maxHP, s.units[hi].hp + due)
                ev.append(.note("Refund Coil — \(due)❤️ returned"))
            }
        }

        // MARK: Enemy phase

        static func enemyOrder(_ s: BoardState) -> [Int] {
            s.enemies.map(\.id).sorted()
        }

        static func enemyAct(_ id: Int, _ s: inout BoardState, _ ev: inout [Event]) {
            guard let i0 = s.index(of: id) else { return }
            if s.units[i0].frozen {
                s.units[i0].frozen = false
                s.units[i0].intent = nil
                ev.append(.status(s.units[i0].pos, "\(s.units[i0].kind.emoji) thaws, losing its turn"))
                return
            }
            if s.units[i0].flopping {
                s.units[i0].intent = nil
                ev.append(.status(s.units[i0].pos, "🪱 flops helplessly"))
                return
            }
            if let intent = s.units[i0].intent {
                s.units[i0].intent = nil
                resolveIntent(intent, byUnit: id, &s, &ev)
            }
            guard !s.heroDead, s.index(of: id) != nil else { return }
            enemyMove(id, &s, &ev)
            guard let i2 = s.index(of: id) else { return }
            s.units[i2].phaseCounter += 1
            let intent = makeIntent(for: s.units[i2], s)
            s.units[i2].intent = intent
        }

        /// Enemy hits on the hero route through Mirrorwax first.
        /// Pool-wide intents pass chainPools: false — they already
        /// enumerate their area, so per-tile hits must not re-conduct.
        static func enemyHit(_ targetId: Int, _ amount: Int, _ type: DmgType,
                             _ s: inout BoardState, _ ev: inout [Event], chainPools: Bool = true) {
            if let h = s.hero, h.id == targetId, let mirror = s.mirrorTile {
                s.mirrorTile = nil
                ev.append(.note("🪞 mirrorwax redirects the blow"))
                if let t = s.unit(at: mirror) { damage(t.id, amount, type, &s, &ev, chainPools: chainPools) }
                return
            }
            damage(targetId, amount, type, &s, &ev, chainPools: chainPools)
        }

        static func resolveIntent(_ intent: Intent, byUnit id: Int,
                                  _ s: inout BoardState, _ ev: inout [Event]) {
            let attacker = s.units.first { $0.id == id }
            switch intent.kind {
            case .strike:
                var landed = false
                for p in intent.tiles {
                    guard let t = s.unit(at: p) else { continue }
                    landed = true
                    enemyHit(t.id, intent.damage, .phys, &s, &ev)
                    if attacker?.kind == .fungus, let j = s.index(of: t.id), !s.units[j].oiled {
                        s.units[j].oiled = true
                        ev.append(.status(p, "\(s.units[j].kind.emoji) oiled"))
                    }
                }
                if !landed { ev.append(.whiff(attacker?.kind.emoji ?? "?")) }
            case .poolZap:
                ev.append(.note("🪱 discharges into its pool"))
                for p in intent.tiles {
                    if let t = s.unit(at: p) {
                        enemyHit(t.id, intent.damage, .shock, &s, &ev, chainPools: false)
                    }
                }
            case .drag:
                guard let hi = s.heroIndex, intent.tiles.contains(s.units[hi].pos) else {
                    ev.append(.whiff("🦀"))
                    return
                }
                let heroPos = s.units[hi].pos
                let vats = allTiles.filter { s[$0].surface == .vat }
                let goal = vats.min { ($0.dist(heroPos), $0.idx) < ($1.dist(heroPos), $1.idx) }
                    ?? attacker?.pos ?? heroPos
                ev.append(.note("🦀 drags you"))
                displace(s.units[hi].id, pushDirection(from: heroPos, to: goal), 2, &s, &ev)
            case .flood:
                for p in intent.tiles where s[p].surface != .vat {
                    s[p].surface = .water
                    s[p].steamTicks = 0
                    ev.append(.surface(p, .water))
                    if let ui = s.unitIndex(at: p) { enterTile(ui, &s, &ev) }
                }
            case .sparkTiles:
                if intent.floodFirst {
                    for p in intent.tiles where s[p].surface != .vat {
                        s[p].surface = .water
                        ev.append(.surface(p, .water))
                        if let ui = s.unitIndex(at: p) { enterTile(ui, &s, &ev) }
                    }
                }
                for p in intent.tiles {
                    if let t = s.unit(at: p) {
                        enemyHit(t.id, intent.damage, .shock, &s, &ev, chainPools: false)
                    }
                }
            case .igniteTiles:
                for p in intent.tiles { ignite(p, &s, &ev) }
                for p in intent.summonAlso where s.unit(at: p) == nil && s[p].surface != .vat {
                    spawnEnemy(.rat, at: p, &s, &ev)
                }
            case .summonRats:
                for p in intent.tiles where s.unit(at: p) == nil && s[p].surface != .vat {
                    spawnEnemy(.rat, at: p, &s, &ev)
                }
            }
        }

        static func spawnEnemy(_ kind: UnitKind, at p: Pt, _ s: inout BoardState, _ ev: inout [Event]) {
            let hp = kind.baseHP + (s.depth - 1) / 12
            s.units.append(Unit(id: s.nextId, kind: kind, pos: p, hp: hp, maxHP: hp))
            s.nextId += 1
            ev.append(.note("\(kind.emoji) emerges"))
        }

        /// Deterministic greedy re-path: fixed direction order, first strict
        /// improvement, stop at desired range. No randomness, ever.
        static func enemyMove(_ id: Int, _ s: inout BoardState, _ ev: inout [Event]) {
            guard let i = s.index(of: id), let hero = s.hero else { return }
            let kind = s.units[i].kind
            let desired = desiredRange(kind)
            let startPos = s.units[i].pos
            var steps = kind.moveRange
            while steps > 0 {
                steps -= 1
                guard let ci = s.index(of: id) else { return }
                let cur = s.units[ci].pos
                if cur.dist(hero.pos) <= desired { break }
                var best: Pt? = nil
                var bestDist = cur.dist(hero.pos)
                for d in Pt.dirs {
                    let n = cur + d
                    guard canEnter(n, s.units[ci], s), s[n].surface != .fire else { continue }
                    if n.dist(hero.pos) < bestDist {
                        bestDist = n.dist(hero.pos)
                        best = d
                    }
                }
                guard let d = best else { break }
                let exited = cur
                let walked = walkStep(id, d, &s, &ev)
                if kind == .queen && s[exited].surface == .none {
                    s[exited].surface = .oil
                    ev.append(.surface(exited, .oil))
                }
                if !walked { break }
            }
            if let ci = s.index(of: id), s.units[ci].pos != startPos {
                ev.append(.moved(id, s.units[ci].pos))
            }
        }

        static func desiredRange(_ kind: UnitKind) -> Int {
            switch kind {
            case .cherub, .regret, .docent: return 2
            default: return 1
            }
        }

        /// Telegraphs. Tiles chosen here are LOCKED — resolution never
        /// re-aims. Pure function of the current state.
        static func makeIntent(for u: Unit, _ s: BoardState) -> Intent? {
            guard let hero = s.hero else { return nil }
            switch u.kind {
            case .rat, .sporeling:
                guard u.pos.dist(hero.pos) == 1 else { return nil }
                return Intent(kind: .strike, tiles: [hero.pos], damage: 1, text: "bite for 1")
            case .golem:
                guard u.pos.dist(hero.pos) == 1 else { return nil }
                return Intent(kind: .strike, tiles: [hero.pos], damage: 2, text: "slam for 2")
            case .cherub:
                guard u.pos.dist(hero.pos) <= 2, !steamBlocks(u.pos, hero.pos, s) else { return nil }
                return Intent(kind: .strike, tiles: [hero.pos], damage: 1, text: "beam for 1")
            case .eel:
                let pool = floodFillWater(from: u.pos, s)
                guard !pool.isEmpty else { return nil }
                return Intent(kind: .poolZap, tiles: pool.sorted { $0.idx < $1.idx }, damage: 2,
                              text: "zap its pool for 2")
            case .fungus:
                var tiles: [Pt] = []
                for d in Pt.dirs {
                    for k in 1...2 {
                        let p = Pt(x: u.pos.x + d.x * k, y: u.pos.y + d.y * k)
                        if p.inBounds { tiles.append(p) }
                    }
                }
                return Intent(kind: .strike, tiles: tiles, damage: 1, text: "spit a cross: 1 + Oiled")
            case .crab:
                guard u.pos.dist(hero.pos) <= 2 else { return nil }
                return Intent(kind: .drag, tiles: [hero.pos], damage: 0, text: "drag you 2 toward a vat")
            case .regret:
                if u.phaseCounter % 2 == 0 {
                    let corner = Pt(x: min(3, max(0, hero.pos.x - 1)), y: min(3, max(0, hero.pos.y - 1)))
                    let tiles = [corner,
                                 corner + Pt(x: 1, y: 0),
                                 corner + Pt(x: 0, y: 1),
                                 corner + Pt(x: 1, y: 1)]
                    return Intent(kind: .flood, tiles: tiles, damage: 0, text: "flood the marked 2×2")
                }
                let waters = allTiles.filter { s[$0].surface == .water }
                guard !waters.isEmpty else { return nil }
                return Intent(kind: .sparkTiles, tiles: waters, damage: 2, text: "spark EVERY water tile for 2")
            case .queen:
                var tiles: [Pt] = []
                for p in [Pt(x: hero.pos.x - 1, y: hero.pos.y), Pt(x: hero.pos.x + 1, y: hero.pos.y)]
                where p.inBounds {
                    tiles.append(p)
                }
                var summon: [Pt] = []
                var text = "ignite the tiles flanking you"
                if u.phaseCounter % 3 == 2 {
                    summon = Array(allTiles
                        .filter { s.unit(at: $0) == nil && s[$0].surface != .vat && s[$0].surface != .fire }
                        .sorted { ($0.dist(u.pos), $0.idx) < ($1.dist(u.pos), $1.idx) }
                        .prefix(2))
                    text += " + summon 2 rats"
                }
                return Intent(kind: .igniteTiles, tiles: tiles, damage: 0, summonAlso: summon, text: text)
            case .docent:
                switch u.phaseCounter % 3 {
                case 0:
                    // Rule 1: steam blocks enemy ranged line-of-sight —
                    // the finale's strike respects it like the Cherub does.
                    guard !steamBlocks(u.pos, hero.pos, s) else { return nil }
                    let dmg = 3 + s.docentBonus
                    return Intent(kind: .strike, tiles: [hero.pos], damage: dmg, text: "strike for \(dmg)")
                case 1:
                    let spot = allTiles
                        .filter { s.unit(at: $0) == nil && s[$0].surface != .vat && s[$0].surface != .fire }
                        .min { ($0.dist(hero.pos), $0.idx) < ($1.dist(hero.pos), $1.idx) }
                    guard let spot else { return nil }
                    return Intent(kind: .summonRats, tiles: [spot], damage: 0, text: "summon a rat")
                default:
                    let dmg = 2 + s.docentBonus
                    let corner = Pt(x: min(3, max(0, hero.pos.x - 1)), y: min(3, max(0, hero.pos.y - 1)))
                    let tiles = [corner,
                                 corner + Pt(x: 1, y: 0),
                                 corner + Pt(x: 0, y: 1),
                                 corner + Pt(x: 1, y: 1)]
                    return Intent(kind: .sparkTiles, tiles: tiles, damage: dmg, floodFirst: true,
                                  text: "flood + spark the 2×2 for \(dmg)")
                }
            default:
                return nil
            }
        }

        // MARK: End-of-turn tick

        static func tick(_ s: inout BoardState, _ ev: inout [Event]) {
            // Rule 6: burning units take 1; golems melt while burning.
            for id in s.units.map(\.id) {
                guard let i = s.index(of: id), s.units[i].burn > 0 else { continue }
                s.units[i].burn -= 1
                if s.units[i].kind == .golem {
                    s.units[i].maxHP = max(1, s.units[i].maxHP - 1)
                    s.units[i].hp = min(s.units[i].hp, s.units[i].maxHP)
                    let p = s.units[i].pos
                    if s[p].surface == .none {
                        s[p].surface = .oil
                        ev.append(.surface(p, .oil))
                    }
                    ev.append(.note("🧈 melts — max HP down"))
                }
                damage(id, 1, .burn, &s, &ev)
            }
            // Rule 4: fire spreads to orthogonally adjacent oil (snapshot).
            let fireTiles = allTiles.filter { s[$0].surface == .fire }
            for f in fireTiles {
                for d in Pt.dirs {
                    let n = f + d
                    if n.inBounds && s[n].surface == .oil { ignite(n, &s, &ev) }
                }
            }
            // Rules 5/6: standing in fire ignites, standing in water wets.
            for id in s.units.map(\.id) {
                guard let i = s.index(of: id) else { continue }
                let u = s.units[i]
                if u.kind.flying { continue }
                switch s[u.pos].surface {
                case .fire:
                    if u.kind == .hero && s.has(.insulatedSole) { break }
                    fireContact(i, &s, &ev)
                case .water:
                    enterTile(i, &s, &ev)
                default:
                    break
                }
            }
            // Rule 1: steam dissipates at the end of the NEXT turn.
            for p in allTiles where s[p].surface == .steam {
                s[p].steamTicks -= 1
                if s[p].steamTicks <= 0 {
                    s[p].surface = .none
                    ev.append(.surface(p, .none))
                }
            }
            // Frost Gallery: untouched water freezes over.
            if biome(for: s.depth) == .frostGallery {
                for p in allTiles where s[p].surface == .water && s.unit(at: p) == nil {
                    s[p].surface = .ice
                    ev.append(.surface(p, .ice))
                }
            }
            // The Great Work: transmuters cycle water → oil → fire → water.
            for p in allTiles where s[p].isTransmuter {
                switch s[p].surface {
                case .water: s[p].surface = .oil
                case .oil: s[p].surface = .fire
                default: s[p].surface = .water
                }
                ev.append(.surface(p, s[p].surface))
                if let ui = s.unitIndex(at: p) {
                    if s[p].surface == .fire { fireContact(ui, &s, &ev) }
                    if s[p].surface == .water { enterTile(ui, &s, &ev) }
                }
            }
            // Eel pool check + crab shell reset.
            for i in s.units.indices {
                if s.units[i].kind == .eel {
                    let onPool = s[s.units[i].pos].surface == .water
                    if !onPool && !s.units[i].flopping {
                        s.units[i].flopping = true
                        s.units[i].intent = nil
                        ev.append(.status(s.units[i].pos, "🪱 flops — its pool is gone"))
                    } else if onPool && s.units[i].flopping {
                        s.units[i].flopping = false
                        ev.append(.status(s.units[i].pos, "🪱 slips back into the water"))
                    }
                }
                if s.units[i].kind == .crab { s.units[i].shellActive = true }
            }
        }

        static func beginPlayerTurn(_ s: inout BoardState, _ ev: inout [Event]) {
            s.turn += 1
            s.ap = 3
            s.mp = min(s.maxMP, s.mp + 1)
            s.kindleUsed = false
            s.mirrorTile = nil
            s.spearRetreatTo = nil
            if let hi = s.heroIndex, s.units[hi].frozen {
                s.units[hi].frozen = false
                s.ap = 0
                ev.append(.note("you thaw — no AP this turn"))
            }
            // Echo of the Fallen: the remnant strikes the nearest enemy
            // with the dead keeper's weapon (base damage, no statuses).
            if let rem = s.units.first(where: { $0.kind == .remnant }),
               let weapon = s.remnantWeapon {
                let target = s.enemies.min {
                    ($0.pos.dist(rem.pos), $0.id) < ($1.pos.dist(rem.pos), $1.id)
                }
                if let target {
                    ev.append(.note("🫠 the remnant strikes \(target.kind.emoji)"))
                    damage(target.id, weapon.baseDamage, .phys, &s, &ev)
                }
            }
            // Fresh player phase: feat counters reset AFTER the dawn strike
            // so only the player's own cascades count toward feats.
            s.killsThisTurn = 0
            s.freezesThisTurn = 0
        }

        // MARK: Floor generation (all RNG confined here, seeded)

        static func biome(for depth: Int) -> Biome {
            switch cycleDepth(depth) {
            case 1...3: return .cisterns
            case 4...6: return .renderingVats
            case 7...9: return .frostGallery
            default: return .greatWork
            }
        }

        /// Depth 13+ is endless: biomes cycle, +1 enemy HP per full cycle.
        static func cycleDepth(_ depth: Int) -> Int { ((depth - 1) % 12) + 1 }

        static let heroSpawn = Pt(x: 2, y: 4)

        static func buildFloor(_ s: inout BoardState, depth: Int) {
            var rng = SplitMix64(seed: s.runSeed ^ (UInt64(depth) &* 0x9E3779B97F4A7C15))
            s.depth = depth
            s.turn = 0          // the floor-entry beginPlayerTurn lands on 1
            s.tiles = Array(repeating: Tile(), count: 25)
            s.mirrorTile = nil
            s.spearRetreatTo = nil
            s.remnantWeapon = nil
            s.docentBonus = 0   // the counter scopes to a single Docent fight
            let keptHero = s.hero
            s.units.removeAll()

            switch biome(for: depth) {
            case .cisterns:
                let pools = rng.int(2..<5)
                for _ in 0..<pools { blob(.water, size: rng.int(3..<7), &s, &rng) }
            case .renderingVats:
                for _ in 0..<rng.int(1..<3) { line(.oil, &s, &rng) }
                for _ in 0..<rng.int(1..<4) {
                    let p = Pt(x: rng.int(0..<5), y: rng.int(0..<4))
                    if p.dist(heroSpawn) > 1 && s[p].surface == .none { s[p].surface = .vat }
                }
            case .frostGallery:
                for _ in 0..<rng.int(2..<4) { blob(.ice, size: rng.int(3..<5), &s, &rng) }
                blob(.water, size: rng.int(3..<6), &s, &rng)
            case .greatWork:
                var placed = 0
                while placed < 2 {
                    let p = Pt(x: rng.int(0..<5), y: rng.int(0..<4))
                    if p != heroSpawn && !s[p].isTransmuter {
                        s[p].isTransmuter = true
                        s[p].surface = .water
                        placed += 1
                    }
                }
                blob(.water, size: 3, &s, &rng)
                line(.oil, &s, &rng)
            }
            s[heroSpawn].surface = .none
            s[heroSpawn].isTransmuter = false

            if var h = keptHero {
                // A fresh floor: statuses don't follow you down the stairs.
                h.pos = heroSpawn
                h.wet = false
                h.burn = 0
                h.frozen = false
                h.oiled = false
                s.units.append(h)
            }

            for kind in roster(for: cycleDepth(depth)) {
                let candidates = allTiles.filter { p in
                    guard s.unit(at: p) == nil, p.dist(heroSpawn) >= 2 else { return false }
                    if kind == .eel { return s[p].surface == .water }
                    if kind.flying { return true }
                    return s[p].surface != .vat && s[p].surface != .fire
                }
                guard !candidates.isEmpty else { continue }
                let sorted = candidates.sorted { $0.idx < $1.idx }
                let p = sorted[rng.int(0..<sorted.count)]
                let hp = kind.baseHP + (depth - 1) / 12
                s.units.append(Unit(id: s.nextId, kind: kind, pos: p, hp: hp, maxHP: hp))
                s.nextId += 1
            }

            // Telegraph immediately so turn 1 is fully readable.
            for idx in s.units.indices where s.units[idx].kind.isEnemy {
                let intent = makeIntent(for: s.units[idx], s)
                s.units[idx].intent = intent
            }
        }

        static func roster(for cycleDepth: Int) -> [UnitKind] {
            switch cycleDepth {
            case 1: return [.rat, .rat]
            case 2: return [.rat, .rat, .eel]
            case 3: return [.rat, .eel, .cherub]
            case 4: return [.golem, .rat, .fungus]
            case 5: return [.golem, .fungus, .rat, .rat]
            case 6: return [.regret, .rat, .fungus]
            case 7: return [.crab, .cherub, .rat]
            case 8: return [.crab, .golem, .cherub]
            case 9: return [.queen]
            case 10: return [.golem, .crab, .rat, .cherub]
            case 11: return [.golem, .fungus, .crab, .eel]
            default: return [.docent, .rat]
            }
        }

        static func blob(_ surface: Surface, size: Int, _ s: inout BoardState, _ rng: inout SplitMix64) {
            var p = Pt(x: rng.int(0..<5), y: rng.int(0..<5))
            for _ in 0..<size {
                if s[p].surface == .none && p != heroSpawn { s[p].surface = surface }
                let n = p + Pt.dirs[rng.int(0..<4)]
                if n.inBounds { p = n }
            }
        }

        static func line(_ surface: Surface, _ s: inout BoardState, _ rng: inout SplitMix64) {
            let horizontal = rng.int(0..<2) == 0
            let fixed = rng.int(0..<5)
            let start = rng.int(0..<3)
            for k in start..<(start + 3) {
                let p = horizontal ? Pt(x: k, y: fixed) : Pt(x: fixed, y: k)
                if s[p].surface == .none && p != heroSpawn { s[p].surface = surface }
            }
        }
    }

    // MARK: - Persistence

    struct RunSave: Codable {
        var board: BoardState
        var stage: String
        var rewardPicksLeft: Int
        var active: Bool
        var setRecordThisRun: Bool? = nil
    }

    struct Meta: Codable {
        var feats: [String] = []
        var bequests: [String] = []
        var lastDeathDepth: Int? = nil
        var lastDeathWeapon: String? = nil
        var runCount: Int = 0
        var trialNumber: Int = 4101
    }

    private static let runKey = "arcade.athanor.run"
    private static let metaKey = "arcade.athanor.meta"

    // MARK: - View state

    enum Stage: Equatable {
        case boot, runStart, player, enemyAnim, reward, altar, altarDiscard(SpellKind),
             fountain, descend, bequest, dead
    }

    enum InputMode: Equatable { case idle, target, confirm }

    enum TargetKind: Equatable {
        case move
        case weapon
        case spell(SpellKind, Int)   // spell, overchannel HP
    }

    @State private var board = BoardState()
    @State private var meta = Meta()
    @State private var stage: Stage = .boot
    @State private var mode: InputMode = .idle
    @State private var targetKind: TargetKind? = nil
    @State private var targetTiles: Set<Pt> = []
    @State private var moveOptions: [Pt: [Pt]] = [:]
    @State private var pending: Action? = nil
    @State private var previewEvents: [Event] = []
    @State private var previewBoard: BoardState? = nil
    @State private var undoStack: [BoardState] = []
    @State private var inspector = "Tap any tile or unit — every number is visible."
    @State private var docentLine = ""
    @State private var projection = ""
    @State private var phaseGen = 0
    @State private var animActing: Int? = nil
    @State private var rewardOptions: [PrecipitateKind] = []
    @State private var rewardPicksLeft = 0
    @State private var altarOptions: [SpellKind] = []
    @State private var chosenWeapon: WeaponKind = .hammer
    @State private var chosenBequest: SpellKind? = nil
    /// Snapshot taken just before the enemy phase runs. Any save made while
    /// stage == .enemyAnim persists THIS board — the one the deterministic
    /// "enemy" replay in loadEverything is correct against — never the
    /// half-resolved live board.
    @State private var prePhaseBoard: BoardState? = nil
    @State private var overchannelQuipShown = false
    @State private var isNewRecord = false
    @State private var epitaph = ""
    @State private var didLoad = false
    @Environment(\.scenePhase) private var scenePhase

    private var heroHP: Int { board.hero?.hp ?? 0 }
    private var heroMaxHP: Int { board.hero?.maxHP ?? 10 }
    private var biome: Biome { Engine.biome(for: board.depth) }

    // MARK: - Body

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "athanor")!,
                   onRestart: { abandonRun() },
                   confirmRestart: true) {
            VStack(spacing: 6) {
                statRow
                    .padding(.horizontal, 12)
                Text(docentLine.isEmpty ? " " : docentLine)
                    .font(.caption.italic())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                boardView
                    .padding(.horizontal, 12)
                inspectorStrip
                    .padding(.horizontal, 12)
                Spacer(minLength: 0)
                actionArea
            }
            .padding(.top, 2)
            .background(
                LinearGradient(colors: [biome.tint.opacity(0.10), Color.clear],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay { overlayView }
            .onAppear {
                if !didLoad {
                    didLoad = true
                    loadEverything()
                }
            }
            .onDisappear { saveRun() }
            .onChange(of: scenePhase) { _, p in
                if p == .background || p == .inactive { saveRun() }
            }
        }
    }

    // MARK: - Stat row

    private var statRow: some View {
        HStack(spacing: 8) {
            StatPill(label: "HP", value: "❤️\(heroHP)/\(heroMaxHP)", tint: .red)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Health \(heroHP) of \(heroMaxHP)")
            StatPill(label: "Mana", value: "🔮\(board.mp)/\(board.maxMP)", tint: .purple)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Mana \(board.mp) of \(board.maxMP)")
            StatPill(label: "AP", value: apDots, tint: .green)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Action points \(board.ap) of 3")
            StatPill(label: "Depth", value: depthText, tint: biome.tint)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Depth \(board.depth)")
        }
    }

    private var apDots: String {
        String(repeating: "●", count: max(0, board.ap))
            + String(repeating: "○", count: max(0, 3 - board.ap))
    }

    private var depthText: String {
        if let best = GameScores.shared.best(for: "athanor"), best > 0 {
            return "🌀\(board.depth) · ★\(best)"
        }
        return "🌀\(board.depth)"
    }

    // MARK: - Board

    private var boardView: some View {
        GeometryReader { geo in
            let size = (min(geo.size.width, geo.size.height) - 16) / 5
            let ghost = ghostInfo
            let telegraphs = telegraphMap
            VStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { y in
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { x in
                            tileView(Pt(x: x, y: y), size: size, ghost: ghost, telegraphs: telegraphs)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private struct GhostInfo {
        var dmg: [Pt: Int] = [:]
        var skull: Set<Pt> = []
        var ghosts: [Pt: (id: Int, emoji: String)] = [:]
        var surfaces: [Pt: Surface] = [:]
    }

    private var ghostInfo: GhostInfo {
        var g = GhostInfo()
        guard mode == .confirm, let pb = previewBoard else { return g }
        for e in previewEvents {
            switch e {
            case .hit(let p, let n, _): g.dmg[p, default: 0] += n
            case .die(let p, _, _): g.skull.insert(p)
            case .moved(let id, let to):
                if let u = pb.units.first(where: { $0.id == id }) ?? board.units.first(where: { $0.id == id }) {
                    g.ghosts[to] = (id, u.kind.emoji)
                }
            case .surface(let p, let sf): g.surfaces[p] = sf
            default: break
            }
        }
        return g
    }

    private struct TelegraphInfo {
        var dmg: [Pt: Int] = [:]        // locked tiles → summed incoming damage
        var frozen: Set<Pt> = []        // tiles locked by a FROZEN attacker
    }

    /// Locked telegraph tiles → summed incoming damage (0 = non-damage mark).
    /// A frozen unit's locked attack is suspended (rule 7: telegraph shows
    /// ❄️) — it springs back red if the freeze is shattered.
    private var telegraphMap: TelegraphInfo {
        var out = TelegraphInfo()
        for u in board.units {
            guard let intent = u.intent else { continue }
            if u.frozen {
                out.frozen.formUnion(intent.tiles)
                continue
            }
            for p in intent.tiles { out.dmg[p, default: 0] += intent.damage }
            for p in intent.summonAlso where out.dmg[p] == nil { out.dmg[p] = 0 }
        }
        return out
    }

    private func tileView(_ p: Pt, size: CGFloat, ghost: GhostInfo, telegraphs: TelegraphInfo) -> some View {
        let tile = board[p]
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(surfaceColor(tile))
            surfaceMarkView(tile, size: size)
            if let dmg = telegraphs.dmg[p] {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.red.opacity(0.85), lineWidth: 2)
                telegraphBadge(dmg, size: size)
            } else if telegraphs.frozen.contains(p) {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.cyan.opacity(0.85), lineWidth: 2)
                frozenBadge(size: size)
            }
            if let u = board.unit(at: p) {
                unitView(u, size: size)
            }
            selectionLayer(p, size: size)
            ghostLayer(p, size: size, ghost: ghost)
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture { tapTile(p) }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(tileA11yLabel(p, telegraphs: telegraphs))
        .accessibilityAction { tapTile(p) }
    }

    private func tileA11yLabel(_ p: Pt, telegraphs: TelegraphInfo) -> String {
        var parts: [String] = ["tile \(p.x), \(p.y)"]
        let t = board[p]
        if t.surface != .none { parts.append(String(describing: t.surface)) }
        if t.isTransmuter { parts.append("transmuter") }
        if let u = board.unit(at: p) {
            var d = "\(u.kind.name), HP \(u.hp) of \(u.maxHP)"
            if u.wet { d += ", wet" }
            if u.burn > 0 { d += ", burning" }
            if u.frozen { d += ", frozen" }
            if u.oiled { d += ", oiled" }
            parts.append(d)
            if let intent = u.intent, !u.frozen { parts.append("intends \(intent.text)") }
        }
        if let dmg = telegraphs.dmg[p], dmg > 0 { parts.append("telegraphed \(dmg) damage") }
        if telegraphs.frozen.contains(p) { parts.append("suspended attack — attacker frozen") }
        if mode != .idle {
            if targetKind == .move, moveOptions[p] != nil { parts.append("move target") }
            else if targetKind != .move, targetTiles.contains(p) { parts.append("valid target") }
        }
        return parts.joined(separator: ", ")
    }

    private func surfaceColor(_ tile: Tile) -> Color {
        switch tile.surface {
        case .none: return biome.tint.opacity(0.12)
        case .water: return Color.blue.opacity(0.45)
        case .oil: return Color.brown.opacity(0.55)
        case .fire: return Color.orange.opacity(0.60)
        case .ice: return Color.cyan.opacity(0.45)
        case .steam: return Color.gray.opacity(0.50)
        case .vat: return Color.black.opacity(0.78)
        }
    }

    @ViewBuilder
    private func surfaceMarkView(_ tile: Tile, size: CGFloat) -> some View {
        VStack {
            HStack {
                if tile.isTransmuter {
                    Text("✨").font(.system(size: size * 0.2))
                }
                Spacer()
            }
            Spacer()
            HStack {
                if !tile.surface.mark.isEmpty {
                    Text(tile.surface.mark)
                        .font(.system(size: size * 0.22))
                        .opacity(0.75)
                }
                Spacer()
            }
        }
        .padding(3)
    }

    private func telegraphBadge(_ dmg: Int, size: CGFloat) -> some View {
        VStack {
            HStack {
                Spacer()
                Text(dmg > 0 ? "\(dmg)" : "!")
                    .font(.system(size: size * 0.22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.red.opacity(0.9), in: Capsule())
            }
            Spacer()
        }
        .padding(2)
    }

    /// The attacker is frozen: its locked tiles show ❄️, not damage.
    private func frozenBadge(size: CGFloat) -> some View {
        VStack {
            HStack {
                Spacer()
                Text("❄️")
                    .font(.system(size: size * 0.2))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.cyan.opacity(0.65), in: Capsule())
            }
            Spacer()
        }
        .padding(2)
    }

    private func unitView(_ u: Unit, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            if !u.statusLine.isEmpty || u.kind.isEnemy {
                HStack(spacing: 0) {
                    Text(u.statusLine).font(.system(size: size * 0.17))
                    if u.kind.isEnemy, let order = initiativeIndex(of: u) {
                        Text(initiativeBadge(order))
                            .font(.system(size: size * 0.19, weight: .bold))
                            .foregroundStyle(.red)
                    }
                }
            }
            Text(u.kind.emoji)
                .font(.system(size: size * 0.42))
                .opacity(u.frozen ? 0.6 : 1)
                .scaleEffect(animActing == u.id ? 1.25 : 1)
            Text("\(u.hp)")
                .font(.system(size: size * 0.17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .background(hpColor(u), in: Capsule())
        }
        .animation(.easeInOut(duration: 0.2), value: animActing)
    }

    private func hpColor(_ u: Unit) -> Color {
        if u.kind == .hero { return .green }
        if u.kind == .remnant { return .teal }
        return u.hp <= 1 ? .red.opacity(0.8) : .gray.opacity(0.8)
    }

    private func initiativeIndex(of u: Unit) -> Int? {
        Engine.enemyOrder(board).firstIndex(of: u.id)
    }

    /// Bijective with the id-sorted resolution order — circled digits run
    /// contiguously ①–⑳; text fallback beyond (5×5 board caps enemies at 24).
    private func initiativeBadge(_ order: Int) -> String {
        if order < 20, let sc = UnicodeScalar(UInt32(0x2460 + order)) { return String(sc) }
        return "(\(order + 1))"
    }

    @ViewBuilder
    private func selectionLayer(_ p: Pt, size: CGFloat) -> some View {
        if mode == .target || mode == .confirm {
            if targetKind == .move, moveOptions[p] != nil {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: size * 0.16, height: size * 0.16)
            } else if targetKind != .move, targetTiles.contains(p) {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.yellow.opacity(0.9), lineWidth: 2.5)
            }
        }
    }

    @ViewBuilder
    private func ghostLayer(_ p: Pt, size: CGFloat, ghost: GhostInfo) -> some View {
        if mode == .confirm {
            ZStack {
                if let sf = ghost.surfaces[p], !sf.mark.isEmpty {
                    Text(sf.mark).font(.system(size: size * 0.3)).opacity(0.5)
                        .offset(x: -size * 0.25, y: size * 0.25)
                }
                // Render unless the tile is occupied by the SAME unit —
                // swaps (Transpose) ghost onto each other's tiles.
                if let g0 = ghost.ghosts[p], board.unit(at: p)?.id != g0.id {
                    Text(g0.emoji).font(.system(size: size * 0.42)).opacity(0.35)
                }
                if let dmg = ghost.dmg[p] {
                    Text("-\(dmg)")
                        .font(.system(size: size * 0.3, weight: .heavy, design: .rounded))
                        .foregroundStyle(.orange)
                        .shadow(color: .black.opacity(0.6), radius: 1)
                        .offset(y: -size * 0.28)
                }
                if ghost.skull.contains(p) {
                    Text("💀").font(.system(size: size * 0.34))
                        .offset(x: size * 0.25, y: -size * 0.25)
                }
            }
        }
    }

    // MARK: - Inspector

    private var inspectorStrip: some View {
        Text(inspector)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(3)
            .padding(10)
            .frame(minHeight: 56, alignment: .topLeading)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func inspect(_ p: Pt) {
        if let u = board.unit(at: p) {
            var line = "\(u.kind.emoji) \(u.kind.name) · HP \(u.hp)/\(u.maxHP)"
            if !u.statusLine.isEmpty { line += " · \(u.statusLine)" }
            if u.kind.isEnemy, let order = initiativeIndex(of: u) {
                line += " · acts \(initiativeBadge(order))"
            }
            if u.frozen {
                line += "\nintends: ❄️ frozen — skips its next action"
            } else if u.kind == .eel && u.flopping {
                line += "\nintends: flopping — skips turns, takes +1 phys"
            } else if let intent = u.intent {
                line += "\nintends: \(intent.text) (tiles locked)"
            } else if u.kind.isEnemy {
                line += "\nintends: nothing yet"
            }
            if u.kind == .docent {
                line += "\nqueue: \(docentQueueText(u)) · mana drunk: \(board.docentBonus)"
            } else if u.kind == .crab {
                // Live shell state — a cracked shell stays down this round.
                line += u.shellActive
                    ? "\nshell: first hit negated — collisions crack it"
                    : "\nshell: cracked — hits land normally until next round"
            } else {
                line += "\n\(u.kind.gimmick)"
            }
            inspector = line
        } else {
            let t = board[p]
            var line = "tile (\(p.x),\(p.y)) · \(t.surface == .none ? "bare stone" : String(describing: t.surface))"
            if t.isTransmuter { line += " · ✨ transmutes water→oil→fire each tick" }
            if t.surface == .vat { line += " — push-kill; heavy units take 2 instead" }
            if t.surface == .steam { line += " — blocks ranged sight, fades in \(t.steamTicks) tick(s)" }
            inspector = line
        }
    }

    /// Head of the queue = the currently telegraphed action, rendered from
    /// its LOCKED intent damage; future entries use the live bonus (honest
    /// best-current estimates — the counter only ever rises).
    private func docentQueueText(_ u: Unit) -> String {
        let start = u.phaseCounter % 3
        func entry(_ slot: Int, lockedDamage: Int?) -> String {
            switch slot {
            case 0: return "strike \(lockedDamage ?? 3 + board.docentBonus)"
            case 1: return "summon rat"
            default: return "flood+spark \(lockedDamage ?? 2 + board.docentBonus)"
            }
        }
        return (0..<3).map { i in
            entry((start + i) % 3, lockedDamage: i == 0 ? u.intent?.damage : nil)
        }.joined(separator: " → ")
    }

    // MARK: - Action area

    @ViewBuilder
    private var actionArea: some View {
        VStack(spacing: 8) {
            if stage == .player {
                if board.spearRetreatTo != nil {
                    retreatBar
                } else if mode == .confirm {
                    confirmBar
                } else {
                    actionBar
                }
            } else if stage == .enemyAnim {
                Text("The reagents move…")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var actionBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                weaponButton
                ForEach(board.spells, id: \.self) { spellButton($0) }
                kindleButton
            }
            HStack(spacing: 8) {
                Button {
                    GameHaptics.tap()
                    undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline)
                        .foregroundStyle(undoStack.isEmpty ? Color.secondary : .white)
                        .frame(width: 46, height: 46)
                        .background(undoStack.isEmpty ? Color.gray.opacity(0.3) : Color.indigo,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(undoStack.isEmpty)
                .accessibilityLabel("Undo last action")
                VStack(spacing: 3) {
                    Text(projection.isEmpty ? " " : projection)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    ArcadeButton(title: "End Turn", systemImage: "forward.fill", tint: .teal) {
                        endTurn()
                    }
                }
            }
        }
    }

    private var weaponButton: some View {
        let enabled = board.ap >= 1
        return actionSlot(emoji: board.weapon.emoji, caption: "1AP", enabled: enabled,
                          a11yLabel: "\(board.weapon.name), 1 action point",
                          a11yValue: enabled ? "ready" : "no AP left") {
            if enabled {
                enterTargeting(.weapon)
            } else {
                inspector = "\(board.weapon.name): no AP left this turn."
            }
        }
    }

    private func spellButton(_ spell: SpellKind) -> some View {
        let missing = max(0, spell.mp - board.mp)
        let apOK = board.ap >= spell.ap
        let canCast = apOK && missing == 0
        let canOver = apOK && missing > 0 && heroHP > missing
        // Short on MP: the button itself explains the overchannel hold.
        let caption: String
        if apOK && missing > 0 {
            caption = "need \(missing)🔮 — hold for \(missing)❤️"
        } else if spell == .leyburst {
            caption = "\(spell.ap)AP·X🔮"
        } else {
            caption = "\(spell.ap)AP·\(spell.mp)🔮"
        }
        return actionSlot(emoji: spell.emoji, caption: caption, enabled: canCast,
                          a11yLabel: "\(spell.name), \(spell.ap) action points, \(spell.mp) mana",
                          a11yValue: canCast
                            ? "ready"
                            : (apOK ? "needs \(missing) more mana — overchannel available"
                                    : "needs \(spell.ap) action points")) {
            if canCast {
                enterTargeting(.spell(spell, 0))
            } else if !apOK {
                inspector = "\(spell.name): needs \(spell.ap) AP — you have \(board.ap)."
            } else {
                inspector = "\(spell.name): need \(missing)🔮 — hold to overchannel for \(missing)❤️."
            }
        } onLongPress: {
            if canOver {
                GameHaptics.medium()
                inspector = "Overchanneling \(spell.name): \(missing)❤️ will burn as mana."
                enterTargeting(.spell(spell, missing))
            } else if missing > 0 {
                if !apOK {
                    inspector = "\(spell.name): needs \(spell.ap) AP — you have \(board.ap). Overchannel can't pay AP."
                } else {
                    inspector = "Overchannel needs \(missing + 1)❤️ to survive the price."
                }
            }
        }
    }

    private var kindleButton: some View {
        let can = !board.kindleUsed && heroHP > 1 && board.mp < board.maxMP
        return actionSlot(emoji: "🕳️", caption: "kindle", enabled: can,
                          a11yLabel: "Kindle — pay 1 health for 1 mana, once per turn") {
            if can {
                doKindle()
            } else if board.kindleUsed {
                inspector = "Kindle: already used this turn."
            } else if board.mp >= board.maxMP {
                inspector = "Kindle: mana already full."
            } else {
                inspector = "Kindle: you can't spare the wax (1❤️ → 1🔮)."
            }
        }
    }

    @ViewBuilder
    private func actionSlot(emoji: String, caption: String, enabled: Bool,
                            a11yLabel: String? = nil,
                            a11yValue: String? = nil,
                            action: @escaping () -> Void,
                            onLongPress: (() -> Void)? = nil) -> some View {
        let base = VStack(spacing: 2) {
            Text(emoji).font(.system(size: 22))
            Text(caption)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(enabled ? biome.tint.opacity(0.5) : .clear, lineWidth: 1.5))
        .opacity(enabled ? 1 : 0.45)
        .onTapGesture {
            GameHaptics.tap()
            action()
        }
        .onLongPressGesture(minimumDuration: 0.45) {
            onLongPress?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(a11yLabel ?? caption)
        .accessibilityValue(a11yValue ?? (enabled ? "ready" : "unavailable"))
        .accessibilityAction { action() }
        if let onLongPress {
            base.accessibilityAction(named: "Overchannel") { onLongPress() }
        } else {
            base
        }
    }

    private var confirmBar: some View {
        HStack(spacing: 8) {
            ArcadeButton(title: "Cancel", systemImage: "xmark", tint: .gray) {
                cancelSelection()
            }
            ArcadeButton(title: "Confirm", systemImage: "checkmark", tint: .green) {
                commitPending()
            }
        }
    }

    private var retreatBar: some View {
        HStack(spacing: 8) {
            ArcadeButton(title: "Stay", systemImage: "figure.stand", tint: .gray) {
                cancelSelection()
                board.spearRetreatTo = nil
                recomputeProjection()
                saveRun()
            }
            ArcadeButton(title: "Retreat (free)", systemImage: "arrow.uturn.down", tint: .indigo) {
                // Retreat mutates the board: any staged preview computed
                // against the pre-retreat state must be invalidated.
                cancelSelection()
                undoStack.append(board)
                let events = Engine.resolve(.spearRetreat, &board)
                afterCommit(events)
            }
        }
    }

    // MARK: - Targeting grammar
    // tap action → valid tiles glow → tap target → ghost preview →
    // Confirm, or tap elsewhere to cancel. Two decisive taps.

    private func tapTile(_ p: Pt) {
        // While the Stay/Retreat choice is pending, the board is read-only:
        // staging a preview now would commit against a state Retreat can
        // still mutate out from under it.
        guard stage == .player, board.spearRetreatTo == nil else {
            inspect(p)
            return
        }
        switch mode {
        case .idle:
            if let u = board.unit(at: p), u.kind == .hero {
                if board.ap >= 1 {
                    enterTargeting(.move)
                } else {
                    inspector = "No AP left to move."
                    inspect(p)
                }
            } else {
                inspect(p)
            }
        case .target, .confirm:
            if targetKind == .move, let steps = moveOptions[p] {
                stagePreview(.move(steps))
            } else if targetKind != .move, targetTiles.contains(p), let k = targetKind {
                stagePreview(action(for: k, at: p))
            } else {
                cancelSelection()
                inspect(p)
            }
        }
    }

    private func enterTargeting(_ kind: TargetKind) {
        cancelSelection()
        targetKind = kind
        if kind == .move {
            moveOptions = computeMoveOptions()
            targetTiles = Set(moveOptions.keys)
        } else {
            targetTiles = validTiles(for: kind)
        }
        guard !targetTiles.isEmpty else {
            inspector = noTargetsText(for: kind)
            targetKind = nil
            return
        }
        mode = .target
        inspector = instructionText(for: kind)
    }

    private func cancelSelection() {
        mode = .idle
        targetKind = nil
        targetTiles = []
        moveOptions = [:]
        pending = nil
        previewBoard = nil
        previewEvents = []
    }

    private func action(for kind: TargetKind, at p: Pt) -> Action {
        switch kind {
        case .move: return .move(moveOptions[p] ?? [])
        case .weapon: return .strike(p)
        case .spell(let sp, let over): return .cast(sp, p, overHP: over)
        }
    }

    private func stagePreview(_ a: Action) {
        var copy = board
        let events = Engine.resolve(a, &copy)
        pending = a
        previewBoard = copy
        previewEvents = events
        mode = .confirm
        inspector = "preview: " + previewSummary(events)
        GameHaptics.tap()
    }

    private func previewSummary(_ events: [Event]) -> String {
        let parts = events.compactMap(\.brief)
        if parts.isEmpty { return "no effect" }
        let shown = parts.prefix(5).joined(separator: " · ")
        return parts.count > 5 ? shown + " · +\(parts.count - 5) more" : shown
    }

    /// Commit re-runs the SAME resolve on the real state — the exact code
    /// path the preview used, so they can never disagree.
    private func commitPending() {
        guard let a = pending else { return }
        undoStack.append(board)
        let events = Engine.resolve(a, &board)
        cancelSelection()
        afterCommit(events)
    }

    private func doKindle() {
        undoStack.append(board)
        let events = Engine.resolve(.kindle, &board)
        afterCommit(events)
    }

    private func afterCommit(_ events: [Event]) {
        processEvents(events, playerCaused: true)
        recomputeProjection()
        saveRun()
        if board.heroDead {
            handleDeath()
        } else if board.enemies.isEmpty {
            floorCleared()
        }
    }

    private func undo() {
        guard let prev = undoStack.popLast() else { return }
        board = prev
        cancelSelection()
        recomputeProjection()
        saveRun()
        inspector = "Rewound. The Docent pretends not to notice."
    }

    private func processEvents(_ events: [Event], playerCaused: Bool) {
        if events.contains(where: { if case .hit = $0 { return true } else { return false } }) {
            GameHaptics.medium()
        }
        let reactions = events.filter(\.isReaction).count
        if reactions >= 3 {
            GameHaptics.heavy()
            docentLine = Quips.cascade(meta.trialNumber)
        }
        if !overchannelQuipShown,
           events.contains(where: { if case .note(let t) = $0 { return t.hasPrefix("overchannel") } else { return false } }) {
            overchannelQuipShown = true
            docentLine = Quips.firstOverchannel(meta.trialNumber)
        }
        guard playerCaused else { return }
        for e in events {
            if case .die(_, let emoji, _) = e, emoji == UnitKind.queen.emoji {
                unlockFeat("peerReview", "Feat: Peer Review — Depth-1 clears now offer 2 Precipitates.")
            }
        }
        // Counters live in BoardState, so Undo rolls them back and mid-turn
        // saves keep them — thresholds are read from the committed board.
        if board.freezesThisTurn >= 2 {
            unlockFeat("coldMethod", "Feat: Cold Method — the Frost Knife joins your starting arsenal.")
        }
        if board.killsThisTurn >= 3 {
            unlockFeat("controlledBurn", "Feat: Controlled Burn — Oilslick joins your starting-pool options.")
            if !meta.bequests.contains(SpellKind.oilslick.rawValue) {
                meta.bequests.append(SpellKind.oilslick.rawValue)
                saveMeta()
            }
        }
    }

    private func unlockFeat(_ id: String, _ line: String) {
        guard !meta.feats.contains(id) else { return }
        meta.feats.append(id)
        saveMeta()
        docentLine = line
        GameHaptics.success()
    }

    // MARK: - Valid targets

    private func computeMoveOptions() -> [Pt: [Pt]] {
        var opts: [Pt: [Pt]] = [:]
        guard let h = board.hero else { return opts }
        for d1 in Pt.dirs {
            let p1 = h.pos + d1
            guard Engine.canEnter(p1, h, board) else { continue }
            if opts[p1] == nil { opts[p1] = [d1] }
            // A slide ends the walk — no second step off ice.
            if board[p1].surface == .ice && Engine.slides(h, board) { continue }
            for d2 in Pt.dirs {
                let p2 = p1 + d2
                guard p2 != h.pos, p2.inBounds, board.unit(at: p2) == nil,
                      board[p2].surface != .vat, opts[p2] == nil else { continue }
                opts[p2] = [d1, d2]
            }
        }
        return opts
    }

    private func validTiles(for kind: TargetKind) -> Set<Pt> {
        guard let h = board.hero else { return [] }
        var out: Set<Pt> = []
        switch kind {
        case .move:
            return Set(moveOptions.keys)
        case .weapon:
            switch board.weapon {
            case .hammer, .rapier, .alembic, .frostKnife:
                for d in Pt.dirs {
                    let p = h.pos + d
                    if p.inBounds && board.unit(at: p) != nil { out.insert(p) }
                }
            case .spear:
                for d in Pt.dirs {
                    for k in 1...2 {
                        let p = Pt(x: h.pos.x + d.x * k, y: h.pos.y + d.y * k)
                        if p.inBounds { out.insert(p) }
                    }
                }
            case .sling:
                for u in board.units where u.id != h.id {
                    let dist = u.pos.dist(h.pos)
                    if dist >= 2 && dist <= 4 { out.insert(u.pos) }
                }
            }
        case .spell(let sp, _):
            switch sp {
            case .spark, .fulminate:
                for u in board.units where u.id != h.id && u.pos.dist(h.pos) <= 3 { out.insert(u.pos) }
            case .candleflame:
                for p in Engine.allTiles where p.dist(h.pos) <= 3 && board[p].surface != .vat { out.insert(p) }
            case .gust:
                for u in board.units
                where u.id != h.id && u.pos.dist(h.pos) <= 4 && Engine.aligned(u.pos, h.pos) {
                    out.insert(u.pos)
                }
                for d in Pt.dirs {
                    let p = h.pos + d
                    if p.inBounds && board.unit(at: p) == nil { out.insert(p) }
                }
            case .undertow:
                for u in board.units
                where u.id != h.id && u.pos.dist(h.pos) <= 4 && Engine.aligned(u.pos, h.pos) {
                    out.insert(u.pos)
                }
            case .hoarfrost:
                for u in board.units where u.id != h.id && u.pos.dist(h.pos) <= 3 { out.insert(u.pos) }
                for p in Engine.allTiles where p.dist(h.pos) <= 3 && board[p].surface == .water { out.insert(p) }
            case .oilslick:
                for d in Pt.dirs {
                    for k in 1...3 {
                        let p = Pt(x: h.pos.x + d.x * k, y: h.pos.y + d.y * k)
                        if p.inBounds { out.insert(p) }
                    }
                }
            case .mirrorwax:
                for d in Pt.dirs {
                    let p = h.pos + d
                    if p.inBounds { out.insert(p) }
                }
            case .transpose:
                for u in board.units
                where u.id != h.id && Engine.clearPath(h.pos, u.pos, board) {
                    out.insert(u.pos)
                }
            case .emberWaltz:
                for p in Engine.allTiles
                where p.dist(h.pos) <= 3 && p != h.pos && board.unit(at: p) == nil && board[p].surface != .vat {
                    out.insert(p)
                }
            case .leyburst:
                out.insert(h.pos)
            }
        }
        return out
    }

    private func instructionText(for kind: TargetKind) -> String {
        switch kind {
        case .move: return "Move (1 AP, up to 2 steps): tap a dot. Ice slides you."
        case .weapon: return "\(board.weapon.emoji) \(board.weapon.name): \(board.weapon.blurb) Tap a glowing tile."
        case .spell(let sp, let over):
            let overText = over > 0 ? " OVERCHANNELED: \(over)❤️." : ""
            return "\(sp.emoji) \(sp.name): \(sp.blurb)\(overText) Tap a glowing tile."
        }
    }

    private func noTargetsText(for kind: TargetKind) -> String {
        switch kind {
        case .move: return "Nowhere to move — boxed in."
        case .weapon:
            return board.weapon == .sling
                ? "Sling: nothing at range 2–4 (it can't fire point-blank)."
                : "\(board.weapon.name): nothing in reach."
        case .spell(let sp, _): return "\(sp.name): no valid target from here."
        }
    }

    // MARK: - Turn flow

    private func endTurn() {
        guard stage == .player else { return }
        cancelSelection()
        undoStack.removeAll()
        board.spearRetreatTo = nil
        prePhaseBoard = board   // every mid-phase save persists THIS board
        stage = .enemyAnim
        saveRun()   // stage "enemy": a relaunch replays the phase from here
        GameHaptics.tap()
        phaseGen += 1
        let gen = phaseGen
        Task { @MainActor in
            for id in Engine.enemyOrder(board) {
                guard gen == phaseGen, !board.heroDead else { break }
                guard board.index(of: id) != nil else { continue }
                animActing = id
                try? await Task.sleep(nanoseconds: 220_000_000)
                guard gen == phaseGen else { return }
                let events = withAnimation(.easeInOut(duration: 0.22)) {
                    Engine.resolve(.enemyAct(id), &board)
                }
                processEvents(events, playerCaused: false)
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            guard gen == phaseGen else { return }
            animActing = nil
            let tickEvents = withAnimation(.easeInOut(duration: 0.22)) {
                Engine.resolve(.tick, &board)
            }
            processEvents(tickEvents, playerCaused: false)
            if board.heroDead { handleDeath(); return }
            if board.enemies.isEmpty { floorCleared(); return }
            let dawn = withAnimation(.easeInOut(duration: 0.22)) {
                Engine.resolve(.beginPlayerTurn, &board)
            }
            processEvents(dawn, playerCaused: false)
            // Surface the thaw penalty the engine already announces —
            // otherwise the 0-AP turn reads like a bug.
            if dawn.contains(where: { if case .note(let t) = $0 { return t.hasPrefix("you thaw") } else { return false } }) {
                inspector = "❄️ you thaw — no AP this turn"
            }
            if board.heroDead { handleDeath(); return }
            if board.enemies.isEmpty { floorCleared(); return }
            prePhaseBoard = nil
            stage = .player
            recomputeProjection()
            saveRun()
        }
    }

    /// The projection line: run the ENTIRE enemy phase + tick on a copy
    /// through the same resolve pipeline. Deterministic, so it is exact —
    /// including whiffs from tiles you've already stepped out of.
    private func recomputeProjection() {
        var copy = board
        var events: [Event] = []
        for id in Engine.enemyOrder(copy) {
            guard !copy.heroDead else { break }
            events += Engine.resolve(.enemyAct(id), &copy)
        }
        if !copy.heroDead {
            events += Engine.resolve(.tick, &copy)
        }
        if copy.heroDead {
            projection = "end turn: 💀 you die — reconsider"
            return
        }
        // Mirror the commit path exactly: the dawn resolve (remnant strike,
        // thaw) runs only when the phase didn't already clear the floor.
        if !copy.enemies.isEmpty {
            events += Engine.resolve(.beginPlayerTurn, &copy)
        }
        var parts = ["❤️\(copy.hero?.hp ?? 0) predicted"]
        let deaths = events.filter { if case .die(_, _, true) = $0 { return true } else { return false } }.count
        if deaths > 0 { parts.append("\(deaths) die") }
        let burning = copy.units.filter { $0.burn > 0 && $0.kind.isEnemy }.count
        if burning > 0 { parts.append("\(burning) burning") }
        let melting = copy.units.contains { $0.kind == .golem && $0.burn > 0 }
        if melting { parts.append("golem melts") }
        if copy.enemies.isEmpty {
            parts.append("floor clears")
        } else if copy.ap == 0 {
            parts.append("❄️ thaw — 0 AP")
        }
        projection = "end turn: " + parts.joined(separator: " · ")
    }

    // MARK: - Floor clear & rewards

    private func floorCleared() {
        phaseGen += 1
        animActing = nil
        prePhaseBoard = nil
        cancelSelection()
        GameHaptics.success()
        docentLine = Quips.floorClear(meta.trialNumber)
        rewardPicksLeft = (board.depth == 1 && meta.feats.contains("peerReview")) ? 2 : 1
        rewardOptions = drawPrecipitates()
        if rewardOptions.isEmpty {
            rewardPicksLeft = 0
            advanceRewardFlow(after: .reward)
        } else {
            stage = .reward
            saveRun()
        }
    }

    /// Seeded from (runSeed, depth) so a resumed run re-offers identical
    /// options. Never duplicates owned Precipitates.
    private func drawPrecipitates() -> [PrecipitateKind] {
        var rng = SplitMix64(seed: board.runSeed ^ (UInt64(board.depth) &* 0xA24BAED4963EE407))
        var pool = PrecipitateKind.allCases.filter { !board.precipitates.contains($0) }
        // Fountains can cap MP at 5 without owning Reservoir — a card whose
        // stated effect can't apply never enters the draw.
        if board.maxMP >= 5 { pool.removeAll { $0 == .reservoir } }
        var out: [PrecipitateKind] = []
        while out.count < 3 && !pool.isEmpty {
            out.append(pool.remove(at: rng.int(0..<pool.count)))
        }
        return out
    }

    private func drawAltarSpells() -> [SpellKind] {
        var rng = SplitMix64(seed: board.runSeed ^ (UInt64(board.depth) &* 0xD6E8FEB86659FD93))
        var pool = SpellKind.findable.filter { !board.spells.contains($0) }
        var out: [SpellKind] = []
        while out.count < 3 && !pool.isEmpty {
            out.append(pool.remove(at: rng.int(0..<pool.count)))
        }
        return out
    }

    private func pickPrecipitate(_ p: PrecipitateKind) {
        GameHaptics.tap()
        board.precipitates.append(p)
        if p == .waxHeart, let hi = board.heroIndex {
            board.units[hi].maxHP += 2
            board.units[hi].hp = min(board.units[hi].maxHP, board.units[hi].hp + 2)
        }
        if p == .reservoir { board.maxMP = min(5, board.maxMP + 1) }
        rewardPicksLeft -= 1
        if rewardPicksLeft > 0 {
            rewardOptions = drawPrecipitates()
            if !rewardOptions.isEmpty { saveRun(); return }
        }
        advanceRewardFlow(after: .reward)
    }

    private func advanceRewardFlow(after prev: Stage) {
        let cd = Engine.cycleDepth(board.depth)
        if prev == .reward && [2, 4, 8, 10].contains(cd) {
            altarOptions = drawAltarSpells()
            if !altarOptions.isEmpty {
                stage = .altar
                saveRun()
                return
            }
        }
        if (prev == .reward || prev == .altar) && board.depth % 3 == 0 {
            stage = .fountain
            saveRun()
            return
        }
        stage = .descend
        saveRun()
    }

    private func takeAltarSpell(_ sp: SpellKind) {
        GameHaptics.tap()
        if board.spells.count >= 4 {
            stage = .altarDiscard(sp)
            saveRun()
        } else {
            board.spells.append(sp)
            advanceRewardFlow(after: .altar)
        }
    }

    private func discardSpell(_ old: SpellKind, incoming: SpellKind) {
        GameHaptics.tap()
        if let i = board.spells.firstIndex(of: old) { board.spells[i] = incoming }
        advanceRewardFlow(after: .altar)
    }

    private func pickFountain(heal: Bool) {
        GameHaptics.tap()
        if heal, let hi = board.heroIndex {
            board.units[hi].hp = min(board.units[hi].maxHP, board.units[hi].hp + 3)
        } else {
            board.maxMP = min(5, board.maxMP + 1)
        }
        stage = .descend
        saveRun()
    }

    private func descend() {
        let newDepth = board.depth + 1
        Engine.buildFloor(&board, depth: newDepth)
        isNewRecord = GameScores.shared.report(score: newDepth, for: "athanor")
        let cd = Engine.cycleDepth(newDepth)
        if cd == 6 || cd == 9 || cd == 12 {
            docentLine = Quips.bossIntro(cycleDepth: cd)
        } else if isNewRecord {
            docentLine = Quips.newBest(newDepth)
        } else {
            docentLine = Quips.descend(meta.trialNumber, depth: newDepth)
        }
        spawnRemnantIfNeeded()   // after the quip chain so its note survives
        // The new floor dawns through the same engine path as every turn:
        // AP 3, +1 MP regen, kindle cleared, remnant strike, counters reset.
        let dawn = Engine.resolve(.beginPlayerTurn, &board)
        processEvents(dawn, playerCaused: false)
        undoStack.removeAll()
        cancelSelection()
        stage = .player
        if board.enemies.isEmpty { floorCleared(); return }
        recomputeProjection()
        saveRun()
    }

    /// Echo of the Fallen: reaching the exact depth of the last death
    /// spawns a wax remnant armed with the dead keeper's weapon.
    private func spawnRemnantIfNeeded() {
        guard meta.lastDeathDepth == board.depth,
              let raw = meta.lastDeathWeapon,
              let weapon = WeaponKind(rawValue: raw) else { return }
        let free = Engine.allTiles.first {
            board.unit(at: $0) == nil && board[$0].surface == .none
                && $0.dist(Engine.heroSpawn) >= 1 && !board[$0].isTransmuter
        }
        guard let free else { return }
        board.remnantWeapon = weapon
        board.units.append(Unit(id: board.nextId, kind: .remnant, pos: free,
                                hp: UnitKind.remnant.baseHP, maxHP: UnitKind.remnant.baseHP))
        board.nextId += 1
        docentLine = "A remnant of the previous trial still holds its \(weapon.name.lowercased()). The Docent files this under 'sentiment'."
    }

    // MARK: - Death, bequest, new run

    private func handleDeath() {
        phaseGen += 1
        animActing = nil
        prePhaseBoard = nil
        cancelSelection()
        GameHaptics.error()
        // Floors are reported on arrival, so this call is idempotent; the
        // "record run" flag was set by the last descend() and is kept.
        GameScores.shared.report(score: board.depth, for: "athanor")
        epitaph = makeEpitaph()
        meta.lastDeathDepth = board.depth
        meta.lastDeathWeapon = board.weapon.rawValue
        meta.runCount += 1
        docentLine = Quips.death(meta.trialNumber)   // cite the concluded trial
        meta.trialNumber += 1
        saveMeta()
        let carried = carriedFindables()
        stage = carried.isEmpty ? .dead : .bequest
        saveRun()
    }

    private func carriedFindables() -> [SpellKind] {
        board.spells.filter {
            SpellKind.findable.contains($0) && !meta.bequests.contains($0.rawValue)
        }
    }

    private func bequeath(_ sp: SpellKind?) {
        GameHaptics.tap()
        if let sp {
            meta.bequests.append(sp.rawValue)
            saveMeta()
        }
        stage = .dead
        saveRun()
    }

    private func makeEpitaph() -> String {
        let verb: String
        switch board.lastKillerType {
        case "fire", "burn": verb = "Melted"
        case "shock": verb = "Grounded"
        case "frost": verb = "Preserved"
        case "vat": verb = "Dissolved"
        case "collision": verb = "Rearranged"
        default: verb = "Disassembled"
        }
        return "\(verb) on Depth \(board.depth), mid-experiment."
    }

    private func prepareNewRun() {
        chosenWeapon = .hammer
        chosenBequest = nil
        stage = .runStart
        docentLine = Quips.runStart(meta.trialNumber)
    }

    private func abandonRun() {
        guard stage != .runStart && stage != .boot else { return }
        // handleDeath already counted this trial; restart from the death or
        // bequest screen is just "New Run".
        if stage == .dead || stage == .bequest {
            prepareNewRun()
            return
        }
        phaseGen += 1
        animActing = nil
        prePhaseBoard = nil
        cancelSelection()
        let concluded = meta.trialNumber
        meta.runCount += 1
        meta.trialNumber += 1
        saveMeta()
        board.heroDead = true   // marks the save inactive
        saveRun()
        prepareNewRun()
        docentLine = "Trial \(concluded): subject abandoned mid-procedure. Noted without comment."
    }

    private func newRun() {
        var b = BoardState()
        // Seeding is generation, not resolution — randomness is allowed here.
        var seeder = SystemRandomNumberGenerator()
        b.runSeed = seeder.next()
        b.weapon = chosenWeapon
        b.spells = SpellKind.starting + (chosenBequest.map { [$0] } ?? [])
        b.units.append(Unit(id: 1, kind: .hero, pos: Engine.heroSpawn,
                            hp: UnitKind.hero.baseHP, maxHP: UnitKind.hero.baseHP))
        b.nextId = 2
        Engine.buildFloor(&b, depth: 1)
        board = b
        GameScores.shared.report(score: 1, for: "athanor")
        overchannelQuipShown = false
        isNewRecord = false
        undoStack.removeAll()
        cancelSelection()
        docentLine = Quips.runStart(meta.trialNumber)
        inspector = "Tap Cinderwick 🕯️ to move. Tap enemies to read their plans."
        spawnRemnantIfNeeded()   // after the quip so its note survives
        // Same floor-entry dawn as descend(): one shared resolve path.
        let dawn = Engine.resolve(.beginPlayerTurn, &board)
        processEvents(dawn, playerCaused: false)
        stage = .player
        if board.enemies.isEmpty { floorCleared(); return }
        recomputeProjection()
        saveRun()
    }

    // MARK: - Persistence plumbing

    private func stageKey(_ s: Stage) -> String {
        switch s {
        case .enemyAnim: return "enemy"
        case .reward: return "reward"
        case .altar, .altarDiscard: return "altar"
        case .fountain: return "fountain"
        case .descend: return "descend"
        case .bequest: return "bequest"
        default: return "player"
        }
    }

    private func saveRun() {
        guard stage != .boot && stage != .runStart else { return }
        // Mid-phase saves persist the pre-phase snapshot the "enemy" replay
        // is correct against — never the half-resolved live board.
        let snapshot = stage == .enemyAnim ? (prePhaseBoard ?? board) : board
        // A pending bequest is a permanent meta reward: keep it resumable.
        let active = (!snapshot.heroDead && stage != .dead) || stage == .bequest
        let save = RunSave(board: snapshot, stage: stageKey(stage),
                           rewardPicksLeft: rewardPicksLeft, active: active,
                           setRecordThisRun: isNewRecord)
        SimPersist.save(save, key: Self.runKey)
    }

    private func saveMeta() {
        SimPersist.save(meta, key: Self.metaKey)
    }

    private func loadEverything() {
        if let m = SimPersist.load(Meta.self, key: Self.metaKey) { meta = m }
        guard let r = SimPersist.load(RunSave.self, key: Self.runKey), r.active else {
            prepareNewRun()
            return
        }
        // A dead board only resumes into the pending-bequest flow.
        if r.stage != "bequest" && r.board.heroDead {
            prepareNewRun()
            return
        }
        board = r.board
        rewardPicksLeft = r.rewardPicksLeft
        isNewRecord = r.setRecordThisRun ?? false
        docentLine = "The Docent looks up. 'Ah. Trial \(meta.trialNumber) resumes.'"
        switch r.stage {
        case "enemy":
            // Saved just before the phase ran: replay it — deterministic,
            // intents locked, identical outcome.
            stage = .player
            endTurn()
        case "bequest":
            // The permanent meta choice survives close/relaunch.
            epitaph = makeEpitaph()
            stage = carriedFindables().isEmpty ? .dead : .bequest
        case "reward":
            rewardOptions = drawPrecipitates()
            if rewardOptions.isEmpty { advanceRewardFlow(after: .reward) } else { stage = .reward }
        case "altar":
            altarOptions = drawAltarSpells()
            if altarOptions.isEmpty { advanceRewardFlow(after: .altar) } else { stage = .altar }
        case "fountain":
            stage = .fountain
        case "descend":
            stage = .descend
        default:
            stage = .player
            recomputeProjection()
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlayView: some View {
        switch stage {
        case .runStart: runStartOverlay
        case .reward: rewardOverlay
        case .altar: altarOverlay
        case .altarDiscard(let sp): discardOverlay(sp)
        case .fountain: fountainOverlay
        case .descend: descendOverlay
        case .bequest: bequestOverlay
        case .dead:
            GameOverOverlay(title: "The Great Work Ends",
                            subtitle: "\(epitaph)\nDepth \(board.depth) · Trial \(meta.trialNumber - 1)",
                            isVictory: false,
                            newRecord: isNewRecord,
                            buttonTitle: "New Run") {
                prepareNewRun()
            }
        default:
            EmptyView()
        }
    }

    private func overlayCard<C: View>(_ title: String, _ subtitle: String?,
                                      @ViewBuilder content: () -> C) -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                content()
            }
            .padding(18)
            .frame(maxWidth: 360)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
            .padding(20)
        }
        .transition(.opacity)
    }

    private func optionRow(emoji: String, title: String, blurb: String,
                           locked: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                Text(emoji).font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(locked ? .secondary : .primary)
                    Text(blurb)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if locked { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
            }
            .padding(10)
            .background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(locked)
    }

    private var runStartOverlay: some View {
        overlayCard("ATHANOR", "Trial \(meta.trialNumber). Choose your instrument, descend, shut off the reaction.") {
            VStack(spacing: 10) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(WeaponKind.allCases, id: \.self) { w in
                            let locked = w == .frostKnife && !meta.feats.contains("coldMethod")
                            optionRow(emoji: w.emoji,
                                      title: w.name + (chosenWeapon == w && !locked ? "  ✓" : ""),
                                      blurb: locked ? "Locked: freeze 2 enemies in one turn (Cold Method)." : w.blurb,
                                      locked: locked) {
                                GameHaptics.tap()
                                chosenWeapon = w
                            }
                        }
                        if !meta.bequests.isEmpty {
                            bequestPicker
                        }
                    }
                }
                .frame(maxHeight: 380)
                ArcadeButton(title: "Begin the Descent", systemImage: "arrow.down.circle.fill", tint: .orange) {
                    newRun()
                }
            }
        }
    }

    private var bequestPicker: some View {
        VStack(spacing: 6) {
            Text("A DEAD KEEPER'S GIFT — optional 4th slot")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(meta.bequests, id: \.self) { raw in
                if let sp = SpellKind(rawValue: raw) {
                    optionRow(emoji: sp.emoji,
                              title: sp.name + (chosenBequest == sp ? "  ✓" : ""),
                              blurb: sp.blurb) {
                        GameHaptics.tap()
                        chosenBequest = chosenBequest == sp ? nil : sp
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private var rewardOverlay: some View {
        overlayCard("Precipitate",
                    rewardPicksLeft > 1 ? "Choose one (then one more — Peer Review)." : "The floor's residue crystallizes. Choose one.") {
            VStack(spacing: 6) {
                ForEach(rewardOptions, id: \.self) { p in
                    optionRow(emoji: p.emoji, title: p.name, blurb: p.blurb) {
                        pickPrecipitate(p)
                    }
                }
            }
        }
    }

    private var altarOverlay: some View {
        overlayCard("An Altar", "It offers a spell from the tower's marginalia. Or walk past.") {
            VStack(spacing: 6) {
                ForEach(altarOptions, id: \.self) { sp in
                    optionRow(emoji: sp.emoji, title: "\(sp.name) · \(sp.ap)AP \(sp.mp)🔮", blurb: sp.blurb) {
                        takeAltarSpell(sp)
                    }
                }
                ArcadeButton(title: "Walk Past", systemImage: "figure.walk", tint: .gray) {
                    advanceRewardFlow(after: .altar)
                }
            }
        }
    }

    private func discardOverlay(_ incoming: SpellKind) -> some View {
        overlayCard("Four slots, five spells", "Your hands can hold four. Discard one for \(incoming.emoji) \(incoming.name).") {
            VStack(spacing: 6) {
                ForEach(board.spells, id: \.self) { sp in
                    optionRow(emoji: sp.emoji, title: "Discard \(sp.name)", blurb: sp.blurb) {
                        discardSpell(sp, incoming: incoming)
                    }
                }
                ArcadeButton(title: "Keep What I Have", systemImage: "xmark", tint: .gray) {
                    advanceRewardFlow(after: .altar)
                }
            }
        }
    }

    private var fountainOverlay: some View {
        overlayCard("A Fountain", "Something in the water still remembers being medicine.") {
            VStack(spacing: 8) {
                ArcadeButton(title: "Drink: heal 3 ❤️", systemImage: "heart.fill", tint: .red) {
                    pickFountain(heal: true)
                }
                ArcadeButton(title: board.maxMP >= 5 ? "Attune: 🔮 already 5 (max)" : "Attune: +1 max 🔮",
                             systemImage: "sparkles",
                             tint: .purple,
                             isEnabled: board.maxMP < 5) {
                    pickFountain(heal: false)
                }
                if board.maxMP >= 5 {
                    Text("Mana is capped at 5 — drink instead.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var descendOverlay: some View {
        let next = board.depth + 1
        let nextBiome = Engine.biome(for: next)
        return overlayCard("Depth \(board.depth) — cleared",
                           "\(nextBiome.title) waits below.") {
            ArcadeButton(title: "Descend to Depth \(next)",
                         systemImage: "arrow.down.circle.fill",
                         tint: nextBiome.tint) {
                descend()
            }
        }
    }

    private var bequestOverlay: some View {
        overlayCard("Your hands keep one thing", "One found spell may join the permanent starting pool.") {
            VStack(spacing: 6) {
                ForEach(carriedFindables(), id: \.self) { sp in
                    optionRow(emoji: sp.emoji, title: sp.name, blurb: sp.blurb) {
                        bequeath(sp)
                    }
                }
                ArcadeButton(title: "Let It All Melt", systemImage: "xmark", tint: .gray) {
                    bequeath(nil)
                }
            }
        }
    }

    // MARK: - The Docent's lab notes

    private enum Quips {
        static func runStart(_ trial: Int) -> String {
            let lines = ["Trial %d begins. Subject: one candle, ambulatory. Expectations: managed.",
                         "Trial %d. The Docent uncaps a fresh pen."]
            return String(format: lines[trial % lines.count], trial)
        }

        static func descend(_ trial: Int, depth: Int) -> String {
            let lines = ["Depth \(depth). The stairwell smells of results.",
                         "Trial %d proceeds to depth \(depth). Unremarkable, which is remarkable.",
                         "Depth \(depth). The Docent adjusts one decimal of hope."]
            return String(format: lines[(trial + depth) % lines.count], trial)
        }

        static func floorClear(_ trial: Int) -> String {
            let lines = ["Trial %d: floor rendered inert. Adequate.",
                         "Reagents neutralized. The Docent initials the margin.",
                         "Trial %d: subject survives arithmetic. Promising.",
                         "Floor annotated 'resolved'. Filed under modest triumphs."]
            return String(format: lines[trial % lines.count], trial)
        }

        static func cascade(_ trial: Int) -> String {
            let lines = ["Trial %d: subject ignited three problems with one candle. Promising.",
                         "A cascade. The Docent underlines twice, which is effusive.",
                         "Chain reaction logged. Peer review will assume exaggeration."]
            return String(format: lines[trial % lines.count], trial)
        }

        static func firstOverchannel(_ trial: Int) -> String {
            let lines = ["Trial %d: subject burns itself as fuel. The Alchemist would have wept, or applauded.",
                         "Overchannel noted. Wax is, after all, a budget."]
            return String(format: lines[trial % lines.count], trial)
        }

        static func death(_ trial: Int) -> String {
            let lines = ["Trial %d concluded. Cause: enthusiasm.",
                         "Subject extinguished. The Docent files the stub of Trial %d.",
                         "Trial %d ends. The tower remains unimpressed.",
                         "Wick recovered. Notes archived. Next candle, please."]
            return String(format: lines[trial % lines.count], trial)
        }

        static func bossIntro(cycleDepth: Int) -> String {
            switch cycleDepth {
            case 6: return "The Alchemist's Regret 🫧 floods the chamber. It only knows two moves. It only needs two."
            case 9: return "The Tallow Queen 👑. Fire feeds her. Bring anything else."
            default: return "The Clockwork Docent 🗿 shows you its schedule. Every spell you cast, it studies."
            }
        }

        static func newBest(_ depth: Int) -> String {
            let lines = ["Depth \(depth): deeper than any prior trial. The Docent allows one raised eyebrow.",
                         "A record. Depth \(depth). Noted in ink instead of pencil."]
            return lines[depth % lines.count]
        }
    }
}

#Preview {
    AthanorGameView()
}
