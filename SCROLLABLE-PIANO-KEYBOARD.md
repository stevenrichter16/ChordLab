I've created a mock-up of the scrollable linear keyboard design with these key features:
Key Features Implemented:
1. Horizontal Scrolling Layout

Traditional piano layout spanning 3 octaves (C3-C5)
Smooth horizontal scrolling with momentum
Touch-friendly scrolling for mobile devices
Custom scrollbar styling

2. Navigation Features

Quick navigation buttons (C3, C4, C5) for jumping to specific octaves
Left/right scroll indicators that appear on hover
Auto-scroll to root note when selecting a chord
Smooth scroll animations

3. Visual Design

Larger keys (45px width) for better touch targets
Clear octave labels above each group
Only highlighted keys show labels to reduce clutter
Hover effects on keys for better interactivity

4. Enhanced Highlighting

Chord notes: Blue (#007AFF) with elevation and shadow
Scale notes: Green border with thicker bottom border
Root notes: Pulsing animation with enhanced glow
Playing notes: Yellow with press-down animation

5. Smart Features

Labels only appear on highlighted keys
Center alignment on C4 when page loads
Responsive scroll indicators that hide at scroll limits
Support for both major and minor chords

Advantages of This Design:

Familiar Layout: Musicians will instantly recognize the traditional keyboard
Full Range: Can easily extend to more octaves if needed
Better Key Size: Larger keys are easier to tap on mobile
Clear Visual Hierarchy: Octave groupings make navigation intuitive
Smooth Interactions: Hardware-accelerated scrolling feels native

Integration Notes:
For your SwiftUI implementation:

Use ScrollView(.horizontal) with ScrollViewReader for programmatic scrolling
Implement scrollTo() for the octave quick navigation
Use DragGesture for custom scroll physics if needed
The highlighting system can use your existing @State properties

This design provides the most familiar and extensible approach while maintaining excellent usability on touch devices.