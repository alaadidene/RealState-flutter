#!/bin/bash

# Script d'aide pour démarrer le projet Flutter
# Real Estate App

echo "============================================"
echo "  Real Estate App - Flutter Setup Helper"
echo "============================================"
echo ""

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter n'est pas installé !"
    echo "📥 Installez Flutter depuis : https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter est installé"
flutter --version
echo ""

# Flutter Doctor
echo "🔍 Vérification de l'environnement Flutter..."
flutter doctor
echo ""

# Installer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get
echo ""

# Analyser le code
echo "🔍 Analyse du code..."
flutter analyze
echo ""

echo "============================================"
echo "  ✅ Configuration terminée !"
echo "============================================"
echo ""
echo "🚀 Pour lancer l'application :"
echo ""
echo "   Android:  flutter run -d android"
echo "   iOS:      flutter run -d ios"
echo "   Web:      flutter run -d chrome"
echo ""
echo "💡 Commandes utiles :"
echo ""
echo "   flutter devices          - Voir les appareils disponibles"
echo "   flutter clean            - Nettoyer le build"
echo "   flutter pub get          - Réinstaller les dépendances"
echo "   flutter build apk        - Build Android"
echo "   flutter logs             - Voir les logs"
echo ""
