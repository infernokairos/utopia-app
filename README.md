# UTOPIA

> The all-in-one student workspace — combining academic attendance tracking, rich note-taking, campus community events, focus tools, and custom Material 3 themes.

---

## 🌟 Key Features

### 📚 Academic & Attendance Tracking
* **Attendance Management**: Automated portal sync, detailed subject statistics, and total attendance overview.
* **"What If" Attendance Calculator**: Interactive simulator to predict future attendance based on missed or attended classes.
* **Timetables & Assignments**: Personal class schedule management and assignment tracking.

### 📝 Notes & Knowledge Base
* **Block & Markdown Editor**: Built-in rich-text document editing powered by AppFlowy.
* **Visual Link Graph**: Interactive knowledge map linking related notes and concepts.
* **Drive & Community Notes**: Share and browse notes across the student community with Google Drive integration.

### 🎯 Focus & Habit Productivity
* **Focus Mode**: Ambient soundscapes and timer for uninterrupted study sessions.
* **Habit Tracker**: Daily habit logging, streak tracking, and interactive task heatmaps.

### 🏛️ Campus Community & Events
* **Events & Ticketing**: Discover campus events, manage QR tickets, view organizer dashboards, and claim certificates.
* **Student Projects & Feed**: Showcase personal projects and explore student initiatives across campus.
* **Peer Chat & Directory**: Connect with classmates, message peers, and join university broadcast channels.
* **SciWordle**: Daily science-themed word puzzle with global campus leaderboards.

### 🎨 M3 Expressive Themes
Supports custom Material 3 Expressive light & dark color palettes:
* ☀️ **Rose Gold** *(Ivory alabaster canvas with warm rose-gold accents)*
* ☀️ **Baby Lav** *(Restorative digital violet and soft pastel lavender)*
* 🌙 **Say Inferno** *(Ember soot dark cards with fiery flame-red accents)*
* 🌙 **Sweet Lime** *(Deep slate with electric citrus-lime highlights)*
* 🌙 **Graphite** *(Sleek industrial monochrome dark)*
* ☀️ **Slate Monochrome** *(Clean high-contrast light theme)*

---

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.11.3`)
* **Backend & Auth**: Firebase (Auth, Firestore, Realtime DB, Cloud Storage, Messaging) & Supabase
* **Local Storage**: SQLite (`sqflite`), `flutter_secure_storage`, `shared_preferences`
* **Editor**: `appflowy_editor`, `flutter_markdown`
* **UI & Typography**: Google Fonts (`Roboto Flex`, `Outfit`), `flutter_animate`, Custom Material 3 Expressive System

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.11.3`)
* Android Studio / VS Code with Flutter extension
* Android Device / Emulator (or iOS setup)

### Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/infernoGurala/utopia-app.git
   cd utopia-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📂 Project Architecture

```text
lib/
├── main.dart               # App entrypoint & global theme provider
├── screens/                # UI screens (Attendance, Notes, Focus, Events, Profile, etc.)
├── services/               # Backend API services (Firebase, Supabase, Attendance APIs)
├── theme/                  # Material 3 Expressive theme engine & custom palettes
└── widgets/                # Reusable UI components & custom controls
```

---

## 👤 Author

Designed & Developed by **`𝕀 ℕ 𝔽 𝔼 ℝ ℕ 𝕆`**
