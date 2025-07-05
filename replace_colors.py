import re
import os

# Mappage des couleurs vers les constantes
COLOR_MAPPING = {
    '0xFF4A90E2': 'AppTheme.primaryBlue',
    '0xFFD4EFFB': 'AppTheme.lightBlue',
    '0xFF4A4A4A': 'AppTheme.textPrimary',
    '0xFF29B6F6': 'AppTheme.secondaryBlue',
    '0xFFBFE6FB': 'AppTheme.lightBlueBorder',
    '0xFF2F6DF2': 'AppTheme.darkBlue',
    '0xFF62CEF5': 'AppTheme.lightCyan',
    '0xFFA855F7': 'AppTheme.accentPurple',
    '0xFFEC4899': 'AppTheme.accentPink',
    '0xFFEF4444': 'AppTheme.accentRed',
    '0xFF22C55E': 'AppTheme.successGreen',
    '0xFF8E44AD': 'AppTheme.primaryPurple',
    '0xFFF97316': 'AppTheme.accentOrange',
    '0xFF6366F1': 'AppTheme.accentIndigo',
    '0xFF06B6D4': 'AppTheme.accentCyan',
    '0xFF8E8E93': 'AppTheme.textSecondary',
    '0xFFF2F6FA': 'AppTheme.backgroundLight',
    '0xFFB0B0B0': 'AppTheme.dividerColor',
}

def replace_colors_in_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        modified = False
        
        # Vérifier si le fichier a déjà l'import du thème
        if 'app_theme' not in content.lower() and any(f'Color({code})' in content for code in COLOR_MAPPING):
            # Ajouter l'import en haut du fichier
            imports = []
            if "import 'package:flutter/material.dart';" not in content:
                imports.append("import 'package:flutter/material.dart';\n")
            if "import '../utils/app_theme.dart';" not in content:
                imports.append("import '../utils/app_theme.dart';\n")
            
            if imports:
                content = "".join(imports) + "\n" + content
            modified = True
        
        # Remplacer les couleurs
        for hex_code, constant in COLOR_MAPPING.items():
            pattern = re.compile(f'Color\(({re.escape(hex_code)})\)')
            if pattern.search(content):
                content = pattern.sub(constant, content)
                modified = True
        
        # Écrire les modifications si nécessaire
        if modified:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(content)
            print(f'✅ Modifié: {file_path}')
        else:
            print(f'ℹ️ Aucun changement: {file_path}')
            
    except Exception as e:
        print(f'❌ Erreur avec {file_path}: {str(e)}')

def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart') and not file.startswith('app_theme'):
                file_path = os.path.join(root, file)
                replace_colors_in_file(file_path)

if __name__ == '__main__':
    lib_dir = os.path.join(os.getcwd(), 'lib')
    print('🚀 Début du remplacement des couleurs...')
    process_directory(lib_dir)
    print('✅ Remplacement des couleurs terminé !')
