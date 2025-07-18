# CityRacer-TurboDrive



# 🚗 City Racer

City Racer is a fast-paced, mobile racing game built with [Flutter](https://flutter.dev/) and powered by the [Flame engine](https://flame-engine.org/). Players race through urban tracks, avoid obstacles, collect coins, and unlock new cars and levels. The game supports multiple control schemes and rich audiovisual feedback for an immersive experience.

---

## 📱 Features

- 🚘 Multiple game modes: Classic, Endless, and Level-based gameplay.
- 🎮 Customizable controls: Tilt, Swipe, Tap, On-screen wheel, and more.
- 🎨 Dynamic UI: Onboarding, Garage, Road Shop, Settings, and Level Select screens.
- 🔊 Audio effects using Flame Audio.
- 💾 Persistent storage via Shared Preferences and Hive.
- 📡 Facebook Auth integration and Google AdMob support.
- 🌍 Adaptive gameplay with sensor-based input (accelerometer).
- 💤 Wakelock to keep screen active during gameplay.

---

## 📦 Installation

```bash
git clone https://github.com/yourusername/city_racer.git
cd city_racer
flutter pub get
flutter run
```

Ensure your environment supports Flutter 3.8.0 or later.

## 🗂 Project Structure

```
lib/
├── main.dart                  # Entry point
├── game/                      # Core game logic and mechanics
│   ├── modes/                 # Game modes: classic, endless, level
│   ├── controls/              # Input handling mechanisms
│   ├── nodes/                 # Visual game components (car, road, coins)
│   ├── utils/                 # Game configuration and helpers
├── screens/                   # UI screens: splash, garage, settings, etc.
├── widgets/                   # Reusable UI components (if any)
```

---

## 🧰 Dependencies

| Package                 | Purpose                                |
| ----------------------- | -------------------------------------- |
| `flame`                 | 2D game engine                         |
| `flame_forge2d`         | Physics support                        |
| `flame_audio`           | Sound and music                        |
| `sensors_plus`          | Accelerometer input                    |
| `shared_preferences`    | Storing settings/local data            |
| `hive_flutter`          | NoSQL storage for persistent game data |
| `wakelock_plus`         | Prevent screen from sleeping           |
| `flutter_facebook_auth` | Social login                           |
| `google_mobile_ads`     | AdMob monetization                     |

---

## 🎮 Gameplay Overview

* Players control a vehicle navigating a busy city street.
* Obstacles and collectible coins appear dynamically.
* Different control modes adjust how users steer or interact.
* Visuals and sound provide real-time feedback for player actions.
* Levels can be selected or played infinitely in endless mode.

---

## 📸 Screenshots
---
<img width="270" height="600" alt="Screenshot_1752674810" src="https://github.com/user-attachments/assets/eedc73c9-d299-4535-873c-5ccadf7cb86b" />
<img width="270" height="600" alt="Screenshot_1752674919" src="https://github.com/user-attachments/assets/12bbe133-beb5-4a1d-b5b0-df93a947f5e0" />
<img width="270" height="600" alt="Screenshot_1752674837" src="https://github.com/user-attachments/assets/2663c014-56af-4234-bdaf-ab3509b868d1" />


<img width="270" height="600" alt="Screenshot_1752674851" src="https://github.com/user-attachments/assets/f3ec5387-2a34-485c-bdc6-cbeb8d75c78e" />
<img width="270" height="600" alt="Screenshot_1752674910" src="https://github.com/user-attachments/assets/3e75eb9f-55b5-45f8-929e-0380345802d1" />
<img width="270" height="600" alt="Screenshot_1752674841" src="https://github.com/user-attachments/assets/ea222e75-9b9f-4cdc-a7d4-4a3a8c68430b" />


<img width="270" height="600" alt="Screenshot_1752674584" src="https://github.com/user-attachments/assets/53d2b4dc-7f16-4025-8973-4c51e155cdd8" />
<img width="270" height="600" alt="Simulator Screenshot - iPhone 16 Pro Max - 2025-07-10 at 19 31 00" src="https://github.com/user-attachments/assets/54ccc827-96bd-4798-9fae-f9401d697300" />
<img width="270" height="600" alt="Screenshot_1752674888" src="https://github.com/user-attachments/assets/4499dfb4-bdef-420f-a03a-2784d49b7365" />

## 🛠️ Customization

To add new cars, roads, or levels:

* Add assets to `assets/images/cars/`, `assets/images/roads/`
* Update game logic in `game/nodes/` or `game/utils/level_config.dart`
* Update `pubspec.yaml` to include new assets

---

## 🧪 Development Notes

* The game uses a modular architecture for scalability.
* Game logic is decoupled from UI rendering.
* Physics and animations are managed through Flame's core loop.

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.


---
