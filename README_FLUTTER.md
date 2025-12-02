# Real Estate App - Flutter Version

Application immobilière Flutter complète avec Appwrite backend, convertie depuis React Native.

## 🚀 Fonctionnalités

### ✅ Authentification
- Connexion / Inscription avec email et mot de passe
- Gestion de session utilisateur
- Profil utilisateur personnalisable

### 🏠 Propriétés
- Liste et recherche de propriétés
- Filtres par catégorie (location/vente)
- Détails complets des propriétés
- Images multiples en galerie
- Création de nouvelles propriétés
- Géolocalisation et cartes

### ⭐ Favoris
- Ajout/suppression de favoris
- Synchronisation en temps réel
- Liste personnalisée de propriétés favorites

### 💬 Messagerie
- Chat en temps réel
- Conversations avec agents immobiliers
- Envoi de messages texte et images
- Indicateur de saisie en cours

### 📅 Réservations
- Système de réservation complet
- Gestion des demandes de réservation
- Calendrier de disponibilité
- Statuts de réservation (en attente, confirmé, annulé)

### 💳 Paiements
- Intégration système de paiement
- Historique des transactions
- Gestion des remboursements

### ⭐ Avis et Notes
- Système d'évaluation des propriétés
- Commentaires des utilisateurs
- Notation par étoiles (1-5)
- Likes sur les avis

### 🔔 Notifications
- Notifications push
- Centre de notifications
- Préférences de notifications personnalisables
- Notifications par catégorie

## 📋 Prérequis

- Flutter SDK (>=3.2.0)
- Dart SDK
- Android Studio / Xcode
- Compte Appwrite configuré

## 🛠️ Installation

### 1. Cloner le projet

```bash
cd Real_Estate_App
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Configuration Appwrite

Le fichier `.env` existe déjà avec les configurations Appwrite :

```env
EXPO_PUBLIC_APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1
EXPO_PUBLIC_APPWRITE_PROJECT_ID=votre_project_id
EXPO_PUBLIC_APPWRITE_DATABASE_ID=votre_database_id
# ... autres configurations
```

### 4. Lancer l'application

#### Android
```bash
flutter run
```

#### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

#### Web
```bash
flutter run -d chrome
```

## 📁 Structure du Projet

```
lib/
├── main.dart                  # Point d'entrée de l'app
├── core/                      # Configuration et utilitaires
│   ├── config/
│   │   └── env_config.dart   # Variables d'environnement
│   ├── router/
│   │   └── app_router.dart   # Navigation (GoRouter)
│   └── theme/
│       └── app_theme.dart    # Thème de l'application
├── models/                    # Modèles de données
│   ├── property_models.dart
│   ├── booking_models.dart
│   ├── messaging_models.dart
│   └── notification_models.dart
├── providers/                 # Gestion d'état (Riverpod)
│   ├── auth_provider.dart
│   ├── properties_provider.dart
│   └── favorites_provider.dart
├── services/                  # Services API
│   └── appwrite_service.dart # Client Appwrite
├── screens/                   # Écrans de l'app
│   ├── auth/
│   ├── home/
│   ├── property/
│   ├── bookings/
│   ├── messages/
│   ├── notifications/
│   └── profile/
└── widgets/                   # Widgets réutilisables
    ├── property_card.dart
    ├── search_bar_widget.dart
    └── filter_chips.dart
```

## 🔄 Migration React Native → Flutter

### Conversions principales

| React Native | Flutter |
|-------------|---------|
| React Hooks | Riverpod Providers |
| useState | StateNotifier |
| useEffect | initState / dispose |
| Context API | Provider/Riverpod |
| Expo Router | GoRouter |
| StyleSheet | ThemeData |
| FlatList | ListView / GridView |
| Appwrite SDK (JS) | Appwrite SDK (Dart) |

### Composants convertis

- ✅ PropertyCard → PropertyCard (Widget)
- ✅ SearchBar → SearchBarWidget
- ✅ Filters → FilterChips
- ✅ FavoriteButton → Intégré dans PropertyCard
- ✅ Navigation → GoRouter + Bottom Navigation

## 🎨 Thème et Design

L'application utilise :
- **Material Design 3**
- **Google Fonts** (Rubik)
- **Palette de couleurs** identique à l'app React Native
- **Composants personnalisés** avec le même look & feel

## 🔐 Authentification

```dart
// Connexion
await ref.read(authProvider.notifier).signIn(
  email: 'user@example.com',
  password: 'password',
);

// Déconnexion
await ref.read(authProvider.notifier).signOut();
```

## 📊 Gestion d'état

L'application utilise **Riverpod** pour la gestion d'état :

```dart
// Lecture d'état
final propertiesState = ref.watch(propertiesProvider);

// Modification d'état
ref.read(propertiesProvider.notifier).setFilter('rent');

// Provider async
final property = ref.watch(propertyByIdProvider(id));
```

## 🌐 API Appwrite

Toutes les opérations Appwrite sont centralisées dans `AppwriteService` :

```dart
final appwrite = AppwriteService();

// Récupérer les propriétés
final properties = await appwrite.getProperties();

// Ajouter aux favoris
await appwrite.addToFavorites(
  userId: userId,
  propertyId: propertyId,
);
```

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter drive --target=test_driver/app.dart
```

## 📦 Build de production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🔧 Dépendances principales

- **flutter_riverpod** - Gestion d'état
- **go_router** - Navigation
- **appwrite** - Backend as a Service
- **google_maps_flutter** - Cartes et géolocalisation
- **cached_network_image** - Cache d'images
- **google_fonts** - Polices personnalisées
- **image_picker** - Sélection d'images
- **shared_preferences** - Stockage local

## 📝 Notes de migration

### Différences avec React Native

1. **Gestion d'état** : Riverpod remplace Context + useState
2. **Navigation** : GoRouter au lieu d'Expo Router
3. **Styles** : ThemeData au lieu de StyleSheet
4. **Composants** : Widgets Flutter natifs
5. **Async/Await** : Même syntaxe mais avec FutureProvider

### Améliorations Flutter

- ✅ Performance native supérieure
- ✅ Hot reload ultra-rapide
- ✅ Meilleure gestion de la mémoire
- ✅ Typage fort avec Dart
- ✅ Widgets Material et Cupertino intégrés

## 🐛 Débogage

```bash
# Logs en temps réel
flutter logs

# Analyser les performances
flutter run --profile

# Mode debug avec DevTools
flutter run --observatory-port=8080
```

## 📱 Plateformes supportées

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Windows (à configurer)
- ✅ macOS (à configurer)
- ✅ Linux (à configurer)

## 🤝 Contribution

L'application est une conversion complète de React Native vers Flutter en conservant :
- La même logique métier
- Les mêmes fonctionnalités
- Le même design UI/UX
- La même base de données Appwrite

## 📄 Licence

Ce projet est une conversion de l'application React Native existante.

## 🆘 Support

Pour toute question sur la migration ou l'utilisation :
1. Consulter la documentation Flutter : https://flutter.dev/docs
2. Documentation Appwrite : https://appwrite.io/docs
3. Documentation Riverpod : https://riverpod.dev

---

**Version Flutter** : Conversion complète de React Native vers Flutter
**Maintient la compatibilité** avec la même base de données Appwrite
