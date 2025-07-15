#!/usr/bin/env python3
"""
Script pour générer automatiquement toutes les icônes d'application
à partir de l'icône source leSmenu.png
"""

import os
import sys
from PIL import Image, ImageOps
import subprocess

def ensure_pillow():
    """Vérifie et installe Pillow si nécessaire"""
    try:
        from PIL import Image
    except ImportError:
        print("Installation de Pillow...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
        from PIL import Image

def create_icon(source_path, output_path, size, format='PNG', background_color=None):
    """Crée une icône avec la taille spécifiée"""
    try:
        # Ouvrir l'image source
        with Image.open(source_path) as img:
            # Convertir en RGBA si nécessaire
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            # Redimensionner en gardant les proportions
            img.thumbnail((size, size), Image.Resampling.LANCZOS)
            
            # Créer une nouvelle image avec la taille exacte
            new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            
            # Centrer l'image
            paste_x = (size - img.width) // 2
            paste_y = (size - img.height) // 2
            new_img.paste(img, (paste_x, paste_y))
            
            # Si un fond est spécifié, l'appliquer
            if background_color:
                background = Image.new('RGBA', (size, size), background_color)
                background.paste(new_img, (0, 0), new_img)
                new_img = background
            
            # Créer le dossier de sortie si nécessaire
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            
            # Sauvegarder
            if format.upper() == 'ICO':
                new_img.save(output_path, format='ICO', sizes=[(size, size)])
            else:
                new_img.save(output_path, format=format)
            
            print(f"✓ Créé: {output_path} ({size}x{size})")
            
    except Exception as e:
        print(f"✗ Erreur lors de la création de {output_path}: {e}")

def generate_android_icons(source_path):
    """Génère les icônes Android"""
    print("\n=== Génération des icônes Android ===")
    
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    for folder, size in android_sizes.items():
        output_path = f"android/app/src/main/res/{folder}/ic_launcher.png"
        create_icon(source_path, output_path, size)

def generate_ios_icons():
    # Source image
    source_path = "assets/images/icone1.jpg"
    output_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    
    # iOS icon sizes (name, width, height)
    icon_sizes = [
        ("Icon-App-20x20@1x.png", 20, 20),
        ("Icon-App-20x20@2x.png", 40, 40),
        ("Icon-App-20x20@3x.png", 60, 60),
        ("Icon-App-29x29@1x.png", 29, 29),
        ("Icon-App-29x29@2x.png", 58, 58),
        ("Icon-App-29x29@3x.png", 87, 87),
        ("Icon-App-40x40@1x.png", 40, 40),
        ("Icon-App-40x40@2x.png", 80, 80),
        ("Icon-App-40x40@3x.png", 120, 120),
        ("Icon-App-60x60@2x.png", 120, 120),
        ("Icon-App-60x60@3x.png", 180, 180),
        ("Icon-App-76x76@1x.png", 76, 76),
        ("Icon-App-76x76@2x.png", 152, 152),
        ("Icon-App-83.5x83.5@2x.png", 167, 167),
        ("Icon-App-1024x1024@1x.png", 1024, 1024),
    ]
    
    # Open source image
    with Image.open(source_path) as img:
        # Convert to RGB to remove any alpha channel
        if img.mode in ('RGBA', 'LA', 'P'):
            # Create white background
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = background
        elif img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Generate each icon size
        for filename, width, height in icon_sizes:
            output_path = os.path.join(output_dir, filename)
            
            # Resize image
            resized = img.resize((width, height), Image.Resampling.LANCZOS)
            
            # Save as PNG without alpha channel
            resized.save(output_path, 'PNG', optimize=True)
            print(f"Generated: {filename} ({width}x{height})")

def generate_macos_icons(source_path):
    """Génère les icônes macOS"""
    print("\n=== Génération des icônes macOS ===")
    
    macos_sizes = {
        'app_icon_16.png': 16,
        'app_icon_32.png': 32,
        'app_icon_64.png': 64,
        'app_icon_128.png': 128,
        'app_icon_256.png': 256,
        'app_icon_512.png': 512,
        'app_icon_1024.png': 1024
    }
    
    for filename, size in macos_sizes.items():
        output_path = f"macos/Runner/Assets.xcassets/AppIcon.appiconset/{filename}"
        create_icon(source_path, output_path, size)

def generate_web_icons(source_path):
    """Génère les icônes Web"""
    print("\n=== Génération des icônes Web ===")
    
    web_sizes = {
        'Icon-192.png': 192,
        'Icon-512.png': 512,
        'Icon-maskable-192.png': 192,
        'Icon-maskable-512.png': 512
    }
    
    for filename, size in web_sizes.items():
        output_path = f"web/icons/{filename}"
        create_icon(source_path, output_path, size)

def generate_windows_icon(source_path):
    """Génère l'icône Windows"""
    print("\n=== Génération de l'icône Windows ===")
    
    # Windows utilise une icône ICO avec plusieurs tailles
    output_path = "windows/runner/resources/app_icon.ico"
    
    try:
        # Créer une icône avec plusieurs tailles
        sizes = [16, 32, 48, 64, 128, 256]
        images = []
        
        with Image.open(source_path) as img:
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            for size in sizes:
                # Redimensionner
                resized = img.copy()
                resized.thumbnail((size, size), Image.Resampling.LANCZOS)
                
                # Créer une nouvelle image avec la taille exacte
                new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
                paste_x = (size - resized.width) // 2
                paste_y = (size - resized.height) // 2
                new_img.paste(resized, (paste_x, paste_y))
                images.append(new_img)
        
        # Sauvegarder en format ICO
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        images[0].save(output_path, format='ICO', sizes=[(size, size) for size in sizes])
        print(f"✓ Créé: {output_path} (multi-tailles)")
        
    except Exception as e:
        print(f"✗ Erreur lors de la création de {output_path}: {e}")

def update_pubspec_assets():
    """Met à jour le pubspec.yaml pour inclure la nouvelle icône"""
    print("\n=== Mise à jour du pubspec.yaml ===")
    
    pubspec_path = "pubspec.yaml"
    
    try:
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Vérifier si l'icône est déjà dans les assets
        if 'assets/images/icone1.jpg' not in content:
            # Ajouter l'icône aux assets
            assets_section = "  assets:\n    - assets/images/\n    - assets/sounds/\n    - assets/animations/\n    - assets/images/icone1.jpg\n    - assets/images/instagram.png"
            content = content.replace("  assets:\n    - assets/images/\n    - assets/sounds/\n    - assets/animations/\n    - assets/images/instagram.png", assets_section)
            
            with open(pubspec_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print("✓ Ajouté icone1.jpg aux assets du pubspec.yaml")
        else:
            print("✓ icone1.jpg est déjà dans les assets")
            
    except Exception as e:
        print(f"✗ Erreur lors de la mise à jour du pubspec.yaml: {e}")

def main():
    """Fonction principale"""
    print("🚀 Génération des icônes d'application Smooth AI")
    print("=" * 50)
    
    # Vérifier Pillow
    ensure_pillow()
    
    # Chemin vers l'icône source
    source_path = "assets/images/icone1.jpg"
    
    # Vérifier que l'icône source existe
    if not os.path.exists(source_path):
        print(f"✗ Erreur: L'icône source {source_path} n'existe pas!")
        print("Assurez-vous que icone1.jpg est dans le dossier assets/images/")
        return
    
    print(f"✓ Icône source trouvée: {source_path}")
    
    # Générer toutes les icônes
    generate_android_icons(source_path)
    generate_ios_icons()
    generate_macos_icons(source_path)
    generate_web_icons(source_path)
    generate_windows_icon(source_path)
    
    # Mettre à jour le pubspec.yaml
    update_pubspec_assets()
    
    print("\n" + "=" * 50)
    print("✅ Génération des icônes terminée!")
    print("\n📱 Prochaines étapes:")
    print("1. Exécutez 'flutter clean'")
    print("2. Exécutez 'flutter pub get'")
    print("3. Testez votre application sur différentes plateformes")
    print("\n🎨 Vos icônes sont maintenant prêtes pour toutes les plateformes!")

if __name__ == "__main__":
    main() 