# WineCellar App — Setup Guide for Windows 11

This guide will walk you through every step to run the WineCellar app on your Windows 11 computer — both as a Windows desktop app and on an Android phone simulator. No prior IT knowledge is required. Just follow each step in order.

1. Скачать гит
1. Скачали по ссылке проект Zip.
Скачать флаттер как в синтуркции, ссылку поменять
2. Скачать Visual Studio Code
3. Cкачать Android Studio (More Actions -> Virtual Device Manager). Также  Settings, в поиске Android SDK: три галочки
Android SDK Command-line Tools (latest)
Android SDK Platform-Tools
Android SDK Build-Tools
3. Открыть проект в  Visual Studio 
4.
5. Открыть терминал в Visual Studio 

---

## What you will install

| Tool | What it does |
|---|---|
| **Git** | Downloads the project code from the internet |
| **Flutter SDK** | The toolkit that builds the app |
| **Android Studio** | Provides the Android phone simulator |
| **Visual Studio** | Provides tools needed to run the app on Windows |

Total download size: approximately **10–15 GB**. Make sure you have enough free disk space.

---

## Part 1 — Install Git

Git is a tool that lets you download ("clone") the project code.

2. Go to: **https://git-scm.com/download/win**
3. Download and install Git

---

## Part 2 — Install Flutter SDK

Flutter is the framework that builds the app.

### Step 2a — Download Flutter

1. Go to: **https://docs.flutter.dev/get-started/install/windows/desktop**
2. Under the section **"Download and install"**, click the button that says **"flutter_windows_3.x.x-stable.zip"** (the exact version number does not matter — download the latest).
3. The file will save to your Downloads folder.

### Step 2b — Extract Flutter

1. Open your **Downloads** folder.
2. Right-click the downloaded `.zip` file and choose **"Extract All..."**.
3. In the window that appears, type this path as the destination:
   ```
   C:\flutter
   ```
4. Click **Extract**. Wait until it finishes.

### Step 2c — Add Flutter to PATH (so Windows can find it)

1. Click the **Start** button (Windows logo) and type: `environment variables`
2. Click **"Edit the system environment variables"**.
3. In the window that opens, click the **"Environment Variables..."** button near the bottom right.
4. In the top section labeled **"User variables for [your name]"**, find the row called **Path** and double-click it.
5. Click **"New"** (top right of the list).
6. Type exactly:
   ```
   C:\flutter\bin
   ```
7. Click **OK** on all open windows to close them.

### Step 2d — Verify Flutter works

1. Click **Start**, type `cmd`, and press **Enter** to open the Command Prompt (a black window).
2. Type this command and press **Enter**:
   ```
   flutter --version
   ```
3. You should see a version number printed. If you see an error saying "flutter is not recognized", go back and redo Step 2c.

---

## Part 3 — Install Visual Studio (required for Windows desktop apps)

This is needed to build the app for Windows. Note: this is **Visual Studio**, not **Visual Studio Code** — they are different programs.

1. Go to: **https://visualstudio.microsoft.com/downloads/**
2. Under **"Community"** (the free version), click **"Free download"**.
3. Open the installer.
4. When the installer opens, it will show you a list of "Workloads". Find and check the box for:
   - **"Desktop development with C++"**
5. Click **"Install"** at the bottom right.
6. This will take a while (several GB to download). Wait until it finishes.

---

## Part 4 — Install Android Studio (required for the phone simulator)

### Step 4a — Download and install

1. Go to: **https://developer.android.com/studio**
2. Click the big **"Download Android Studio"** button.
3. Accept the terms and click the download button.
4. Open the installer and click **Next** on every screen without changing anything.
5. Click **Install**, then **Finish** when done.

### Step 4b — First-time setup of Android Studio

1. Open **Android Studio** from your Start menu.
2. The first time it opens, it will run a **Setup Wizard**. Click **Next**.
3. Choose **"Standard"** installation type and click **Next**.
4. Accept all license agreements (click **Accept** for each one that appears, then **Finish**).
5. It will download some additional files. Wait for it to complete.

### Step 4c — Create a virtual Android device (phone simulator)

