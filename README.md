📚 Kolt ESP Library

Uma biblioteca de ESP (Extra Sensory Perception) minimalista e eficiente para Roblox, orientada a endereço de objetos 3D. Desenvolvida para fornecer visualização de entidades no jogo com alto desempenho e personalização.

🚀 Como Carregar

```lua
local Kolt = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()
```

📋 Índice

· Visão Geral
· Configuração Rápida
· Funções Principais
· Configurações Globais
· Exemplos de Uso
· API Completa
· Notas Técnicas

🌟 Visão Geral

A Kolt ESP Library oferece:

· ✅ ESP com caixa (Box ESP)
· ✅ Linhas traçadoras (Tracers)
· ✅ Highlight de objetos
· ✅ Nomes e distâncias
· ✅ Suporte a cores de time
· ✅ Modo arco-íris
· ✅ Origem agrupada de tracers
· ✅ Suporte a múltiplas referências de tela
· ✅ Alto desempenho com Drawing objects

⚡ Configuração Rápida

```lua
-- Carregar a biblioteca
local Kolt = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()

-- Adicionar ESP para todos os jogadores
for _, player in ipairs(game.Players:GetPlayers()) do
    if player ~= game.Players.LocalPlayer and player.Character then
        Kolt:Add(player.Character, {
            Name = player.Name,
            Color = Color3.fromRGB(255, 100, 100)
        })
    end
end

-- Conectar para novos jogadores
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        Kolt:Add(character, {
            Name = player.Name,
            Color = Color3.fromRGB(255, 100, 100)
        })
    end)
end)
```

🎯 Funções Principais

Kolt:Add(target, config)

Adiciona ESP a um objeto (Model ou BasePart).

Parâmetros:

· target: Instância do Roblox (Model ou BasePart)
· config: Tabela de configuração (opcional)

Exemplo:

```lua
Kolt:Add(workspace.Enemy, {
    Name = "Inimigo",
    Color = Color3.fromRGB(255, 0, 0),
    HighlightOutlineColor = Color3.fromRGB(0, 0, 0),
    TracerColor = Color3.fromRGB(255, 255, 0)
})
```

Kolt:Remove(target)

Remove o ESP de um objeto específico.

Exemplo:

```lua
Kolt:Remove(workspace.Enemy)
```

Kolt:Clear()

Remove todos os ESPs ativos.

Exemplo:

```lua
Kolt:Clear()
```

Kolt:Unload()

Descarrega completamente a biblioteca e limpa todos os recursos.

Exemplo:

```lua
Kolt:Unload()
```

⚙️ Configurações Globais

Configurações de Visualização

```lua
-- Ativar/desativar componentes do ESP
Kolt:SetGlobalESPType("ShowTracer", true)           -- Linhas traçadoras
Kolt:SetGlobalESPType("ShowHighlightFill", true)    -- Preenchimento do highlight
Kolt:SetGlobalESPType("ShowHighlightOutline", true) -- Contorno do highlight
Kolt:SetGlobalESPType("ShowName", true)             -- Nomes
Kolt:SetGlobalESPType("ShowDistance", true)         -- Distâncias
Kolt:SetGlobalESPType("ShowBox", true)              -- Caixas ESP

-- Configurar origem dos tracers
Kolt:SetGlobalTracerOrigin("Bottom")  -- Opções: Bottom, Top, Center, Left, Right

-- Agrupar tracers
Kolt:SetGlobalTracerStack(true)

-- Usar múltiplas referências de tela
Kolt:SetGlobalTracerScreenRefs(true)

-- Modo arco-íris
Kolt:SetGlobalRainbow(true)

-- Usar cores de time
Kolt.GlobalSettings.ShowTeamColor = true
```

Configurações de Estilo

```lua
-- Opacidade geral
Kolt:SetGlobalOpacity(0.8)

-- Tamanho da fonte
Kolt:SetGlobalFontSize(14)

-- Espessura das linhas
Kolt:SetGlobalLineThickness(1.5)
Kolt:SetGlobalBoxThickness(1.5)

-- Transparências
Kolt:SetGlobalBoxTransparency(0.5)
Kolt:SetGlobalHighlightOutlineTransparency(0.65)
Kolt:SetGlobalHighlightFillTransparency(0.85)

-- Distância de renderização
Kolt.GlobalSettings.MaxDistance = 1000  -- Máxima distância para mostrar ESP
Kolt.GlobalSettings.MinDistance = 0     -- Mínima distância para mostrar ESP

-- Tipo de caixa
Kolt.GlobalSettings.BoxType = "Dynamic"  -- "Dynamic" ou "Fixed"
```

