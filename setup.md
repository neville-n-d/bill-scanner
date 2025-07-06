# Flutter Setup Guide

## Installing Flutter

### 1. Download Flutter SDK
Visit the official Flutter website: https://flutter.dev/docs/get-started/install

### 2. Extract and Set Path
```bash
# Extract Flutter to a desired location (e.g., ~/development)
cd ~/development
unzip ~/Downloads/flutter_macos_arm64_3.16.5-stable.zip

# Add Flutter to your PATH
export PATH="$PATH:~/development/flutter/bin"
```

### 3. Add to Shell Profile
Add this line to your `~/.zshrc` or `~/.bash_profile`:
```bash
export PATH="$PATH:~/development/flutter/bin"
```

### 4. Verify Installation
```bash
flutter doctor
```

### 5. Install Dependencies
Once Flutter is installed, run:
```bash
cd electricity_bill_app
flutter pub get
```

## Platform Setup

### Android
1. Install Android Studio
2. Install Android SDK
3. Create an Android Virtual Device (AVD)
4. Run `flutter doctor` to verify setup

### iOS (macOS only)
1. Install Xcode from App Store
2. Install Xcode Command Line Tools
3. Accept Xcode license: `sudo xcodebuild -license accept`
4. Run `flutter doctor` to verify setup

## Running the App

1. **Connect a device or start an emulator**
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```

## Troubleshooting

### Common Issues

1. **Flutter not found**
   - Make sure Flutter is in your PATH
   - Restart your terminal after adding to PATH

2. **Dependencies not found**
   - Run `flutter pub get` in the project directory
   - Check your internet connection

3. **Camera permissions**
   - Add required permissions to AndroidManifest.xml and Info.plist
   - Grant permissions on device when prompted

4. **API key issues**
   - Replace placeholder API key in `lib/services/ai_service.dart`
   - Ensure you have valid API access

### Getting Help

- Run `flutter doctor` to diagnose issues
- Check Flutter documentation: https://flutter.dev/docs
- Visit Flutter community: https://flutter.dev/community 