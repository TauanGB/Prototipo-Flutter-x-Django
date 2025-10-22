#!/bin/bash

# Script de Setup para iOS - Projeto Flutter
# Este script automatiza a preparação do projeto para iOS

set -e  # Para em caso de erro

echo "🚀 Iniciando setup do projeto para iOS..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cor
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verificar se está no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    print_error "Este script deve ser executado na pasta 'frontend' do projeto!"
    exit 1
fi

print_info "Diretório correto detectado."
echo ""

# 1. Verificar Flutter
echo "📦 Verificando instalação do Flutter..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter não encontrado! Instale o Flutter primeiro."
    exit 1
fi
print_success "Flutter instalado: $(flutter --version | head -n 1)"
echo ""

# 2. Verificar CocoaPods
echo "🍫 Verificando instalação do CocoaPods..."
if ! command -v pod &> /dev/null; then
    print_warning "CocoaPods não encontrado!"
    print_info "Instalando CocoaPods..."
    sudo gem install cocoapods
    print_success "CocoaPods instalado!"
else
    print_success "CocoaPods instalado: $(pod --version)"
fi
echo ""

# 3. Limpar builds anteriores
echo "🧹 Limpando builds anteriores..."
flutter clean
print_success "Build limpo!"
echo ""

# 4. Obter dependências Flutter
echo "📥 Obtendo dependências do Flutter..."
flutter pub get
print_success "Dependências obtidas!"
echo ""

# 5. Verificar se Podfile existe
if [ ! -f "ios/Podfile" ]; then
    print_error "Podfile não encontrado em ios/!"
    print_info "O Podfile deveria ter sido criado pela análise."
    exit 1
fi
print_success "Podfile encontrado!"
echo ""

# 6. Instalar pods do iOS
echo "📲 Instalando pods do iOS (pode demorar alguns minutos)..."
cd ios
rm -rf Pods Podfile.lock  # Limpa instalação anterior
pod repo update  # Atualiza repositório de pods
pod install
cd ..
print_success "Pods instalados!"
echo ""

# 7. Verificar dispositivos iOS disponíveis
echo "📱 Verificando dispositivos iOS disponíveis..."
flutter devices
echo ""

# 8. Instruções finais
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Setup concluído com sucesso!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "Próximos passos:"
echo ""
echo "1️⃣  Abrir projeto no Xcode:"
echo "   $ open ios/Runner.xcworkspace"
echo ""
echo "2️⃣  No Xcode, configurar:"
echo "   - Signing & Capabilities > Team (selecionar sua conta Apple)"
echo "   - General > Bundle Identifier (mudar para algo único)"
echo ""
echo "3️⃣  Configurar API no app:"
echo "   - Descobrir seu IP local"
echo "   - Rodar Django: python manage.py runserver 0.0.0.0:8000"
echo "   - No app: Configurações > Host > [SEU_IP]"
echo ""
echo "4️⃣  Executar:"
echo "   $ flutter run -d ios"
echo ""
print_warning "IMPORTANTE: No iOS real, não use 127.0.0.1 - use seu IP da rede local!"
echo ""
print_info "Leia GUIA_RAPIDO_IOS.md para instruções detalhadas."
echo ""








