# Kolt ESP Library 🚀

![Kolt ESP Banner](https://via.placeholder.com/1200x300?text=Kolt+ESP+V1.1)  
*(Imagine um banner épico aqui com tracers e highlights piscando – contribua com um se quiser!)*

Bem-vindo ao **Kolt ESP Library**! Essa é uma biblioteca Lua minimalista, eficiente e responsiva projetada para Roblox, focada em adicionar funcionalidades de ESP (Extra Sensory Perception) a modelos e partes no jogo. Se você é um dev Roblox que quer destacar entidades, rastrear jogadores ou criar hacks visuais imersivos, o Kolt é o seu companheiro perfeito. 

Criado por **DH_SOARES**, com um estilo clean e performático, o Kolt transforma o seu jogo em uma experiência visual avançada sem complicações. Experimente agora e sinta o poder de ver além do óbvio! 🌟

## Por Que Usar o Kolt? 🤔
- **Minimalista**: Código leve, sem dependências extras – roda suave em qualquer script Roblox.
- **Eficiente**: Atualizações por frame otimizadas com `RenderStepped` para performance top.
- **Responsivo**: Configurações globais e por objeto, com suporte a rainbow mode para um toque de cor dinâmica.
- **Fácil de Experimentar**: Carregue via `loadstring` direto do GitHub e comece a hackear visuals em minutos.
- **Contribua!**: Abra issues, forks ou PRs no repo – vamos evoluir isso juntos!

## Recursos Principais 📦
- **Tracers**: Linhas que conectam a tela ao alvo, com origens customizáveis (Top, Center, Bottom, etc.).
- **Highlights**: Preenchimento e outline 3D sempre visíveis (usando `Highlight` do Roblox).
- **Nomes e Distâncias**: Textos overlay com nome do alvo e distância em metros.
- **Boxes**: Caixas 2D ao redor do alvo (com transparência ajustável).
- **Skeletons**: Linhas conectando partes do modelo (simplificado, pronto para expansão).
- **Modo Rainbow**: Cores que mudam dinamicamente como um arco-íris.
- **Configurações Globais**: Aplique mudanças em massa, como opacidade, espessura de linhas e distâncias mín/máx.
- **Auto-Remoção**: Remove ESP de alvos inválidos automaticamente.
- **Suporte a Modelos e Parts**: Funciona com qualquer `Model` ou `BasePart`.

## Instalação e Carregamento 🛠️
O Kolt é carregado via `loadstring` diretamente do GitHub – perfeito para scripts remotos ou testes rápidos. Não precisa clonar o repo (mas faça se quiser contribuir!).

### Passo a Passo:
1. **Carregue a Biblioteca**:
   Use isso no seu script Roblox (ex: em um LocalScript ou ModuleScript):
   ```lua
   local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()
   ```
   - Isso busca o código Lua cru e o executa, retornando o objeto `ModelESP`.

2. **Ative o ESP**:
   - O Kolt inicia ativado por padrão (`ModelESP.Enabled = true`).
   - Desative globalmente com `ModelESP.Enabled = false` se precisar pausar.

3. **Teste em um Jogo**:
   - Abra o Roblox Studio ou um jogo.
   - Insira o código acima em um script.
   - Adicione ESP a objetos (veja exemplos abaixo).
   - Rode e veja a mágica acontecer!

**Dica Prática**: Se você está testando localmente, clone o repo e require o arquivo Lua diretamente. Mas para uso pessoal em jogos, o `loadstring` é rei! 👑

## API e Uso Básico 📖
O Kolt retorna um objeto `ModelESP` com métodos simples e intuitivos. Tudo é configurável por objeto ou globalmente.

### Métodos Principais:
- **`ModelESP:Add(target, config)`**: Adiciona ESP a um alvo (Model ou BasePart).
  - `target`: O Instance alvo (ex: um jogador's character).
  - `config`: Tabela opcional com overrides (veja Configurações abaixo).
  - Exemplo: `ModelESP:Add(workspace.MyModel, {Name = "Inimigo", Color = Color3.fromRGB(255, 0, 0)})`

- **`ModelESP:Remove(target)`**: Remove ESP de um alvo específico.

- **`ModelESP:Clear()`**: Limpa todos os ESPs adicionados.

- **`ModelESP:UpdateGlobalSettings()`**: Atualiza drawings com as configs globais atuais (chamado automaticamente em setters).

### Setters Globais (APIs para Configurações em Massa):
- **`ModelESP:SetGlobalTracerOrigin(origin)`**: Define origem do tracer ("Top", "Center", "Bottom", "Left", "Right").
- **`ModelESP:SetGlobalESPType(typeName, enabled)`**: Ativa/desativa tipos globalmente (ex: "ShowTracer", "ShowHighlightFill").
- **`ModelESP:SetGlobalRainbow(enable)`**: Ativa modo rainbow (true/false).
- **`ModelESP:SetGlobalOpacity(value)`**: Opacidade geral (0-1).
- **`ModelESP:SetGlobalFontSize(size)`**: Tamanho da fonte (mínimo 10).
- **`ModelESP:SetGlobalLineThickness(thick)`**: Espessura de linhas (mínimo 1).
- **`ModelESP:SetGlobalHighlightFillTransparency(value)`**: Transparência do preenchimento highlight (0-1).
- **`ModelESP:SetGlobalHighlightOutlineTransparency(value)`**: Transparência do outline highlight (0-1).

**Configs Padrão (em `ModelESP.GlobalSettings`)**:
```lua
{
    TracerOrigin = "Bottom",          -- Origem do tracer
    ShowTracer = true,                -- Mostrar tracers
    ShowHighlightFill = true,         -- Preenchimento highlight
    ShowHighlightOutline = true,      -- Outline highlight
    ShowName = true,                  -- Nome do alvo
    ShowDistance = true,              -- Distância
    ShowBox = true,                   -- Caixa 2D
    ShowSkeleton = false,             -- Esqueleto
    RainbowMode = false,              -- Modo arco-íris
    MaxDistance = math.huge,          -- Distância máxima para mostrar
    MinDistance = 0,                  -- Distância mínima
    Opacity = 0.8,                    -- Opacidade geral
    LineThickness = 1.5,              -- Espessura tracers
    BoxThickness = 1.5,               -- Espessura boxes
    SkeletonThickness = 1.2,          -- Espessura skeleton
    BoxTransparency = 0.5,            -- Transparência boxes
    FontSize = 14,                    -- Tamanho fonte
    AutoRemoveInvalid = true,         -- Remover inválidos auto
    HighlightFillTransparency = 0.85, -- Transparência fill
    HighlightOutlineTransparency = 0.65 -- Transparência outline
}
```
**Tema Padrão (em `ModelESP.Theme`)**:
```lua
{
    PrimaryColor = Color3.fromRGB(130, 200, 255),  -- Cor principal
    SecondaryColor = Color3.fromRGB(255, 255, 255),-- Cor secundária
    OutlineColor = Color3.fromRGB(0, 0, 0)         -- Cor outline
}
```

### Configs por Objeto (em `Add`):
Use uma tabela `config` para overrides específicos:
- `Name`: String personalizada.
- `Color`: Color3 principal.
- `OutlineColor`: Color3 do outline.
- `ShowTracer`, `ShowName`, etc.: Booleans para tipos.
- `Opacity`, `LineThickness`, etc.: Números para estilos.

## Exemplos Práticos 💡
Vamos mergulhar no código! Copie e cole para testar.

### Exemplo 1: ESP Básico em um Modelo
```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()

-- Adicione ESP a um modelo no workspace
ModelESP:Add(workspace.EnemyModel, {
    Name = "Inimigo Vermelho",
    Color = Color3.fromRGB(255, 0, 0),
    ShowTracer = true,
    ShowName = true,
    ShowDistance = true,
    MaxDistance = 100  -- Só mostra se <100m
})

-- Remova depois de 10s (exemplo)
wait(10)
ModelESP:Remove(workspace.EnemyModel)
```

### Exemplo 2: ESP em Todos os Jogadores (Uso Pessoal)
```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()

-- Configs globais para um estilo hacker
ModelESP:SetGlobalRainbow(true)
ModelESP:SetGlobalTracerOrigin("Center")
ModelESP:SetGlobalOpacity(0.9)

-- Adicione ESP a todos os characters
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        ModelESP:Add(char, {
            Name = player.Name,
            Color = Color3.fromRGB(0, 255, 0),  -- Verde para aliados?
            ShowHighlightFill = true,
            ShowBox = true,
            ShowSkeleton = true
        })
    end)
end)
```

### Exemplo 3: Customizando e Limpando
```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()

-- Adicione múltiplos
ModelESP:Add(workspace.Part1, {Name = "Parte Secreta"})
ModelESP:Add(workspace.Part2, {ShowSkeleton = false, Opacity = 0.5})

-- Mude globalmente
ModelESP:SetGlobalFontSize(18)
ModelESP:SetGlobalESPType("ShowDistance", false)

-- Limpe tudo
ModelESP:Clear()
```

**Dica Imersiva**: Rode isso em um jogo como Doors ou um simulator. Veja tracers seguindo inimigos – é viciante! Experimente tweakando configs para o seu estilo.

## Contribuindo 🤝
Quer melhorar o Kolt? Fork o repo em [GitHub](https://github.com/DH-SOARESE/Kolt-DOORS) e envie um Pull Request!
- **Ideias**: Adicione suporte a bounds reais para boxes, joints para skeletons, ou mais temas.
- **Issues**: Reporte bugs ou sugira features – ex: "Adicionar suporte a veículos".
- **Testes**: Teste em jogos reais e compartilhe screenshots nos issues.
- **Código Limpo**: Mantenha o estilo minimalista com comentários emoji. 😎

Seja prático: Clone, edite `Kolt ESP-LIBRARY.lua`, teste localmente, e push!

## Licença 📜
MIT License – Use, modifique e distribua livremente. Créditos a DH_SOARES apreciados!

*Versão 1.1 – Atualizado em [data atual]. Pronto para mais? Star o repo e fique ligado em updates!* ⭐
