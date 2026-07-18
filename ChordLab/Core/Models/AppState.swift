//
//  AppState.swift
//  ChordLab
//
//  Global app state management
//

import Foundation
import SwiftUI

@Observable
final class AppState {
    var selectedTab: Int = 0

    // Additional app-wide state can be added here
    var isOnboarded: Bool = false
    var currentTheme: ColorScheme? = nil
    
    // Navigation helpers
    func switchToLearn() {
        selectedTab = 0
    }
    
    func switchToExplore() {
        selectedTab = 1
    }
    
    func switchToLibrary() {
        selectedTab = 2
    }
    
    func switchToPractice() {
        selectedTab = 3
    }
    
    func switchToProfile() {
        selectedTab = 4
    }
}