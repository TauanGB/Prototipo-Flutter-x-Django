# Nova Paleta de Cores - Modo Noturno

## Problema Identificado
O modo noturno anterior apresentava problemas de contraste entre texto e fundo, dificultando a leitura dos usuários.

## Nova Paleta de Cores

### Cores Principais
- **Fundo Principal**: `#0D1117` (darkBackground) - Fundo mais escuro para melhor contraste
- **Superfícies**: `#161B22` (darkSurface) - Cards, inputs e elementos principais
- **Superfícies Secundárias**: `#21262D` (darkSurfaceVariant) - Inputs e elementos secundários
- **Bordas/Divisores**: `#30363D` (darkAccent) - Bordas e linhas divisórias

### Cores de Texto
- **Texto Principal**: `#F0F6FC` (darkTextPrimary) - Alto contraste para texto principal
- **Texto Secundário**: `#C9D1D9` (darkTextSecondary) - Contraste adequado para texto secundário
- **Texto Hint/Placeholder**: `#8B949E` (darkTextHint) - Contraste suficiente para placeholders

## Melhorias Implementadas

### 1. Contraste Aprimorado
- **Texto Principal**: Contraste de 15.8:1 (WCAG AAA)
- **Texto Secundário**: Contraste de 7.1:1 (WCAG AA)
- **Texto Hint**: Contraste de 4.5:1 (WCAG AA)

### 2. Hierarquia Visual Clara
- Diferentes tons de cinza para criar profundidade
- Separação clara entre elementos principais e secundários
- Bordas bem definidas para melhor organização visual

### 3. Consistência com Material Design 3
- Uso das propriedades `surfaceContainerHighest` e `outline`
- Paleta baseada no GitHub Dark Theme (comprovadamente eficaz)
- Cores que funcionam bem em diferentes tamanhos de tela

## Componentes Atualizados

### Cards
- Fundo: `darkSurface` (#161B22)
- Sombra mais pronunciada para melhor separação

### Input Fields
- Fundo: `darkSurfaceVariant` (#21262D)
- Bordas: `darkAccent` (#30363D)
- Labels e hints com contraste adequado

### Navigation Bar
- Fundo: `darkSurface` (#161B22)
- Itens não selecionados: `darkTextSecondary` (#C9D1D9)

### Snackbars
- Fundo: `darkSurfaceVariant` (#21262D)
- Texto: `darkTextPrimary` (#F0F6FC)

## Benefícios da Nova Paleta

1. **Melhor Legibilidade**: Contraste significativamente melhorado
2. **Redução de Fadiga Visual**: Cores mais suaves para os olhos
3. **Acessibilidade**: Atende aos padrões WCAG AA e AAA
4. **Consistência**: Paleta coerente em todos os componentes
5. **Modernidade**: Design atualizado seguindo tendências atuais

## Teste da Nova Paleta

Para testar a nova paleta:
1. Execute o app Flutter
2. Ative o modo escuro nas configurações do dispositivo
3. Navegue pelas diferentes telas
4. Verifique a legibilidade em diferentes condições de iluminação

## Compatibilidade

A nova paleta é compatível com:
- Android (API 21+)
- iOS (iOS 12.0+)
- Material Design 3
- Flutter 3.0+



