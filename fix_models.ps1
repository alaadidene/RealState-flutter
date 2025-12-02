# Script pour corriger automatiquement les conversions de type dans les modèles

Write-Host "🔧 Correction des modèles Dart..." -ForegroundColor Cyan

# Fonction pour ajouter des casts de type
function Fix-ModelFile {
    param($FilePath)
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        
        # Remplacements pour les conversions String
        $content = $content -replace "json\['([^']+)'\] \?\? ''", "(json['\$1'] ?? '') as String"
        $content = $content -replace "json\['\\\$id'\] \?\? ''", "(json['\\\$id'] ?? '') as String"
        
        # Remplacements pour les conversions int
        $content = $content -replace "json\['([^']+)'\] \?\? 0\)(?!\s*as)", "(json['\$1'] ?? 0) as int)"
        
        # Remplacements pour les conversions double
        $content = $content -replace "\(json\['([^']+)'\] \?\? 0\)\.toDouble\(\)", "((json['\$1'] ?? 0) as num).toDouble()"
        $content = $content -replace "json\['([^']+)'\]\?\.toDouble\(\)", "json['\$1'] != null ? ((json['\$1']) as num).toDouble() : null"
        
        # Remplacements pour les conversions bool
        $content = $content -replace "json\['([^']+)'\] \?\? (true|false)(?!\s*as)", "(json['\$1'] ?? \$2) as bool"
        
        # Remplacements pour les types nullable String
        $content = $content -replace "json\['([^']+)'\](?!\s*[?\.]|\s*as|\s*\?\?)([,\)])", "json['\$1'] as String?\$2"
        
        # Sauvegarder le fichier modifié
        Set-Content -Path $FilePath -Value $content -NoNewline
        Write-Host "  ✅ Corrigé: $FilePath" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Fichier non trouvé: $FilePath" -ForegroundColor Yellow
    }
}

# Liste des fichiers de modèles à corriger
$modelFiles = @(
    "lib\models\property_models.dart",
    "lib\models\messaging_models.dart",
    "lib\models\notification_models.dart"
)

foreach ($file in $modelFiles) {
    Fix-ModelFile -FilePath $file
}

Write-Host "`n✨ Correction terminée!" -ForegroundColor Green
Write-Host "📝 Exécutez 'flutter pub get' puis 'flutter analyze' pour vérifier." -ForegroundColor Cyan
