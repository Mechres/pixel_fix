# Pixel Fix

A Flutter utility app to fix stuck pixels and test display performance.

## Features

### Pixel Fix Utility
The primary function of this app is to help fix stuck or dead pixels on your screen by cycling through various patterns and colors:

- **Solid Colors**: Cycles through red, green, blue, white and black
- **RGB Flashing**: Rapidly alternates between red, green, and blue
- **White Flashing**: Alternates between white and black
- **RGB Cycling**: Smoothly transitions through the RGB color spectrum
- **Random Colors**: Displays randomly generated colors
- **Checkerboard**: Shows an alternating checkerboard pattern
- **Concentric Circles**: Displays expanding circle patterns
- **Diagonal Sweep**: Animates diagonal color bands across the screen
- **Gradient Wave**: Creates a dynamic color wave effect

### Display Stress Test
Tests your display's performance and responsiveness:

- **Extreme RGB Cycling**: Ultra-fast cycling through RGB values
- **High Contrast Flashing**: Rapid alternation between bright and dark
- **Pixel Inversion Test**: Checkerboard pattern that alternates pixels
- **Thermal Stress Pattern**: Color-heavy pattern to generate heat
- **Response Time Test**: Fast-moving elements to test response time
- **Burn-in Detection**: Alternating patterns to reveal burn-in issues

## How to Use

### For Fixing Stuck Pixels
1. From the main screen, tap "Start Pixel Fix"
2. Select a pattern from the dropdown menu
3. Adjust the speed as needed
4. Tap "Start" to begin the pattern
5. For best results, use fullscreen mode
6. Run each pattern for 10-15 minutes per stuck pixel

### For Display Testing
1. From the main screen, tap "Display Stress Test"
2. Select a test pattern
3. Choose a test duration
4. Tap "Start Test"
5. View performance metrics after the test completes

## Technical Details

- The app runs in landscape mode to maximize screen coverage
- Saved preferences for pattern and speed settings
- Frame rate monitoring during stress tests
- High-performance rendering for pixel-level control

## Installation

1. Clone this repository
2. Run `flutter pub get`
3. Build and run on your target device

## Requirements
- Flutter 2.0 or higher
- Requires `shared_preferences` package
