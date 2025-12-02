# 🛠️ Flutter Commands Cheat Sheet

Guide de référence rapide pour toutes les commandes Flutter utiles.

---

## 🚀 Démarrage

```bash
# Vérifier l'installation de Flutter
flutter doctor

# Version détaillée
flutter doctor -v

# Version de Flutter
flutter --version

# Mettre à jour Flutter
flutter upgrade

# Voir les channels disponibles
flutter channel

# Changer de channel (stable, beta, dev)
flutter channel stable
```

---

## 📦 Gestion des Packages

```bash
# Installer les dépendances
flutter pub get

# Mettre à jour les packages
flutter pub upgrade

# Voir les packages obsolètes
flutter pub outdated

# Voir l'arbre des dépendances
flutter pub deps

# Nettoyer le cache
flutter pub cache clean
flutter pub cache repair

# Ajouter un package
flutter pub add nom_du_package

# Retirer un package
flutter pub remove nom_du_package
```

---

## 🏃 Exécution

```bash
# Lancer l'app (device auto-détecté)
flutter run

# Lancer sur un device spécifique
flutter run -d device_id

# Lancer en mode debug
flutter run --debug

# Lancer en mode profile (pour analyser perf)
flutter run --profile

# Lancer en mode release
flutter run --release

# Lancer sur Android
flutter run -d android

# Lancer sur iOS
flutter run -d ios

# Lancer sur Chrome
flutter run -d chrome

# Lancer sur Windows
flutter run -d windows

# Lancer sur macOS
flutter run -d macos

# Lancer sur Linux
flutter run -d linux

# Hot reload manuel
flutter run --hot

# Verbose mode (plus de logs)
flutter run -v
```

---

## 📱 Gestion des Devices

```bash
# Lister tous les devices connectés
flutter devices

# Lister tous les émulateurs
flutter emulators

# Lancer un émulateur
flutter emulators --launch emulator_id

# Créer un émulateur (avec Android SDK)
flutter emulators --create

# Voir les devices en détail
flutter devices -v
```

---

## 🏗️ Build

### Android

```bash
# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build APK par ABI
flutter build apk --split-per-abi

# Build App Bundle (Play Store)
flutter build appbundle --release

# Build avec obfuscation
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols

# Analyser la taille de l'APK
flutter build apk --analyze-size
```

### iOS

```bash
# Build iOS (release)
flutter build ios --release

# Build sans codesign
flutter build ios --no-codesign

# Build pour simulateur
flutter build ios --simulator
```

### Web

```bash
# Build web
flutter build web

# Build avec renderer spécifique
flutter build web --web-renderer html
flutter build web --web-renderer canvaskit
flutter build web --web-renderer auto

# Build PWA
flutter build web --pwa-strategy offline-first
```

### Desktop

```bash
# Build Windows
flutter build windows

# Build macOS
flutter build macos

# Build Linux
flutter build linux
```

---

## 🧪 Tests

```bash
# Lancer tous les tests
flutter test

# Lancer un test spécifique
flutter test test/widget_test.dart

# Tests avec coverage
flutter test --coverage

# Tests en mode watch
flutter test --watch

# Tests d'intégration
flutter drive --target=test_driver/app.dart

# Tests avec device
flutter test -d device_id
```

---

## 🔍 Analyse et Qualité

```bash
# Analyser le code
flutter analyze

# Analyser avec plus de détails
flutter analyze --verbose

# Formater le code
flutter format .

# Formater un fichier spécifique
flutter format lib/main.dart

# Vérifier le format sans modifier
flutter format --set-exit-if-changed .

# Dart fix (corrections automatiques)
dart fix --apply
```

---

## 🐛 Debug et Logs

```bash
# Voir les logs en temps réel
flutter logs

# Logs d'un device spécifique
flutter logs -d device_id

# Logs verbeux
flutter logs -v

# Lancer DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Ouvrir DevTools dans le navigateur
flutter devtools

# Screenshot de l'app en cours
flutter screenshot

# Attach au process Flutter
flutter attach
```

---

## 🧹 Nettoyage

```bash
# Nettoyer le build
flutter clean

# Nettoyer et réinstaller
flutter clean && flutter pub get

# Supprimer les fichiers générés
rm -rf .dart_tool
rm -rf build
rm pubspec.lock
flutter pub get

# Reset complet du projet
flutter clean
rm -rf .dart_tool
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -rf .packages
rm pubspec.lock
flutter pub get
```

---

## 📊 Performance

```bash
# Profile mode avec timeline
flutter run --profile --trace-skia

# Analyser les performances
flutter run --profile --analyze-size

# Voir la taille de l'app
flutter build apk --analyze-size
flutter build appbundle --analyze-size

# Observer le rendu des frames
flutter run --trace-skia

# Dump du snapshot
flutter build apk --dump-info

# Compilation AOT
flutter build aot
```

---

## 🔧 Configuration

```bash
# Voir la configuration Flutter
flutter config

# Activer/désactiver analytics
flutter config --no-analytics
flutter config --enable-analytics

# Activer web
flutter config --enable-web

# Activer Windows
flutter config --enable-windows-desktop

# Activer macOS
flutter config --enable-macos-desktop

# Activer Linux
flutter config --enable-linux-desktop

# Voir toutes les options
flutter config --help
```

---

## 📚 Création de Projet