1. Inside Android Studio, look for the option called **"Device Manager"**. It may be in the right sidebar or in the menu under **Tools → Device Manager**.
2. Click **"Create Device"** (or the **+** button).
3. In the list that appears, select **"Pixel 8"** (or any phone with a "Play Store" icon next to it), then click **Next**.
4. You will now see a list of Android versions. Find one with **"API 34"** or **"API 35"** in the name and a **download arrow** next to it. Click the arrow to download it first, wait, then click **Next**.
5. Click **Finish**.

You now have a virtual Android phone. You can see it listed in Device Manager.

---

## Part 5 — Download the WineCellar project

1. Open the **Command Prompt** (Start → type `cmd` → Enter).
2. Choose a folder where you want to save the project. For example, your Desktop:
   ```
   cd %USERPROFILE%\Desktop
   ```
3. Now download the project by running (replace the URL below with the actual repository URL you were given):
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

Still in the Command Prompt (in the `wine_cellar` folder), run:

```
flutter pub get
```

This downloads all the libraries the app needs. Wait until it finishes (you should see "Got dependencies!" at the end).

---

## Part 7 — Run the Flutter setup check

Run:

```
flutter doctor
```

This checks if everything is set up correctly. Look at the output:

- A green **checkmark [✓]** means that item is good.
- A red **[✗]** or yellow **[!]** means something is missing.

Common fixes:
- If it says **"Visual Studio - missing"**: make sure you completed Part 3.
- If it says **"Android toolchain"** has an issue: run `flutter doctor --android-licenses` and press `y` then **Enter** for each prompt.

Once you see checkmarks for **Flutter**, **Windows (desktop)**, and **Android toolchain**, you are ready.

---

## Part 8 — Run the app on the Android simulator

### Step 8a — Start the Android simulator

1. Open **Android Studio**.
2. Click **"Device Manager"** on the right sidebar.
3. Find the virtual device you created (e.g., "Pixel 8") and click the green **Play** triangle next to it.
4. An Android phone will appear on your screen. Wait until it fully boots up (you will see the home screen of the virtual phone).

### Step 8b — Launch the WineCellar app on the simulator

1. Go back to the **Command Prompt** (make sure you are in the `wine_cellar` folder).
2. Run:
   ```
   flutter run -d android
   ```
3. Flutter will build the app and install it on the virtual phone. This may take 2–5 minutes the first time.
4. When it is done, the **WineCellar** app will open automatically on the virtual phone.

---

## Part 9 — Run the app as a Windows desktop application

In the **Command Prompt** (in the `wine_cellar` folder), run:

```
flutter run -d windows
```

This will build and launch the WineCellar app as a regular Windows window on your desktop. The first build may take 2–5 minutes.

---

## Part 10 — Log in to the app

The WineCellar app uses your **University of Vienna (u:account)** credentials to log in and sync your data:

- **Username**: your university email address (e.g., `a12345678@unet.univie.ac.at`)
- **Password**: your ucloud app password. Generate it at ucloud.univie.ac.at -> Settings -> Security -> Devices & Sessions


---

## Troubleshooting

### "flutter is not recognized"
You need to add Flutter to PATH. Redo Step 2c, then close and reopen the Command Prompt.

### The Android simulator is very slow
This is normal on some computers. In Android Studio, go to **Settings → Tools → Emulator** and check **"Launch in a tool window"**. Also make sure your computer has virtualization enabled — ask someone to help you check BIOS settings if the emulator refuses to start.

### "Unable to locate Android SDK"
Open Android Studio, go to **Settings → Appearance & Behavior → System Settings → Android SDK**, and note the SDK location path. Then run:
```
flutter config --android-sdk "C:\path\to\sdk"
```
Replace the path with what you found in Android Studio.

### "Missing Visual Studio components"
Re-open the Visual Studio Installer from the Start menu, find your Visual Studio installation, click **Modify**, and make sure **"Desktop development with C++"** is checked.

### Build fails with dependency errors
Run these two commands in order:
```
flutter clean
flutter pub get
```
Then try running the app again.

---

## Quick reference — commands summary

| What to do | Command |
|---|---|
| Download dependencies | `flutter pub get` |
| Check setup | `flutter doctor` |
| Run on Android simulator | `flutter run -d android` |
| Run on Windows desktop | `flutter run -d windows` |
| Clean build cache | `flutter clean` |

---

*App name: WineCellar | Built with Flutter*
