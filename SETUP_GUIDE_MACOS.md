# WineCellar App — Setup Guide for macOS

Guide to run the WineCellar app on an iOS simulator and as a macOS desktop application.

---

## What you will install

| Tool | What it does |
|---|---|
| **Git** | Downloads the project code from the internet |
| **Flutter SDK** | The toolkit that builds the app |
| **Xcode** | Provides the iOS simulator and macOS build tools |
| **CocoaPods** | Dependency manager required for iOS and macOS builds |

Total download size: approximately **15–20 GB** (Xcode alone is ~12 GB). Make sure you have enough free disk space.

---

## Part 1 — Install Git

Git comes pre-installed on most Macs. To check, open **Terminal** (press `Cmd + Space`, type `Terminal`, press Enter) and run:

```
git --version
```

If you see a version number, you already have Git. If a prompt appears asking you to install developer tools, click **Install** and wait for it to finish.

---

## Part 2 — Install Flutter SDK

### Step 2a — Download Flutter

1. Go to: **https://docs.flutter.dev/get-started/install/macos**
2. Under the **macOS** section, click the download button for the latest stable Flutter SDK (it will be a `.zip` file).
3. The file will save to your Downloads folder.

### Step 2b — Extract Flutter

1. Open **Terminal** and run:
   ```
   cd ~/development
   ```
   If that folder does not exist, create it first:
   ```
   mkdir ~/development
   ```
2. Move and extract the downloaded file:
   ```
   unzip ~/Downloads/flutter_macos_*-stable.zip -d ~/development/
   ```

### Step 2c — Add Flutter to PATH (so Terminal can find it)

1. Find out which shell you use by running:
   ```
   echo $SHELL
   ```
2. If it says `/bin/zsh` (the default on modern Macs), open your shell config file:
   ```
   open -e ~/.zshrc
   ```
   If it says `/bin/bash`, use `~/.bash_profile` instead.
3. Add this line at the bottom of the file:
   ```
   export PATH="$HOME/development/flutter/bin:$PATH"
   ```
4. Save and close the file, then reload it:
   ```
   source ~/.zshrc
   ```

### Step 2d — Verify Flutter works

```
flutter --version
```

You should see a version number. If you see "command not found", redo Step 2c.

---

## Part 3 — Install Xcode

1. Open the **App Store** on your Mac.
2. Search for **Xcode** and click **Get** (it is free).
3. Wait for the download to finish — it is large and may take a while.
4. Open **Xcode** once after installation. It will prompt you to install additional components — click **Install** and wait.
5. Accept the Xcode license agreement by running in Terminal:
   ```
   sudo xcodebuild -license accept
   ```
6. Complete the first-launch setup:
   ```
   sudo xcodebuild -runFirstLaunch
   ```

---

## Part 4 — Install CocoaPods

CocoaPods is required to build iOS and macOS Flutter apps.

Open **Terminal** and run:

```
sudo gem install cocoapods
```

If that fails with a permissions error, try using Homebrew instead:

```
brew install cocoapods
```

> If you do not have Homebrew, install it first by running the command from **https://brew.sh**.

Verify the installation:

```
pod --version
```

---

## Part 5 — Download the WineCellar project

1. Open **Terminal**.
2. Navigate to where you want to save the project, for example your Desktop:
   ```
   cd ~/Desktop
   ```
3. Download the project:
   ```
   git clone https://github.com/anastasiyakrupinina-cmd/wineCellar
   ```
   > If you received the project as a `.zip` file instead, unzip it to your Desktop and skip this step.
4. Move into the project folder:
   ```
   cd wine_cellar
   ```

---

## Part 6 — Install project dependencies

Still in **Terminal** (in the `wine_cellar` folder), run:

```
flutter pub get
```

This downloads all the libraries the app needs. Wait until you see "Got dependencies!" at the end.

---

## Part 7 — Run the Flutter setup check

Run:

```
flutter doctor
```

This checks if everything is set up correctly:

- A green **[✓]** means that item is good.
- A red **[✗]** or yellow **[!]** means something is missing.

Once you see checkmarks for **Flutter**, **Xcode**, and **CocoaPods**, you are ready.

Common fix — if it says Xcode has an issue:
```
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

---

## Part 8 — Run the app on the iOS simulator

### Step 8a — Start the iOS simulator

Open the simulator from Terminal:

```
open -a Simulator
```

A virtual iPhone will appear on your screen. Wait until it fully boots up (the lock screen or home screen will appear).

Alternatively, open it from Xcode: **Xcode → Open Developer Tool → Simulator**.

### Step 8b — Launch the WineCellar app on the simulator

1. Go back to **Terminal** (make sure you are in the `wine_cellar` folder).
2. Run:
   ```
   flutter run -d ios
   ```
3. Flutter will build the app and install it on the virtual iPhone. The first build may take 3–5 minutes.
4. When it is done, the **WineCellar** app will open automatically on the simulator.

---

## Part 9 — Run the app as a macOS desktop application

### Step 9a — Enable macOS desktop support

Run this once in **Terminal**:

```
flutter config --enable-macos-desktop
```

### Step 9b — Launch the app

In **Terminal** (in the `wine_cellar` folder), run:

```
flutter run -d macos
```

This will build and launch the WineCellar app as a native macOS window. The first build may take 3–5 minutes.

---

## Part 10 — Log in to the app

The WineCellar app uses your **University of Vienna (u:account)** credentials to log in and sync your data:

- **Username**: your university email address (e.g., `a12345678@unet.univie.ac.at`)
- **Password**: your ucloud app password. Generate it at ucloud.univie.ac.at → Settings → Security → Devices & Sessions

---

## Troubleshooting

### "flutter: command not found"
Flutter is not on your PATH. Redo Step 2c, then close and reopen Terminal.

### "CocoaPods not installed" or pod errors
Run `sudo gem install cocoapods` again, or try `brew install cocoapods`. Then run `flutter doctor` to confirm.

### Xcode license error
Run `sudo xcodebuild -license accept` in Terminal.

### Build fails with dependency errors
Run these two commands in order:
```
flutter clean
flutter pub get
```
Then try running the app again.

### iOS simulator does not appear
Make sure Xcode is installed and you have run `sudo xcodebuild -runFirstLaunch`. Then try `open -a Simulator` again.

---

## Quick reference — commands summary

| What to do | Command |
|---|---|
| Download dependencies | `flutter pub get` |
| Check setup | `flutter doctor` |
| Start iOS simulator | `open -a Simulator` |
| Run on iOS simulator | `flutter run -d ios` |
| Enable macOS desktop support | `flutter config --enable-macos-desktop` |
| Run on macOS desktop | `flutter run -d macos` |
| Clean build cache | `flutter clean` |

---

*App name: WineCellar | Built with Flutter*
