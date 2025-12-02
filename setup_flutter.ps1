# Script d'aide PowerShell pour démarrer le projet Flutter
# Real Estate App

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Real Estate App - Flutter Setup Helper" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si Flutter est installé
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "✅ Flutter est installé" -ForegroundColor Green
    Write-Host $flutterVersion
    Write-Host ""
} catch {
    Write-Host "❌ Flutter n'est pas installé !" -ForegroundColor Red
    Write-Host "📥 Installez Flutter depuis : https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

# Flutter Doctor
Write-Host "🔍 Vérification de l'environnement Flutter..." -ForegroundColor Yellow
flutter doctor
Write-Host ""

# Installer les dépendances
Write-Host "📦 Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
Write-Host ""

# Analyser le code
Write-Host "🔍 Analyse du code..." -ForegroundColor Yellow
flutter analyze
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ✅ Configuration terminée !" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Pour lancer l'application :" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Android:  flutter run -d android" -ForegroundColor White
Write-Host "   iOS:      flutter run -d ios" -ForegroundColor White
Write-Host "   Web:      flutter run -d chrome" -ForegroundColor White
Write-Host ""
Write-Host "💡 Commandes utiles :" -ForegroundColor Yellow
Write-Host ""
Write-Host "   flutter devices          - Voir les appareils disponibles" -ForegroundColor White
Write-Host "   flutter clean            - Nettoyer le build" -ForegroundColor White
Write-Host "   flutter pub get          - Réinstaller les dépendances" -ForegroundColor White
Write-Host "   flutter build apk        - Build Android" -ForegroundColor White
Write-Host "   flutter logs             - Voir les logs" -ForegroundColor White
Write-Host ""