🎨 Exemplos de Uso

Exemplo 1: ESP para Inimigos

```lua
local function setupEnemyESP()
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        if enemy:IsA("Model") then
            Kolt:Add(enemy, {
                Name = "Inimigo",
                Color = Color3.fromRGB(255, 50, 50)
            })
        end
    end
end

setupEnemyESP()
workspace.Enemies.ChildAdded:Connect(setupEnemyESP)
```

Exemplo 2: ESP para Itens

```lua
local function setupItemsESP()
    for _, item in ipairs(workspace.Items:GetChildren()) do
        if item:IsA("BasePart") then
            Kolt:Add(item, {
                Name = "Item Importante",
                Color = Color3.fromRGB(50, 255, 50),
                TracerColor = Color3.fromRGB(0, 200, 0)
            })
        end
    end
end

setupItemsESP()
workspace.Items.ChildAdded:Connect(setupItemsESP)
```

Exemplo 3: ESP com Temas Customizados

```lua
-- Tema vermelho para inimigos
Kolt.Theme.PrimaryColor = Color3.fromRGB(255, 50, 50)
Kolt.Theme.SecondaryColor = Color3.fromRGB(255, 150, 150)
Kolt.Theme.OutlineColor = Color3.fromRGB(100, 0, 0)

-- Configurações específicas para diferentes tipos de objetos
Kolt:Add(workspace.Boss, {
    Name = "CHEFE",
    Color = Color3.fromRGB(255, 0, 0),
    HighlightOutlineColor = Color3.fromRGB(100, 0, 0),
    TracerColor = Color3.fromRGB(255, 100, 100)
})
```

🔧 API Completa

Propriedades da Biblioteca

```lua
Kolt.Objects        -- Tabela com todos os objetos ESP
Kolt.Enabled        -- Estado ativo/inativo da biblioteca
Kolt.Theme          -- Configurações de tema
Kolt.GlobalSettings -- Configurações globais
```

Métodos de Configuração

```lua
-- Controle de visualização
Kolt:SetGlobalESPType(typeName, enabled)

-- Configurações de estilo
Kolt:SetGlobalOpacity(value)
Kolt:SetGlobalFontSize(size)
Kolt:SetGlobalLineThickness(thick)
Kolt:SetGlobalBoxThickness(thick)
Kolt:SetGlobalBoxTransparency(value)
Kolt:SetGlobalHighlightOutlineTransparency(value)
Kolt:SetGlobalHighlightFillTransparency(value)

-- Configurações de tracers
Kolt:SetGlobalTracerOrigin(origin)
Kolt:SetGlobalTracerStack(enable)
Kolt:SetGlobalTracerScreenRefs(enable)
Kolt:SetGlobalRainbow(enable)
```

Estrutura de Configuração por Objeto

```lua
{
    Target = target,              -- Instância do Roblox
    Name = "Nome",                -- Texto para exibir
    Color = Color3.new(1,0,0),    -- Cor principal
    HighlightOutlineColor = Color3.new(0,0,0), -- Cor do contorno
    HighlightOutlineTransparency = 0.65,        -- Transparência do contorno
    FilledTransparency = 0.85,                  -- Transparência do preenchimento
    BoxColor = nil,               -- Cor da caixa (nil = usar cor principal)
    TracerColor = nil,            -- Cor do tracer (nil = usar cor principal)
}
```

📝 Notas Técnicas

1. Performance: A biblioteca usa Drawing objects para melhor performance
2. Compatibilidade: Funciona com Models e BaseParts
3. Remoção Automática: Objetos invalidados são automaticamente removidos quando AutoRemoveInvalid = true
4. Orientação a Objetos: Cada ESP é tratado como um objeto independente
5. Renderização: Usa múltiplas referências de pontos para melhor precisão visual

🐛 Solução de Problemas

ESP não aparece

· Verifique se o objeto é um Model ou BasePart
· Confirme que o objeto está dentro da distância configurada
· Verifique se as configurações globais estão habilitadas

Performance baixa

· Reduza a quantidade de objetos com ESP
· Aumente as distâncias mínima/máxima
· Desative componentes não necessários

Cores incorretas

· Verifique se ShowTeamColor não está conflitando com cores customizadas
· Confirme se o modo arco-íris não está sobrepondo outras cores

📞 Suporte

Para issues e contribuições, visite o GitHub do projeto.

---

Desenvolvido por DH_SOARES - Versão 1.4
