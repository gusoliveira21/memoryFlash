#!/usr/bin/env python3
"""
Script para gerar ícone PNG a partir do SVG
Requer: pip install cairosvg pillow
"""

try:
    import cairosvg
    from PIL import Image
    import io
    
    # Converter SVG para PNG
    png_data = cairosvg.svg2png(url='assets/icon/app_icon.svg', output_width=1024, output_height=1024)
    
    # Salvar PNG
    with open('assets/icon/app_icon.png', 'wb') as f:
        f.write(png_data)
    
    print("Ícone gerado com sucesso em assets/icon/app_icon.png")
except ImportError:
    print("Instalando dependências...")
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "cairosvg", "pillow"])
    print("Por favor, execute o script novamente.")
except Exception as e:
    print(f"Erro: {e}")
    print("\nAlternativa: Use uma ferramenta online como:")
    print("https://convertio.co/svg-png/")
    print("ou")
    print("https://cloudconvert.com/svg-to-png")
    print("para converter assets/icon/app_icon.svg para PNG 1024x1024")

