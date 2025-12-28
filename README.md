# Atomic Orbital - Flutter Port

A Flutter port of the original Java-based Android game "Atomic Orbital".

## Original Game
The original game was built in Java for Android. Players fly around the core and collect energy while avoiding emitting photons. Available on Google Play: https://play.google.com/store/apps/details?id=de.numpy.orbital.orbital4

## Flutter Port Features

- **Cross-platform**: Runs on iOS, Android, Web, and Desktop
- **Modern UI**: Built with Flutter's Material Design
- **Entity-Component System**: Clean architecture for game objects
- **Audio Support**: Background music and sound effects
- **Settings Persistence**: High scores and game preferences
- **Responsive Design**: Adapts to different screen sizes

## Game Mechanics

- **Player**: Orbits around the central atom
- **Atom**: Central nucleus that the player orbits
- **Photons**: Dangerous particles that spawn from the atom
- **Energy**: Collectible items that increase your score
- **Lives**: You have 3 lives - avoid photons to survive

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add required assets:
   - Download Orbitron font from Google Fonts and place in `assets/fonts/`
   - Add audio files to `assets/audio/` (see placeholder.txt for required files)

4. Run the game:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── constants/
│   └── game_constants.dart      # Game configuration
├── models/
│   ├── entity.dart              # Entity base class
│   ├── components.dart          # Component system
│   └── vector2d.dart           # 2D vector math
├── services/
│   ├── audio_service.dart       # Audio management
│   └── settings_service.dart    # Settings persistence
├── game/
│   ├── game_engine.dart         # Main game logic
│   └── game_screen.dart         # UI and rendering
└── main.dart                    # App entry point
```

## Architecture

The game uses an Entity-Component System (ECS) architecture:

- **Entities**: Game objects (player, atom, photons, energy)
- **Components**: Data and behavior (position, graphics, logic, collision)
- **Systems**: Game logic and rendering

## Controls

- **Tap**: Start game from menu
- **Pause Button**: Pause/resume game
- **Mute Button**: Toggle audio
- **Energy Button**: Spawn energy for testing

## Development

### Adding New Features

1. **New Entity Types**: Add to `EntityType` enum and create factory methods
2. **New Components**: Extend base component classes in `components.dart`
3. **New Logic**: Create custom logic components for entity behavior

### Performance Optimization

- The game runs at 60 FPS
- Entity pooling can be added for better performance
- Custom painting is used for efficient rendering

## License

This is a port of the original Atomic Orbital game. Please respect the original game's licensing.

## Contributing

Feel free to submit issues and enhancement requests!