```bash
# Créer un nouveau projet
flutter create mon_app

# Créer avec package name custom
flutter create --org com.monentreprise mon_app

# Créer une application (par défaut)
flutter create --template=app mon_app

# Créer un package
flutter create --template=package mon_package

# Créer un plugin
flutter create --template=plugin mon_plugin

# Créer avec description
flutter create --description "Description de l'app" mon_app

# Créer avec plateformes spécifiques
flutter create --platforms=android,ios mon_app

# Créer dans le dossier actuel
flutter create .
```

---

## 🌐 Web Spécifique

```bash
# Lancer sur Chrome
flutter run -d chrome

# Lancer avec hot reload
flutter run -d chrome --hot

# Lancer avec port spécifique
flutter run -d web-server --web-port=8080

# Build web avec PWA
flutter build web --pwa-strategy offline-first

# Build web release
flutter build web --release

# Build avec base href custom
flutter build web --base-href /mon-app/
```

---

## 🍎 iOS Spécifique

```bash
# Installer les pods
cd ios && pod install && cd ..

# Mettre à jour les pods
cd ios && pod update && cd ..

# Clean des pods
cd ios && rm -rf Pods && rm Podfile.lock && pod install && cd ..

# Lancer sur simulateur
flutter run -d "iPhone 14"

# Lister les simulateurs iOS
xcrun simctl list devices

# Ouvrir Xcode
open ios/Runner.xcworkspace
```

---

## 🤖 Android Spécifique

```bash
# Clean Gradle
cd android && ./gradlew clean && cd ..

# Build Gradle
cd android && ./gradlew build && cd ..

# Lister les devices Android
adb devices

# Installer l'APK manuellement
adb install build/app/outputs/flutter-apk/app-release.apk

# Logs Android
adb logcat

# Ouvrir Android Studio
open -a "Android Studio" android/
```

---

## 🎨 Assets et Génération

```bash
# Générer les icônes d'app
flutter pub run flutter_launcher_icons:main

# Générer le splash screen
flutter pub run flutter_native_splash:create

# Générer les fichiers (build_runner)
flutter pub run build_runner build

# Générer en mode watch
flutter pub run build_runner watch

# Générer en supprimant les conflits
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📖 Documentation

```bash
# Générer la documentation
dart doc

# Ouvrir la doc Flutter
flutter doctor --help

# Aide sur une commande
flutter run --help
flutter build --help

# Voir toutes les commandes
flutter --help
```

---

## 💡 Astuces Avancées

```bash
# Lancer avec options Dart VM
flutter run --enable-asserts

# Désactiver sound null safety (legacy)
flutter run --no-sound-null-safety

# Voir les performances de build
flutter build apk --verbose

# Profiling avancé
flutter run --profile --trace-skia --endless-trace-buffer

# Dump l'arbre de widgets
flutter run --dump-semantics-tree

# Observer les allocations mémoire
flutter run --profile --trace-systrace

# Lancer sans hot reload
flutter run --no-hot
```

---

## 🔄 CI/CD

```bash
# Build pour CI (pas d'interaction)
flutter build apk --no-sound-null-safety --release

# Tests en mode CI
flutter test --machine

# Analyse pour CI
flutter analyze --no-pub

# Version de l'app
flutter pub run build_runner build --release
```

---

## 🎯 Raccourcis Pendant flutter run

Pendant que l'app tourne :

```
r       Hot reload
R       Hot restart
h       Aide
p       Afficher la grille de debug
o       Changer orientation (portrait/landscape)
q       Quitter
s       Screenshot
w       Dump widget hierarchy
t       Dump rendering tree
L       Dump layer tree
S       Dump accessibility tree
U       Dump semantics tree
i       Toggle widget inspector
z       Toggle elevation overlay
```

---

## 📝 Variables d'Environnement

```bash
# Lancer avec variables d'env
flutter run --dart-define=ENV=production
flutter run --dart-define=API_URL=https://api.example.com

# Multiples variables
flutter run \
  --dart-define=ENV=prod \
  --dart-define=API_KEY=abc123 \
  --dart-define=DEBUG=false
```

---

## 🚨 Troubleshooting

```bash
# Reset total
flutter clean
flutter pub get
flutter pub cache repair
flutter doctor -v

# Problèmes de packages
rm -rf .dart_tool
rm -rf .packages
rm pubspec.lock
flutter pub get

# Problèmes iOS
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..

# Problèmes Android
cd android
./gradlew clean
cd ..
flutter clean

# Reconstruire les binaires Flutter
flutter precache --all-platforms
```

---

## 📱 Pour ce Projet Spécifique

```bash
# Setup complet
flutter pub get

# Lancer l'app
flutter run

# Lancer sur device spécifique
flutter devices
flutter run -d <device_id>

# Build Android release
flutter build apk --release

# Tests
flutter test

# Analyse
flutter analyze

# Format
flutter format lib/

# Clean
flutter clean && flutter pub get
```

---

## 🎓 Commandes Utiles au Quotidien

```bash
# Workflow de développement standard
flutter pub get           # Une fois au début
flutter run              # Lancer l'app
# ... développer avec hot reload ...
flutter analyze          # Vérifier le code
flutter format lib/      # Formater
flutter test            # Tests avant commit
```

---

**💡 Conseil :** Sauvegardez ce fichier comme référence rapide !

**📌 Bookmark cette page** pour y revenir facilement.
