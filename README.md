# Wine Cellar

A personal wine cellar management app built with Flutter as a bachelor thesis project at the **University of Vienna**, Faculty of Computer Science.

---

## About

Wine Cellar is a cross-platform mobile and desktop application that lets you catalogue, track, and manage your personal wine collection. It stores all data locally on your device and syncs to the University of Vienna's cloud storage (u:cloud) so your collection is available across all your devices.

---

## Features

- **Wine catalog** — add wines with details such as name, vintage, winery, region, country, grape varieties, alcohol content, food pairings, and critic scores
- **Storage management** — assign cellar locations and track bottle quantities per size
- **Search & filter** — find wines by name, type, region, vintage, and more
- **Wishlist** — save wines you want to acquire
- **Archive** — keep a record of wines you have finished
- **Purchase history** — log when and where bottles were bought
- **u:cloud sync** — automatic backup and sync via WebDAV using your University of Vienna (u:account) credentials

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter / Dart |
| State management | flutter_bloc (Cubit) |
| Navigation | auto_route |
| Dependency injection | get_it + injectable |
| Local database | SQLite via sqflite |
| Cloud sync | WebDAV (u:cloud, University of Vienna) |
| Secure credential storage | flutter_secure_storage |

---

## Supported Platforms

- Android
- Windows (desktop)
- iOS
- macOS

---

## Getting Started

- [SETUP_GUIDE.md](SETUP_GUIDE.md) — Windows 11 (Android simulator + Windows desktop)
- [SETUP_GUIDE_MACOS.md](SETUP_GUIDE_MACOS.md) — macOS (iOS simulator + macOS desktop)

### Login

The app uses your University of Vienna **u:account** credentials:

- **Username**: your university email (e.g. `a12345678@unet.univie.ac.at`)
- **Password**: your ucloud app password — generate it at [ucloud.univie.ac.at](https://ucloud.univie.ac.at) under Settings → Security → Devices & Sessions

---

## Project Structure

```
lib/
  core/           # Shared infrastructure (database, router, theme, sync, DI)
  feature/
    wine/         # Wine data models and repository
    dashboard_page/
    search_page/
    wishlist_page/
    archive_page/
    manage_storage_page/
    purchase_history/
    profile_page/
    login_page/
```

---

## Author

Anastasiia Krupinina  
Bachelor's thesis — University of Vienna, Faculty of Computer Science
