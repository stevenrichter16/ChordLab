//
//  OctaveNavigationBar.swift
//  ChordLab
//
//  Created by Steven Richter on 6/21/25.
//

import SwiftUI


// MARK: - Octave Navigation Bar

struct OctaveNavigationBar: View {
    let startOctave: Int
    let endOctave: Int
    let scrollProxy: ScrollViewProxy?
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(startOctave...endOctave, id: \.self) { octave in
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollProxy?.scrollTo("octave\(octave)", anchor: .center)
                    }
                }) {
                    Text("C\(octave)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(Color.appTertiaryBackground)
                        .cornerRadius(6)
                }
            }
        }
    }
}

