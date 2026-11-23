# MIX_APK_Bild

Репозиторий для автоматической сборки APK через GitHub Actions.

## Проекты в репозитории

| Папка | Приложение | Технология | Артефакты сборки |
|---|---|---|---|
| `Khranitoniks_v1.1/` | **Хранитоникс** и **Хранитоникс Бокс** (v1.1) | Kotlin / Compose | `Khranitoniks-v1.1-app-debug-apk`, `Khranitoniks-v1.1-box-debug-apk` |
| `oblachko_runner_v1.1/` | **Облачко: Большой забег** (v1.1) | Three.js + Capacitor 7 | `OblachkoRunner-v1.1-APK` |
| `ostrova_znaniy_v7/` | **Острова Знаний** (v7) | Godot 4.6.2 | `ostrova-znaniy-v7-apk` |
| `ostrova_znaniy_v8/` | **Острова Знаний** (v8) | Godot 4.6.2 | `ostrova-znaniy-v8-apk` |
| `VibeRadio/` | **VibeRadio** | Kotlin / Compose / Media3 | `VibeRadio-APK` |

## Где скачать собранные APK

1. Откройте вкладку **Actions** → выберите последний успешный запуск **Build All APKs**.
2. Внизу страницы в разделе **Artifacts** скачайте нужные архивы с `.apk` внутри.
3. При наличии тега вида `v*` все 6 `.apk` также публикуются в разделе **Releases**.
