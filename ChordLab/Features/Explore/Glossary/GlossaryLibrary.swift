//
//  GlossaryLibrary.swift
//  ChordLab
//
//  The built-in catalog of famous, good-sounding chord progressions.
//  Degree indices: 0=I 1=ii 2=iii 3=IV 4=V 5=vi 6=vii°
//

import Foundation

enum GlossaryLibrary {
    static let all: [GlossaryProgression] = [

        // MARK: Pop

        GlossaryProgression(
            id: "axis-of-awesome",
            name: "The Axis of Awesome",
            numerals: "I – V – vi – IV",
            details: "The four chords behind a comical number of pop hits. Starts home, visits every function, and loops forever without tiring.",
            category: .pop,
            degrees: [.init(0), .init(4), .init(5), .init(3)]
        ),

        GlossaryProgression(
            id: "sensitive-loop",
            name: "The Sensitive Loop",
            numerals: "vi – IV – I – V",
            details: "The same four chords rotated to start on the minor vi — instant melancholy. The backbone of countless emotional anthems.",
            category: .pop,
            degrees: [.init(5), .init(3), .init(0), .init(4)]
        ),

        GlossaryProgression(
            id: "doo-wop",
            name: "'50s Doo-Wop",
            numerals: "I – vi – IV – V",
            details: "The sound of the 1950s: home, a wistful dip to vi, then the classic IV–V climb back. Try it slow with sevenths on the piano.",
            category: .pop,
            degrees: [.init(0), .init(5), .init(3), .init(4)]
        ),

        GlossaryProgression(
            id: "royal-road",
            name: "The Royal Road",
            numerals: "IVmaj7 – V7 – iii7 – vi7",
            details: "Japan's beloved pop progression — it never touches home, so it floats. The maj7 start gives it that bittersweet shimmer.",
            category: .pop,
            degrees: [
                .init(3, seventh: true),
                .init(4, seventh: true),
                .init(2, seventh: true),
                .init(5, seventh: true)
            ]
        ),

        // MARK: Rock

        GlossaryProgression(
            id: "three-chord-classic",
            name: "Three-Chord Classic",
            numerals: "I – IV – V – IV",
            details: "Garage-rock in four slots: pure primary chords, no minors, no apologies. The IV on both sides of V keeps it bouncing.",
            category: .rock,
            degrees: [.init(0), .init(3), .init(4), .init(3)]
        ),

        GlossaryProgression(
            id: "half-cadence-hang",
            name: "The Cliffhanger",
            numerals: "I – IV – V…",
            details: "Ends suspended on V — a musical comma. Feel how badly your ear wants one more chord? That pull is the dominant doing its job.",
            category: .rock,
            degrees: [.init(0), .init(3), .init(4, beats: 4)]
        ),

        // MARK: Jazz

        GlossaryProgression(
            id: "jazz-turnaround",
            name: "The Jazz Turnaround",
            numerals: "ii7 – V7 – Imaj7",
            details: "Jazz's signature move: subdominant, dominant, home — all as sevenths. Learn to hear this and you can navigate any standard.",
            category: .jazz,
            degrees: [
                .init(1, seventh: true),
                .init(4, seventh: true),
                .init(0, seventh: true, beats: 4)
            ],
            suggestedTempo: 110
        ),

        GlossaryProgression(
            id: "blue-moon",
            name: "Blue Moon Changes",
            numerals: "Imaj7 – vi7 – ii7 – V7",
            details: "The doo-wop loop in a tuxedo. Every chord walks smoothly to the next, which is why crooners have leaned on it for a century.",
            category: .jazz,
            degrees: [
                .init(0, seventh: true),
                .init(5, seventh: true),
                .init(1, seventh: true),
                .init(4, seventh: true)
            ]
        ),

        GlossaryProgression(
            id: "circle-of-fifths",
            name: "Circle of Fifths Run",
            numerals: "vi7 – ii7 – V7 – Imaj7",
            details: "Each root falls a fifth to the next — the strongest motion in harmony, four links long. Feel it lock into place at the end.",
            category: .jazz,
            degrees: [
                .init(5, seventh: true),
                .init(1, seventh: true),
                .init(4, seventh: true),
                .init(0, seventh: true)
            ]
        ),

        // MARK: Classical

        GlossaryProgression(
            id: "pachelbel",
            name: "Pachelbel's Canon",
            numerals: "I – V – vi – iii – IV – I – IV – V",
            details: "The 17th-century loop that pop keeps rediscovering. A stepwise-falling bass line hides inside these eight chords.",
            category: .classical,
            degrees: [
                .init(0), .init(4), .init(5), .init(2),
                .init(3), .init(0), .init(3), .init(4)
            ],
            suggestedTempo: 70
        ),

        // MARK: Blues

        GlossaryProgression(
            id: "twelve-bar-blues",
            name: "12-Bar Blues",
            numerals: "I ×4 · IV ×2 · I ×2 · V – IV – I – V",
            details: "The twelve-bar form underneath a century of blues, rock and roll, and jazz. Real blues players sharpen every chord into a dominant 7th.",
            category: .blues,
            degrees: [
                .init(0, beats: 4), .init(0, beats: 4), .init(0, beats: 4), .init(0, beats: 4),
                .init(3, beats: 4), .init(3, beats: 4), .init(0, beats: 4), .init(0, beats: 4),
                .init(4, beats: 4), .init(3, beats: 4), .init(0, beats: 4), .init(4, beats: 4)
            ],
            suggestedTempo: 100
        ),

        // MARK: Cadences

        GlossaryProgression(
            id: "amen-cadence",
            name: "The Amen Cadence",
            numerals: "IV – I",
            details: "The plagal cadence — two chords that end a thousand hymns. Gentler than V–I because there's no leading tone pulling home.",
            category: .cadences,
            degrees: [.init(3), .init(0, beats: 4)]
        ),

        GlossaryProgression(
            id: "deceptive-turn",
            name: "The Deceptive Turn",
            numerals: "I – IV – V – vi",
            details: "Everything sets up a triumphant return home… and lands on vi instead. Composers use this bait-and-switch to keep phrases alive.",
            category: .cadences,
            degrees: [.init(0), .init(3), .init(4), .init(5, beats: 4)]
        )
    ]

    static func entries(in category: GlossaryCategory) -> [GlossaryProgression] {
        all.filter { $0.category == category }
    }
}
