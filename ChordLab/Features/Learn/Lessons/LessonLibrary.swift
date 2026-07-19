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
        circleOfFifths,
        // Progression workshop: applied lessons on BUILDING progressions
        progressionFoundations,
        harmonicRhythm,
        loopsVsJourneys,
        bassMotion,
        finishingProgressions
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
            ),
            LessonPage(
                title: "Consonance & Dissonance",
                body: "Intervals aren't just distances — they have personalities. A perfect fifth (7 half steps) is so stable that rock power chords are built from nothing else. The tritone (6 half steps) is so restless that medieval theorists nicknamed it \"the devil in music.\"\n\nConsonant intervals (thirds, fifths, sixths) blend; dissonant ones (seconds, sevenths, the tritone) rub and want to move. Music breathes by traveling between the two — all tension, then release.\n\nEvery chord you'll ever build is a bundle of intervals, and its personality is the sum of theirs. Tap C, then B° — one is all consonance, the other hides a tritone. Count the tension.",
                demoChords: ["C", "B°"]
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
            ),
            LessonPage(
                title: "Inversions & Voicings",
                body: "C–E–G doesn't have to appear in that exact order. Play E–G–C, or G–C–E, and it's still C major — just inverted. Pianists use inversions to glide between chords with minimal hand movement; that smoothness is called voice leading.\n\nChordLab plays chords in close root position so the root–third–fifth color coding always lines up, but listen to real recordings and you'll notice the bass note isn't always the root.\n\nWhat never changes is the recipe: if the notes boil down to root, major third, and perfect fifth, it's a major triad no matter how they're stacked. Quality lives in the notes, not the order.",
                demoChords: ["C", "G"]
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
            ),
            LessonPage(
                title: "Where Each Quality Lives",
                body: "The four qualities are not equally common, and each has a natural habitat. In every major key, three diatonic chords are major (I, IV, V), three are minor (ii, iii, vi), exactly one is diminished (vii°) — and augmented doesn't occur diatonically at all.\n\nThat ratio explains a lot of music: major and minor carry the story, diminished appears in passing for spice, and augmented is a special effect saved for moments that should tilt.\n\nA practical tip for later: B° shares three of its notes with G7, so the diminished chord often stands in for the dominant. Play them back to back and hear the family resemblance.",
                demoChords: ["B°", "G7", "C+"]
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
            ),
            LessonPage(
                title: "The Relative Minor",
                body: "Every major key has a shadow. Take the same seven notes but treat the sixth degree as home, and you get the relative minor: C major's notes, started from A, give A minor. Same key signature, completely different mood.\n\nThis is why the vi chord feels like a second home inside a major key, and why so many songs drift between a bright chorus and a moody verse without ever changing key signature — they're just leaning on different ends of the same scale.\n\nPlay C, then Am. Same family, different gravity. When you build progressions later, this pair is your brightness dial.",
                demoChords: ["C", "Am"]
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
            ),
            LessonPage(
                title: "Reading Real Charts",
                body: "Numerals grow suffixes as chords get richer: ii7 is the minor seventh built on the second degree, V7 is the dominant seventh, Imaj7 is the major seventh on home. ChordLab writes them exactly this way on the timeline and in the analysis strip.\n\nThis isn't academic — Nashville session players record entire albums from numeral charts. When the singer wants a different key, nobody rewrites anything; the numbers already work everywhere.\n\nTest yourself before tapping: in C major, what numeral is Em? What about B°? Now tap them and check the labels your ear gave you.",
                demoChords: ["Em", "B°"]
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
            ),
            LessonPage(
                title: "Predicting the Next Chord",
                body: "Functions make harmony predictable in the best way. Tonic can go anywhere. Subdominant usually moves to dominant, or slips back home. Dominant almost always resolves to tonic.\n\nThat's the grammar of harmony: T → S → D → T. Most progressions you'll ever write are sentences in that grammar — and the suggestion chips in the Explore dock speak it fluently when they offer your next chord.\n\nBreak the grammar on purpose (dominant falling back to subdominant, like G to F) and you get the rule-bending float that blues and pop use constantly. Know the rule, then choose when to bend it.",
                demoChords: ["C", "F", "G7", "C"]
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
            ),
            LessonPage(
                title: "When to Use Sevenths",
                body: "Sevenths are a dial, not an upgrade. Folk and punk mostly stay with plain triads; jazz and R&B live in sevenths; pop mixes freely — triads in the big chorus, sevenths in the verse for intimacy.\n\nEasy experiment: build any triad progression in Explore, then flip the Type toggle to 7ths and audition the same degrees. Same skeleton, new wardrobe.\n\nOne caution: V7 is hungrier than plain V — the added tritone demands resolution. Use the seventh where you want that hunger, and the plain triad where you want the pull gentler. Compare them below.",
                demoChords: ["G", "G7"]
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
            ),
            LessonPage(
                title: "Cadences in the Wild",
                body: "Once you can name them, you'll hear cadences everywhere: authentic at final choruses, plagal in gospel amens and indie outros, half cadences at every pre-chorus that leaves you leaning forward, deceptive at the bridge where a ballad refuses to end.\n\nIn ChordLab, the dock's analysis strip names your cadence automatically as you build, and the Resolve menu can append an authentic (V7 → I) or plagal (IV → I) ending with one tap, spelled correctly for your key.\n\nTry this: write a short phrase, then end it four different ways and listen to what each ending does to the story. Endings are a choice, not a default.",
                demoChords: ["G7", "C", "F", "Am"]
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
            ),
            LessonPage(
                title: "The 12-Bar Blues",
                body: "The granddaddy of progression forms: twelve bars of just I, IV, and V in a fixed arrangement — four bars of I, two of IV, two of I, then the V–IV–I–V turnaround.\n\nIt's the chassis under blues, early rock and roll, and jump jazz. Learn to play a 12-bar in any key and you can sit in with a band anywhere on Earth — the form is a universal handshake among musicians.\n\nYou don't have to build it by hand: open the Progression Glossary (the book icon in Explore) and add the 12-Bar Blues entry to your timeline with one tap, then listen for the form's three-act shape.",
                demoChords: ["C", "F", "G"]
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
            ),
            LessonPage(
                title: "Transposing With the Circle",
                body: "Transposing — moving a song to a new key — is just sliding around the circle. Every chord keeps its numeral; only the letter names rotate.\n\nChordLab does this mechanically for you: open any saved progression in the Library and choose Transpose to re-render it in a new key. Watch the numerals stay put while the chord names change — that's the circle at work.\n\nWhy bother? Singers have ranges, guitars love E and A, horn sections love flat keys. One song, twelve costumes. Play the home chords of three neighboring keys below and hear how gently the ground shifts.",
                demoChords: ["F", "C", "G", "D"]
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

    // MARK: - 11. Progression Workshop: Foundations

    private static let progressionFoundations = Lesson(
        id: "progression-foundations",
        title: "Workshop: Root Motion",
        subtitle: "The engine that drives progressions",
        icon: "gearshape.2",
        color: .mint,
        pages: [
            LessonPage(
                title: "Start and End at Home",
                body: "Nearly every progression treats the I chord as bookends: start there to establish home, end there — or deliberately don't — to control how finished the music feels.\n\nThe simplest complete progression is a round trip: home, somewhere else, tension, home. Even one stop counts: C → G → C is already a song.\n\nBuild it right now. In Explore, hold C to add it to the dock, then G, then C again, and press play. Everything in this workshop grows from that trip.",
                demoChords: ["C", "G", "C"]
            ),
            LessonPage(
                title: "Motion by Fifths",
                body: "The strongest chord change moves the root down a fifth (or up a fourth — same landing note). V → I is this move. So are ii → V and vi → ii.\n\nChain them and you get harmony's conveyor belt: vi → ii → V → I, each chord falling a fifth into the next. Jazz calls this running the circle, and it's why those progressions feel inevitable.\n\nPlay the chain below and notice how each chord hands its momentum forward — nothing sounds parked until the last one.",
                demoChords: ["Am", "Dm", "G", "C"]
            ),
            LessonPage(
                title: "Motion by Steps & Thirds",
                body: "Stepwise root motion (IV → V, or iii → IV) feels like walking — steady and purposeful. It builds the classic climb to home: IV → V → I.\n\nMotion by thirds (I → vi, C → Am) barely feels like motion at all, because the two chords share two of their three notes. That near-stillness is perfect for smooth mood shifts.\n\nMix the three motions and your progression gets a gait: fifths for power, steps for drive, thirds for glide. Listen for all three in the sequence below.",
                demoChords: ["F", "G", "C", "Am"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "The strongest root motion between two chords is…",
                options: ["up a step", "down a third", "down a fifth", "staying on the same root"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "Which progression is a chain of falling fifths?",
                options: ["I – IV – I – V", "vi – ii – V – I", "I – iii – IV – ii", "I – V – vi – iii"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "C and Am sound so smooth together because…",
                options: ["they share two notes", "they're both major", "the bass leaps an octave", "they're both dominant chords"],
                correctIndex: 0
            )
        ]
    )

    // MARK: - 12. Progression Workshop: Harmonic Rhythm

    private static let harmonicRhythm = Lesson(
        id: "harmonic-rhythm",
        title: "Workshop: Harmonic Rhythm",
        subtitle: "How long each chord breathes",
        icon: "metronome",
        color: .orange,
        pages: [
            LessonPage(
                title: "The Other Rhythm",
                body: "Melodies have rhythm — and so does harmony. Harmonic rhythm is how often the chords change: every beat, every bar, every two bars.\n\nSlow harmonic rhythm (one chord held for bars at a time) feels spacious and anthemic — think stadium choruses. Fast harmonic rhythm (a new chord every beat) feels busy, theatrical, ornate.\n\nThe same four chords at different paces are different songs. Chord choice is only half of writing a progression; chord length is the other half."
            ),
            LessonPage(
                title: "Uneven Lengths Tell Stories",
                body: "Progressions get their shape when chords have different lengths. A classic move: two quick chords, then one long one — setup, setup, arrival.\n\nThe jazz turnaround does exactly this: ii7 and V7 take two beats each, then Imaj7 stretches across four. The landing feels earned because the approach was brisk.\n\nIn the dock's expanded editor, the dotted band at the bottom of each chord cell cycles its length through 1, 2, and 4 beats — and the cell widens to show it. Sculpt with it: try making your last chord the longest.",
                demoChords: ["Dm7", "G7", "Cmaj7"]
            ),
            LessonPage(
                title: "Tempo Is a Material",
                body: "The same progression at 70 BPM is a ballad; at 140 it's a banger. Tempo doesn't just make music faster — it changes what the harmony means.\n\nThat's why glossary entries carry suggested tempos: Pachelbel arrives slow and stately, the 12-bar arrives at a strut. When you add one to an empty timeline, ChordLab adopts its tempo; the BPM pill overrides it anytime.\n\nA useful pairing rule: slow tempos tolerate faster chord changes, and fast tempos want fewer, longer chords. When a progression feels cluttered, slow the changes before you slow the song."
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "Harmonic rhythm means…",
                options: ["the drummer's pattern", "how often the chords change", "the melody's note lengths", "the time signature"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "A short–short–LONG chord pattern usually creates…",
                options: ["a key change", "random tension", "silence", "a sense of earned arrival"],
                correctIndex: 3
            ),
            PracticeQuestion(
                prompt: "In the dock, tapping the band at the bottom of a chord cell…",
                options: ["cycles its length through 1, 2, and 4 beats", "deletes the chord", "transposes the progression", "toggles the metronome"],
                correctIndex: 0
            )
        ]
    )

    // MARK: - 13. Progression Workshop: Loops vs. Journeys

    private static let loopsVsJourneys = Lesson(
        id: "loops-vs-journeys",
        title: "Workshop: Loops vs. Journeys",
        subtitle: "Two shapes every progression takes",
        icon: "arrow.triangle.2.circlepath",
        color: .pink,
        pages: [
            LessonPage(
                title: "The Loop",
                body: "A loop is a progression designed to circle forever. It deliberately avoids a strong cadence so the last bar flows straight back into the first.\n\nI–V–vi–IV is the champion: it touches home mid-cycle but never lands hard enough to stop. That's why it can run underneath an entire song without wearing out.\n\nPlay through the loop below twice without pausing and notice how the F chord leans back into C — the seam is designed to be invisible.",
                demoChords: ["C", "G", "Am", "F"]
            ),
            LessonPage(
                title: "Rotations",
                body: "Keep the same four chords but start the cycle somewhere else, and you get a different song. vi–IV–I–V opens on the minor chord — instant melancholy — even though it contains exactly the same chords as I–V–vi–IV.\n\nWhy? Listeners assume the first thing they hear is home. The starting chord sets the loop's center of gravity before the theory gets a vote.\n\nPlay this rotation and compare it with the previous page. Same ingredients, different weather.",
                demoChords: ["Am", "F", "C", "G"]
            ),
            LessonPage(
                title: "The Journey",
                body: "A journey progression goes somewhere and ends. It moves through subdominant territory, peaks on a dominant, and cadences home. Looped verses plus a journey pre-chorus that cadences into the chorus — that's the architecture of half the songs on the charts.\n\nTo turn a loop into a journey, break the cycle: stretch the final chord longer, swap it for V, or use the dock's Resolve menu to append a proper ending.\n\nLoop for energy. Journey for arrival. Good songs need both, and now you can build both.",
                demoChords: ["F", "G", "C"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "A loop keeps circling because it avoids…",
                options: ["the tonic chord", "minor chords", "repetition", "a strong cadence"],
                correctIndex: 3
            ),
            PracticeQuestion(
                prompt: "vi–IV–I–V compared with I–V–vi–IV is…",
                options: ["the same chords, rotated to start elsewhere", "a different key", "all minor chords", "an authentic cadence"],
                correctIndex: 0
            ),
            PracticeQuestion(
                prompt: "Listeners tend to hear the loop's first chord as…",
                options: ["a mistake", "the dominant", "home", "a passing chord"],
                correctIndex: 2
            )
        ]
    )

    // MARK: - 14. Progression Workshop: Bass Lines

    private static let bassMotion = Lesson(
        id: "bass-motion",
        title: "Workshop: Bass Lines",
        subtitle: "The line your progression walks on",
        icon: "arrow.down.right.circle",
        color: .brown,
        pages: [
            LessonPage(
                title: "The Lowest Voice Leads",
                body: "Listeners track the bass more closely than any other voice — it's the floor the harmony stands on. In root-position progressions the bass simply plays the chord roots, which means your root motion IS your bass line.\n\nChordLab reinforces this with bass doubling (Settings → Sound): every progression chord sounds its root an octave down, like a pianist's left hand.\n\nReplay the falling-fifths chain below, but this time listen only to the bottom of the sound. That striding, purposeful walk is what fifth-motion looks like from the floor.",
                demoChords: ["Am", "Dm", "G", "C"]
            ),
            LessonPage(
                title: "The Great Descents",
                body: "Some famous progressions exist to harmonize a falling line. Pachelbel's Canon — C, G, Am, Em, F, C, F, G — was written to carry the stepwise descent C–B–A–G–F–E: in the original, inverted chords put those notes in the bass, one stair per chord.\n\nChordLab plays chords in root position, so here you'll hear the descent as bolder strides — roots falling in fourths (C down to G, A down to E) — same downward gravity, bigger steps. Both versions feel inevitable because the harmony is following a line.\n\nThe trick powers countless ballads: choose a descending line first, then harmonize each note with a diatonic chord that contains it. The chords follow the line, not the other way around.",
                demoChords: ["C", "G", "Am", "Em"]
            ),
            LessonPage(
                title: "Writing From the Bass Up",
                body: "Try composing backwards. Pick a singable bass path first — say C, down to A, down to F, up to G — then choose the diatonic chords rooted on those notes: C, Am, F, G. The bass line just wrote the '50s doo-wop progression for you.\n\nAlmost any bass path you can hum implies a progression, which is why great progressions feel melodic even before there's a melody.\n\nYour turn: choose four scale notes in Explore, add their diatonic chords to the dock, and listen to your invented bass line stand up and walk.",
                demoChords: ["C", "Am", "F", "G"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "In a root-position progression, the bass line is…",
                options: ["always the note C", "the melody, doubled", "the chord roots in order", "improvised"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "Pachelbel's Canon is built around…",
                options: ["a single held chord", "a descending bass line", "a drum groove", "the blues scale"],
                correctIndex: 1
            ),
            PracticeQuestion(
                prompt: "ChordLab's bass doubling plays…",
                options: ["each chord's root an octave lower", "a fifth above the melody", "a percussion track", "the next chord early"],
                correctIndex: 0
            )
        ]
    )

    // MARK: - 15. Progression Workshop: Finishing

    private static let finishingProgressions = Lesson(
        id: "finishing-progressions",
        title: "Workshop: Finishing Touches",
        subtitle: "Endings, color, and shipping it",
        icon: "checkmark.seal",
        color: .green,
        pages: [
            LessonPage(
                title: "Choose Your Ending",
                body: "The last two chords decide how finished your progression feels. V7 → I says \"the end.\" IV → I says \"amen.\" V → vi says \"to be continued.\" Stopping on V says \"lean in — there's more.\"\n\nThe dock's Resolve menu writes the strong endings for you, spelled correctly for your key, giving the approach chord 2 beats and the landing 4 so the ending breathes.\n\nAudition several endings on the same phrase and choose with your ears, not the rulebook. The right ending depends on what happens next in the song.",
                demoChords: ["G7", "C", "F", "Am"]
            ),
            LessonPage(
                title: "The Color Pass",
                body: "Once the skeleton works, make a color pass. Swap in family members — vi for I somewhere, ii for IV — to freshen the palette without changing the shape. Upgrade chosen moments to sevenths: verse chords to m7 for intimacy, the final V to V7 for maximum pull.\n\nThe test after every swap: does home still feel like home? If a substitution muddies the pull, revert it. Function first, color second.\n\nThe dashed suggestion chips after your last chord speak this language — they offer function-appropriate next moves, not random ones.",
                demoChords: ["Am", "Dm7", "G7", "Cmaj7"]
            ),
            LessonPage(
                title: "Save, Study, Ship",
                body: "When it sounds right, keep it: save the progression with a name and tags, and it lives in your Library with automatic pattern and cadence badges. Transpose it to a singer-friendly key. Export it as MIDI and drop it into GarageBand or Logic to keep producing.\n\nThen build the habit that actually teaches songwriting: study one glossary entry a day. Play it, read why it works, add it to your timeline, and mutate exactly one chord.\n\nImitation, then mutation, then invention — that's the whole path. You know enough theory to be dangerous now. Go build something.",
                demoChords: ["C", "G", "Am", "F"]
            )
        ],
        quiz: [
            PracticeQuestion(
                prompt: "The strongest \"this is the end\" move is…",
                options: ["V7 → I", "I → IV", "vi → ii", "IV → vi"],
                correctIndex: 0
            ),
            PracticeQuestion(
                prompt: "A \"color pass\" on a working progression means…",
                options: ["doubling the tempo", "changing the key signature", "swapping family members and adding sevenths", "deleting every other chord"],
                correctIndex: 2
            ),
            PracticeQuestion(
                prompt: "Which dock feature appends a correctly spelled ending?",
                options: ["the loop toggle", "the Resolve menu", "the BPM slider", "the metronome"],
                correctIndex: 1
            )
        ]
    )
}
