# 🚀 Guia Rápido - Executar App no iOS

## ⚡ Passos Essenciais (NA ORDEM)

### 1️⃣ Instalar Dependências do iOS
```bash
cd frontend/ios
pod install
cd ..
```

**AGUARDE:** Isso pode levar alguns minutos na primeira vez.

---

### 2️⃣ Abrir Projeto no Xcode
```bash
open ios/Runner.xcworkspace
```

**⚠️ IMPORTANTE:** Abra o arquivo `.xcworkspace` e NÃO o `.xcodeproj`!

---

### 3️⃣ Configurar no Xcode

#### a) Selecionar Target
- Clique em "Runner" na barra lateral esquerda (ícone azul)

#### b) Signing & Capabilities
1. Vá na aba "Signing & Capabilities"
2. Em "Team", selecione sua conta de desenvolvedor Apple
   - Se não tiver, clique em "Add Account..." e faça login
3. O Bundle Identifier será algo como: `com.example.frontend`
   - **MUDE para algo único**, ex: `com.seudominio.motorista`

#### c) Background Modes
1. Ainda em "Signing & Capabilities"
2. Clique no botão "+ Capability"
3. Adicione "Background Modes"
4. Marque as opções:
   - ✅ Location updates
   - ✅ Background fetch
   - ✅ Background processing

#### d) Deployment Target
1. Em "General"
2. Deployment Info > iOS: **12.0** ou superior

---

### 4️⃣ Configurar IP da API

**⚠️ PROBLEMA:** No iOS real, `127.0.0.1` NÃO funciona!

#### Descobrir seu IP local:

**No Windows (PowerShell):**
```powershell
ipconfig
```
Procure por "Endereço IPv4" na sua conexão Wi-Fi/Ethernet (ex: 192.168.1.100)

**No Mac/Linux:**
```bash
ifconfig | grep "inet "
```

#### Configurar Django:
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

#### No App Flutter:
- Abra o app
- Clique no ícone de configurações (⚙️)
- Configure:
  - Host: `SEU_IP_LOCAL` (ex: 192.168.1.100)
  - Porta: `8000`
  - Protocolo: `http`
  - Caminho: `/api/v1`
- Clique em "Testar Conexão"
- Se OK, clique em "Salvar"

---

### 5️⃣ Executar no Dispositivo/Simulador

#### Opção A: Simulador iOS
1. No Xcode, selecione um simulador no menu superior (ex: iPhone 15)
2. Clique no botão Play (▶️)

**OU via terminal:**
```bash
flutter run -d ios
```

#### Opção B: Dispositivo Real
1. Conecte seu iPhone/iPad via cabo
2. Confie no computador no dispositivo
3. No Xcode, selecione seu dispositivo no menu superior
4. Clique no botão Play (▶️)

**Primeira vez:** O Xcode instalará alguns componentes no dispositivo.

---

### 6️⃣ Permitir Permissões

Quando o app abrir no iPhone:

1. **Notificações:** Permitir
2. **Localização:** 
   - Primeira pergunta: "Permitir Enquanto Uso o App" ✅
   - Para background: Vá em **Ajustes > Privacidade > Localização > [Seu App]** e mude para "**Sempre**"

---

## 🐛 Problemas Comuns

### Erro: "CocoaPods could not find compatible versions"
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod repo update
pod install
cd ..
```

### Erro: "No Development Team"
- Vá em Xcode > Preferences > Accounts
- Adicione sua conta Apple
- Volte em Signing & Capabilities e selecione o Team

### Erro: "Unable to install..."
- No iPhone: Ajustes > Geral > VPN e Gerenc. de Dispositivos
- Confie no desenvolvedor

### App instala mas não abre
- Verifique o console do Xcode (View > Debug Area > Show Debug Area)
- Procure por erros em vermelho

### Localização não funciona
1. Verifique se permitiu no app
2. Verifique: Ajustes > Privacidade > Serviços de Localização (deve estar ON)
3. Verifique: Ajustes > Privacidade > Localização > [Seu App] (deve estar "Sempre" para background)

### API não conecta
1. iPhone e computador na **MESMA rede Wi-Fi**
2. Firewall do Windows pode estar bloqueando
3. Django rodando com `0.0.0.0:8000` (não `127.0.0.1`)
4. Testar no navegador do iPhone: `http://SEU_IP:8000/api/v1/`

---

## 📝 Checklist de Teste

### Testes Básicos:
- [ ] App abre sem crashar
- [ ] Botões respondem
- [ ] Consegue obter localização manualmente
- [ ] Consegue enviar localização para API

### Testes de Localização:
- [ ] Permissão "Quando em Uso" funciona
- [ ] Latitude/Longitude aparecem corretos
- [ ] Envio manual de localização funciona
- [ ] Serviço automático funciona (foreground)

### Testes de Background:
- [ ] Serviço de background inicia
- [ ] App envia localização com tela travada
- [ ] App envia localização após reabrir
- [ ] Notificações aparecem

### Testes de API:
- [ ] Conexão com backend funciona
- [ ] Dados aparecem no Django Admin
- [ ] Erros de rede são tratados graciosamente

---

## 🎯 Comandos Úteis

```bash
# Ver dispositivos disponíveis
flutter devices

# Executar no simulador iOS
flutter run -d "iPhone 15"

# Build release para dispositivo
flutter build ios --release

# Limpar tudo e reconstruir
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get

# Ver logs em tempo real
flutter logs

# Analisar código
flutter analyze
```

---

## 📱 Sobre Background Location no iOS

### ⚠️ Limitações do iOS:

O iOS **NÃO permite** background execution contínuo como Android:

- **Com o app aberto:** Funciona 100%
- **Com o app em background (multitarefa):** Funciona por ~3 minutos
- **Com o app fechado/suspenso:** iOS acorda o app ocasionalmente
- **Com o app terminado:** Não funciona (usuário precisa abrir)

### 💡 Dicas:

1. **Para testes:** Deixe o app aberto (em foreground)
2. **Para produção:** Explique ao usuário que background no iOS é limitado
3. **Alternativa:** Use `Significant Location Changes` (menos preciso, mas funciona melhor em background)

### 🔋 Consumo de Bateria:

- Location contínuo consome **muita bateria**
- Apple pode **rejeitar** apps que consomem bateria excessivamente
- Considere usar location apenas quando necessário

---

## ℹ️ Informações Adicionais

### Versões de iOS Suportadas:
- **Mínima:** iOS 12.0
- **Recomendada:** iOS 13.0+
- **Testada:** iOS 17.0

### Dispositivos Testados:
- [ ] iPhone (especifique modelo)
- [ ] iPad (especifique modelo)
- [x] Simulador iOS

### Conhecidos Problemas:
- Background service no iOS é limitado pelo sistema operacional
- Location "Always" requer aprovação manual do usuário nas configurações
- Simulador iOS pode não comportar-se exatamente como dispositivo real

---

## 🆘 Precisa de Ajuda?

1. Verifique o arquivo `ANALISE_IOS.md` para análise completa
2. Verifique os logs: `flutter logs`
3. Verifique o console do Xcode
4. Procure erros específicos na documentação do Flutter

---

**Boa sorte! 🍀**


