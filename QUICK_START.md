# 🚀 Quick Start Guide - Flutter Real Estate App

## Installation Ultra-Rapide

### Windows (PowerShell)

```powershell
# 1. Vérifier Flutter
flutter doctor

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'app
flutter run
```

Ou utilisez le script automatique :
```powershell
.\setup_flutter.ps1
```

### macOS / Linux (Terminal)

```bash
# 1. Vérifier Flutter
flutter doctor

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'app
flutter run
```

Ou utilisez le script automatique :
```bash
chmod +x setup_flutter.sh
./setup_flutter.sh
```

---

## 🎯 Premiers Pas

### 1. Choisir un Device

```bash
flutter devices
```

Vous verrez :
- 📱 Appareils Android connectés
- 📱 Simulateurs iOS (macOS uniquement)
- 🌐 Chrome (pour web)
- 💻 Windows/macOS/Linux desktop

### 2. Lancer sur un Device Spécifique

```bash
# Android
flutter run -d android

# iOS (macOS uniquement)
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

### 3. Hot Reload

Pendant que l'app tourne :
- Appuyez sur **`r`** pour Hot Reload (rapide)
- Appuyez sur **`R`** pour Hot Restart (redémarre l'app)
- Appuyez sur **`q`** pour quitter

---

## 📱 Créer un Émulateur Android

### Android Studio

1. Ouvrez Android Studio
2. Tools → Device Manager
3. Create Device
4. Choisissez un modèle (ex: Pixel 6)
5. Téléchargez une image système (Android 13 recommandé)
6. Finish

### Ligne de commande

```bash
# Lister les émulateurs
flutter emulators

# Lancer un émulateur
flutter emulators --launch <emulator_id>
```

---

## 🍎 Créer un Simulateur iOS (macOS uniquement)

```bash
# Lister les simulateurs disponibles
xcrun simctl list devices

# Créer un nouveau simulateur
xcrun simctl create "iPhone 14" "iPhone 14"

# Démarrer le simulateur
open -a Simulator
```

---

## 🔧 Problèmes Courants et Solutions

### ❌ "Flutter not found"

**Solution :**
```bash
# Vérifier que Flutter est dans le PATH
echo $PATH  # macOS/Linux
echo $env:PATH  # Windows PowerShell

# Ajouter Flutter au PATH si nécessaire
export PATH="$PATH:/path/to/flutter/bin"  # macOS/Linux
```

### ❌ "Android licenses not accepted"

**Solution :**
```bash
flutter doctor --android-licenses
# Appuyez sur 'y' pour accepter toutes les licences
```

### ❌ "No devices found"

**Solution :**
```bash
# Vérifier les devices
flutter devices

# Si vide, démarrer un émulateur
flutter emulators --launch <emulator_id>
```

### ❌ "Gradle build failed" (Android)

**Solution :**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### ❌ "Pod install failed" (iOS)

**Solution :**
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..
flutter run
```

### ❌ "Package not found"

**Solution :**
```bash
flutter clean
rm -rf .dart_tool
flutter pub get
```

---

## 🎨 Structure du Projet

```
lib/
├── main.dart              # ← Commencez ici
├── core/                  # Configuration
├── models/                # Modèles de données
├── providers/             # État global (Riverpod)
├── services/              # API Appwrite
├── screens/               # Pages de l'app
└── widgets/               # Composants réutilisables
```

---

## 🔑 Comptes de Test

L'écran de connexion affiche les identifiants de démo :

```
Email: demo@example.com
Password: demo123
```

> **Note :** Ces comptes doivent être créés dans votre console Appwrite.

---

## 📦 Build de Production

### Android APK

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

Fichier : `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Fichier : `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

Ouvrez ensuite Xcode pour signer et uploader sur TestFlight/App Store.

### Web

```bash
flutter build web --release
```

Fichiers : `build/web/`

---

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests avec coverage
flutter test --coverage

# Analyser le code
flutter analyze

# Formater le code
flutter format lib/
```

---

## 📊 Performance

### Mode Profile

```bash
flutter run --profile
```

Utilisez ensuite Flutter DevTools pour analyser les performances.

### DevTools

```bash
# Installer DevTools
flutter pub global activate devtools

# Lancer DevTools
flutter pub global run devtools
```

### Analyser la Taille de l'App

```bash
flutter build apk --analyze-size
```

---

## 🔍 Debugging

### Logs en Temps Réel

```bash
flutter logs
```

### Debug avec VS Code

1. Ouvrez le projet dans VS Code
2. Installez l'extension "Flutter"
3. Appuyez sur **F5** pour démarrer en mode debug

### Debug avec Android Studio

1. Ouvrez le projet dans Android Studio
2. Sélectionnez un device
3. Cliquez sur le bouton Debug (🐞)

---

## 💡 Astuces Pro

### 1. Nettoyer le Projet

```bash
flutter clean && flutter pub get
```

### 2. Voir les Packages Obsolètes

```bash
flutter pub outdated
```

### 3. Mettre à Jour les Packages

```bash
flutter pub upgrade
```

### 4. Vérifier les Problèmes

```bash
flutter doctor -v
```

### 5. Hot UI Update

Modifiez un fichier dans `lib/` et sauvegardez. Le Hot Reload est automatique !

---

## 📚 Documentation Utile

- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Riverpod](https://riverpod.dev)
- [GoRouter](https://pub.dev/packages/go_router)
- [Appwrite Flutter](https://appwrite.io/docs/getting-started-for-flutter)

---

## 🎯 Prochaines Étapes

1. ✅ Lancez l'app : `flutter run`
2. ✅ Testez la navigation entre les tabs
3. ✅ Testez la recherche et les filtres
4. ✅ Testez les favoris
5. ✅ Explorez le code dans `lib/`

---

## 🆘 Besoin d'Aide ?

### Commandes de Diagnostic

```bash
# Tout vérifier
flutter doctor -v

# Version Flutter
flutter --version

# Devices disponibles
flutter devices

# Packages installés
flutter pub deps
```

### Reset Complet

Si rien ne fonctionne :

```bash
flutter clean
rm -rf .dart_tool
rm pubspec.lock
flutter pub get
flutter run
```

---

## ✅ Checklist de Démarrage

- [ ] Flutter installé et dans le PATH
- [ ] `flutter doctor` ne montre pas d'erreur critique
- [ ] Un device (émulateur/simulateur/physique) disponible
- [ ] `flutter pub get` exécuté avec succès
- [ ] `.env` configuré avec vos clés Appwrite
- [ ] `flutter run` démarre l'application

---

**🎉 Vous êtes prêt ! Bon développement avec Flutter !**

```bash
flutter run
```
