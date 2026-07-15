//
//  LessonLibrary.swift
//  ChordLab
//
//  The built-in theory curriculum, in learning order
//

import SwiftUI

enum LessonLibrary {
    static let all: [Lesson] = [
        notesAndIntervals,
        majorTriads,
        minorDimAug,
        majorScaleAndKeys,
        romanNumerals,
        chordFunctions,
        seventhChords,
        cadences,
        commonProgressions,
        circleOfFifths
    ]

    static func lesson(withID id: String) -> Lesson? {
        all.first { $0.id == id }
    }

    // MARK: - 1. Notes & Intervals

    private static let notesAndIntervals = Lesson(
        id: "notes-intervals",
        title: "Notes & Intervals",
        subtitle: "The building blocks of all music",
        icon: "music.note",
        color: .blue,
        pages: [
            LessonPage(
                title: "The Musical Alphabet",
                body: "Western music uses just 12 different notes, which repeat in higher and lower versions called octaves.\n\nSeven of them have letter names — A, B, C, D, E, F, G — and the other five sit between them, named with sharps (♯) or flats (♭). C♯ and D♭ are the same key on the piano, spelled two ways.\n\nOn a piano, the white keys are the letter notes and the black keys are the sharps and flats."
            ),
            LessonPage(
                title: "Half Steps & Whole Steps",
                body: "The distance from any key to its immediate neighbor is a half step — the smallest distance in Western music. Two half steps make a whole step.\n\nHere's the catch that trips everyone up: E–F and B–C are natural half steps. There's no black key between them.\n\nEvery scale and chord you'll ever learn is just a recipe of half steps and whole steps."
            ),
            LessonPage(
                title: "Intervals",
                body: "An interval is the distance between two notes, counted by letter names: C to D is a second, C to E is a third, C to G is a fifth.\n\nIntervals also have qualities — major, minor, and perfect — based on their exact size in half steps. A major third (4 half steps) sounds bright; a minor third (3 half steps) sounds darker.\n\nStack a couple of thirds and you get a chord — tap the one below to hear a major third and a minor third working together.",
                demoChords: ["C"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "How many different pitch classes does Western music use?",
                options: ["7", "12", "10", "24"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "Which natural notes are a half step apart?",
                options: ["C–D and F–G", "A–B and D–E", "E–F and B–C", "G–A and C–D"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "The interval from C up to E is called a…",
                options: ["Second", "Third", "Fourth", "Fifth"],
                correctIndex: 1
            )
        ]
    )

    // MARK: - 2. Major Triads

    private static let majorTriads = Lesson(
        id: "major-triads",
        title: "Major Triads",
        subtitle: "The brightest three-note chord",
        icon: "pianokeys",
        color: .green,
        pages: [
            LessonPage(
                title: "What Is a Chord?",
                body: "A chord is three or more notes sounding together. The most common kind is the triad: three notes called the root, the third, and the fifth.\n\nThe root names the chord — a chord built on C is some kind of C chord. The third and fifth stack above it like floors of a building.\n\nTap the chord below and watch the piano: root, third, and fifth are color-coded.",
                demoChords: ["C"]
            ),
            LessonPage(
                title: "Building a Major Triad",
                body: "A major triad is a specific recipe: a major third (4 half steps) on the bottom, and a minor third (3 half steps) on top.\n\nFrom C: up a major third to E, then up a minor third to G. C–E–G is C major.\n\nThe same recipe works from any starting note. Try F major (F–A–C) and G major (G–B–D) below.",
                demoChords: ["C", "F", "G"]
            ),
            LessonPage(
                title: "The Major Sound",
                body: "Major triads sound bright, stable, and resolved — the musical equivalent of a smile. Most happy-sounding songs lean heavily on them.\n\nTrain your ear: play each of these major triads and notice they share the same character even though they start on different notes.\n\nThat shared character is the quality of the chord — and recognizing quality by ear is a superpower you can build in the Practice tab.",
                demoChords: ["C", "G", "D", "A"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "Which notes make up a C major triad?",
                options: ["C – E♭ – G", "C – F – A", "C – E – G", "C – D – E"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "A major triad stacks…",
                options: [
                    "a major 3rd, then a minor 3rd",
                    "two major 3rds",
                    "a minor 3rd, then a major 3rd",
                    "two perfect 4ths"
                ],
                correctIndex: 0
            ),
            PracticeQuestion(
                prompt: "Which of these chords is a major triad?",
                options: ["Am", "G", "B°", "Dm"],
                correctIndex: 1
            )
        ]
    )

    // MARK: - 3. Minor, Diminished & Augmented

    private static let minorDimAug = Lesson(
        id: "minor-dim-aug",
        title: "Minor, Diminished & Augmented",
        subtitle: "The other three triad qualities",
        icon: "moon.stars",
        color: .indigo,
        pages: [
            LessonPage(
                title: "Minor Triads",
                body: "Flip the major recipe — minor third (3 half steps) on the bottom, major third (4 half steps) on top — and you get a minor triad.\n\nA minor is A–C–E. Compare it with A major and you'll hear the difference immediately: minor sounds darker, more melancholy.\n\nOnly one note changes between major and minor — the third. That single half step carries all the emotion.",
                demoChords: ["Am", "Dm", "Em"]
            ),
            LessonPage(
                title: "Diminished Triads",
                body: "Stack two minor thirds and you get a diminished triad: tense, unstable, wanting to move somewhere.\n\nB diminished (B–D–F) is the only diminished triad you can build from the white keys — and it shows up naturally in every major key on the seventh degree.\n\nIts symbol is a small circle: B°.",
                demoChords: ["B°"]
            ),
            LessonPage(
                title: "Augmented Triads",
                body: "Stack two major thirds and you get an augmented triad: C–E–G♯. It sounds dreamlike and unresolved, like a question mark.\n\nAugmented chords are rare in everyday songs but beloved in film scores and jazz for their floating quality.\n\nIts symbol is a plus sign: C+.",
                demoChords: ["C+"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "Which notes make up an A minor triad?",
                options: ["A – C♯ – E", "A – C – E", "A – C – E♭", "A – B – E"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "A diminished triad stacks…",
                options: [
                    "two major 3rds",
                    "a major 3rd, then a minor 3rd",
                    "two minor 3rds",
                    "a 4th and a 5th"
                ],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "Which chord is augmented?",
                options: ["C°", "Cm", "C7", "C+"],
                correctIndex: 3
            )
        ]
    )

    // MARK: - 4. The Major Scale & Keys

    private static let majorScaleAndKeys = Lesson(
        id: "major-scale-keys",
        title: "The Major Scale & Keys",
        subtitle: "Where melodies and chords come from",
        icon: "key.fill",
        color: .orange,
        pages: [
            LessonPage(
                title: "The Pattern",
                body: "The major scale is a fixed pattern of steps: Whole–Whole–Half–Whole–Whole–Whole–Half.\n\nStart on C and follow the pattern and you land only on white keys: C D E F G A B C. That's why C major is the beginner's key.\n\nSing \"do re mi fa sol la ti do\" — that's the major scale."
            ),
            LessonPage(
                title: "Keys & Key Signatures",
                body: "Start the same pattern on a different note and you'll need sharps or flats to keep the step recipe intact. G major needs one sharp (F♯); F major needs one flat (B♭).\n\nA key is a home base: when a song is \"in G major,\" the G major scale supplies its notes and G feels like home.\n\nTap the chords below to hear the home chord of three different keys.",
                demoChords: ["C", "G", "D"]
            ),
            LessonPage(
                title: "Scale Degrees",
                body: "Each note of the scale has a number (1–7) and a name that hints at its job:\n\n1 Tonic — home. 2 Supertonic. 3 Mediant. 4 Subdominant. 5 Dominant — the strongest pull back to home. 6 Submediant. 7 Leading tone — leans hungrily into the tonic.\n\nThese names matter because chords built on each degree inherit the same jobs — that's the next lesson."
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "The step pattern of a major scale is…",
                options: [
                    "W–H–W–W–H–W–W",
                    "W–W–H–W–W–W–H",
                    "H–W–W–H–W–W–W",
                    "W–W–W–H–W–W–H"
                ],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "Which major scale uses only the white keys?",
                options: ["G major", "F major", "C major", "D major"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "The 5th degree of a major scale is called the…",
                options: ["Dominant", "Tonic", "Mediant", "Leading tone"],
                correctIndex: 0
            )
        ]
    )

    // MARK: - 5. Roman Numerals & Diatonic Chords

    private static let romanNumerals = Lesson(
        id: "roman-numerals",
        title: "Roman Numerals",
        subtitle: "Naming chords by their place in the key",
        icon: "list.number",
        color: .blue,
        pages: [
            LessonPage(
                title: "Chords From the Scale",
                body: "Build a triad on each note of a major scale, using only scale notes, and you get the seven diatonic chords of the key — the chords that naturally belong there.\n\nIn C major: C, Dm, Em, F, G, Am, B°.\n\nTap through them below — together they're the palette nearly every song in C major paints with.",
                demoChords: ["C", "Dm", "Em", "F"]
            ),
            LessonPage(
                title: "The Numeral System",
                body: "Musicians label diatonic chords with Roman numerals by scale degree: I ii iii IV V vi vii°.\n\nUppercase means major (I, IV, V), lowercase means minor (ii, iii, vi), and the little circle marks the diminished chord (vii°).\n\nSo in C major: I = C, ii = Dm, V = G, vii° = B°. The pattern of qualities is identical in every major key.",
                demoChords: ["G", "Am", "B°"]
            ),
            LessonPage(
                title: "Why Numerals Matter",
                body: "Numerals describe a song's shape independently of its key. \"I–IV–V\" is the same move in C major (C–F–G) as it is in E major (E–A–B).\n\nLearn a progression once as numerals and you own it in all twelve keys.\n\nThis is exactly what the Explore tab shows under every chord — now you can read it.",
                demoChords: ["C", "F", "G"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "In any major key, the ii chord is…",
                options: ["major", "diminished", "minor", "augmented"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "In C major, which chord is the V?",
                options: ["F", "G", "Am", "Em"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "The vii° chord in a major key is…",
                options: ["diminished", "major", "minor", "augmented"],
                correctIndex: 0
            )
        ]
    )

    // MARK: - 6. Chord Functions

    private static let chordFunctions = Lesson(
        id: "chord-functions",
        title: "Chord Functions",
        subtitle: "Home, away, and tension",
        icon: "arrow.triangle.turn.up.right.circle",
        color: .green,
        pages: [
            LessonPage(
                title: "Three Jobs",
                body: "Every diatonic chord performs one of three jobs:\n\nTonic — home, rest, resolution. Subdominant — moving away from home, building momentum. Dominant — maximum tension, demanding to resolve back home.\n\nListen to the classic trip below: home (C), away (F), tension (G), and imagine landing back on C.",
                demoChords: ["C", "F", "G"]
            ),
            LessonPage(
                title: "The Pull of V",
                body: "The dominant chord (V) contains the leading tone, which sits one half step below home and pulls hard toward it.\n\nAdd a seventh (V7) and you also get a tritone — the most restless interval in music — making the pull almost irresistible.\n\nPlay G7 then C and feel the release.",
                demoChords: ["G7", "C"]
            ),
            LessonPage(
                title: "The Families",
                body: "Each function is a family, not a single chord:\n\nTonic family: I and vi (and iii). Subdominant family: IV and ii. Dominant family: V and vii°.\n\nFamily members can substitute for each other — swap Am for C, or Dm for F, and the phrase keeps its shape with a fresh color. This is the number-one songwriting trick.",
                demoChords: ["Am", "Dm", "B°"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "Which function creates the strongest pull back home?",
                options: ["Subdominant", "Tonic", "Dominant", "Mediant"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "In C major, F major serves which function?",
                options: ["Subdominant", "Tonic", "Dominant", "Leading tone"],
                correctIndex: 0
            ),
            PracticeQuestion(
                prompt: "Which chord belongs to the tonic family alongside I?",
                options: ["V", "IV", "ii", "vi"],
                correctIndex: 3
            )
        ]
    )

    // MARK: - 7. Seventh Chords

    private static let seventhChords = Lesson(
        id: "seventh-chords",
        title: "Seventh Chords",
        subtitle: "Four notes, richer colors",
        icon: "7.circle",
        color: .purple,
        pages: [
            LessonPage(
                title: "Adding the Seventh",
                body: "Stack one more third on top of a triad and you get a seventh chord — four notes with a lusher, more grown-up sound.\n\nCmaj7 (C–E–G–B) is a C major triad plus a major seventh. It's the sound of jazz ballads and neo-soul.\n\nCompare C and Cmaj7 below — same foundation, extra glow.",
                demoChords: ["C", "Cmaj7"]
            ),
            LessonPage(
                title: "The Five Flavors",
                body: "Five seventh-chord qualities cover nearly everything:\n\nMajor 7th (Cmaj7) — dreamy. Minor 7th (Dm7) — mellow. Dominant 7th (G7) — bluesy tension. Half-diminished (Bø7) — moody suspense. Diminished 7th (B°7) — maximum drama.\n\nTap through the first four — they're the diatonic sevenths of C major you'll meet constantly.",
                demoChords: ["Cmaj7", "Dm7", "G7", "Bø7"]
            ),
            LessonPage(
                title: "The Dominant Seventh",
                body: "The dominant seventh deserves special attention: it only occurs naturally on the fifth degree, so hearing one instantly tells your ear where home is.\n\nIts internal tritone (between the 3rd and 7th) resolves outward by half steps straight into the tonic chord.\n\nG7 to C is harmony's strongest one-two punch. Play it below.",
                demoChords: ["G7", "Cmaj7"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "Which notes make up G7?",
                options: ["G – B – D – F♯", "G – B – D – F", "G – B♭ – D – F", "G – B – D♯ – F"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "The symbol for a major seventh chord on C is…",
                options: ["C7", "Cm7", "Cmaj7", "Cø7"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "The diatonic seventh chord built on vii in a major key is…",
                options: ["Half-diminished (ø7)", "Major 7th", "Dominant 7th", "Minor 7th"],
                correctIndex: 0
            )
        ]
    )

    // MARK: - 8. Cadences

    private static let cadences = Lesson(
        id: "cadences",
        title: "Cadences",
        subtitle: "How musical sentences end",
        icon: "flag.checkered",
        color: .red,
        pages: [
            LessonPage(
                title: "Musical Punctuation",
                body: "A cadence is the chord move that ends a musical phrase — the punctuation of harmony.\n\nSome cadences are periods (fully resolved), some are commas (pausing mid-thought), and some are plot twists.\n\nLearn four of them and you can hear the architecture of almost any song."
            ),
            LessonPage(
                title: "Authentic & Plagal",
                body: "The authentic cadence, V → I, is the period at the end of the sentence: tension, then complete resolution. Play G7 then C below.\n\nThe plagal cadence, IV → I, is gentler — you know it as the \"A-men\" at the end of hymns. Play F then C.\n\nBoth land home, but with very different attitudes.",
                demoChords: ["G7", "C", "F"]
            ),
            LessonPage(
                title: "Deceptive & Half",
                body: "The deceptive cadence, V → vi, sets up the expected homecoming and then sidesteps to the relative minor. Your ear leans for C and lands on Am. Sneaky, and beautiful.\n\nThe half cadence simply stops on V — a comma that leaves the phrase hanging, begging for more.\n\nPlay G7 then Am to hear the deception.",
                demoChords: ["G7", "Am"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "V → I is called a(n)…",
                options: ["Plagal cadence", "Half cadence", "Deceptive cadence", "Authentic cadence"],
                correctIndex: 3
            ),
            PracticeQuestion(
                prompt: "The \"Amen\" cadence is…",
                options: ["IV → I", "V → I", "V → vi", "ii → V"],
                correctIndex: 0
            ),
            PracticeQuestion(
                prompt: "A deceptive cadence resolves V to…",
                options: ["I", "vi", "IV", "iii"],
                correctIndex: 1
            )
        ]
    )

    // MARK: - 9. Common Progressions

    private static let commonProgressions = Lesson(
        id: "common-progressions",
        title: "Common Progressions",
        subtitle: "The patterns behind a thousand songs",
        icon: "square.stack.3d.up.fill",
        color: .teal,
        pages: [
            LessonPage(
                title: "I – IV – V",
                body: "Three chords, a million songs. I–IV–V is the backbone of blues, rock and roll, folk, and country.\n\nIt's the three functions in their purest form: home, away, tension, home.\n\nPlay C, F, G below and you're playing the skeleton of the entire early rock songbook.",
                demoChords: ["C", "F", "G"]
            ),
            LessonPage(
                title: "The Pop Loops",
                body: "I–V–vi–IV is the modern pop loop — count how many hit choruses ride it and you'll lose track. In C: C, G, Am, F.\n\nIts older cousin I–vi–IV–V powered the doo-wop era of the 1950s. Same four chords, different rotation, different feel.\n\nRotation matters: which chord starts the loop changes where \"home\" sits in the cycle.",
                demoChords: ["C", "G", "Am", "F"]
            ),
            LessonPage(
                title: "ii – V – I",
                body: "Jazz's favorite move: ii–V–I. The subdominant ii sets up the dominant V, which resolves to I — three functions in a row, usually as seventh chords.\n\nIn C major: Dm7, G7, Cmaj7. Play them in order and you'll recognize the sound of every jazz standard's turnaround.\n\nThe Practice tab's Progression Challenge will train you to spot all of these by ear.",
                demoChords: ["Dm7", "G7", "Cmaj7"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "The classic jazz turnaround is…",
                options: ["I – IV – V", "ii – V – I", "I – V – vi – IV", "vi – IV – I – V"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "The '50s doo-wop progression is…",
                options: ["I – vi – IV – V", "I – IV – I – V", "ii – V – I – I", "I – iii – IV – V"],
                correctIndex: 0
            ),
            PracticeQuestion(
                prompt: "In C major, ii – V – I is…",
                options: ["Em – A – D", "F – G – C", "Dm – G – C", "Dm – F – C"],
                correctIndex: 2
            )
        ]
    )

    // MARK: - 10. The Circle of Fifths

    private static let circleOfFifths = Lesson(
        id: "circle-of-fifths",
        title: "The Circle of Fifths",
        subtitle: "The map of all twelve keys",
        icon: "circle.hexagongrid",
        color: .cyan,
        pages: [
            LessonPage(
                title: "The Map of Keys",
                body: "Arrange the twelve keys so that each step clockwise is a perfect fifth up, and something magical happens: neighboring keys differ by exactly one accidental.\n\nC (no sharps) sits at the top. One step clockwise is G (one sharp). One step counterclockwise is F (one flat).\n\nKeys that are neighbors on the circle share almost all their notes — which is why they sound related.",
                demoChords: ["C", "G"]
            ),
            LessonPage(
                title: "Reading the Circle",
                body: "Clockwise from C, each key adds one sharp: G, D, A, E, B… Counterclockwise, each adds one flat: F, B♭, E♭, A♭, D♭…\n\nThe new sharp is always the new key's leading tone; the new flat is always its fourth degree. The circle isn't a fact to memorize — it's a machine that generates key signatures.",
                keyName: "F",
                demoChords: ["F", "Bb"]
            ),
            LessonPage(
                title: "Using the Circle",
                body: "The circle is practical, not just pretty:\n\nA key's V chord is one step clockwise; its IV chord is one step counterclockwise — your three most important chords are always adjacent.\n\nModulating to a neighboring key sounds smooth; jumping across the circle sounds dramatic. Composers navigate by this map constantly — and now you can too.",
                demoChords: ["F", "C", "G"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "One step clockwise from C on the circle is…",
                options: ["F", "D", "G", "A"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "Each clockwise step around the circle adds…",
                options: ["one sharp", "one flat", "two sharps", "a minor key"],
                correctIndex: 0
            ),
            PracticeQuestion(
                prompt: "F major has how many flats?",
                options: ["0", "2", "3", "1"],
                correctIndex: 3
            )
        ]
    )
}
