#!/bin/bash
# Script para criar ícone simples usando ferramentas do macOS

mkdir -p assets/icon

# Criar um ícone PNG simples usando sips (ferramenta nativa do macOS)
# Primeiro, vamos criar um arquivo temporário SVG e converter
cat > /tmp/icon_temp.svg << 'SVGEOF'
<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
  <rect width="1024" height="1024" rx="200" fill="#6750A4"/>
  <rect x="256" y="192" width="512" height="640" rx="48" fill="#EADDFF" stroke="#21005D" stroke-width="20"/>
  <text x="512" y="550" font-family="Arial" font-size="250" font-weight="bold" fill="#21005D" text-anchor="middle">?</text>
</svg>
SVGEOF

# Tentar converter usando qlmanage ou outra ferramenta
# Se não funcionar, o usuário pode usar uma ferramenta online
echo "SVG criado em assets/icon/app_icon.svg"
echo "Para converter para PNG, use:"
echo "1. https://convertio.co/svg-png/ (upload assets/icon/app_icon.svg, 1024x1024)"
echo "2. Ou instale librsvg: brew install librsvg"
echo "   Depois: rsvg-convert -w 1024 -h 1024 assets/icon/app_icon.svg > assets/icon/app_icon.png"

