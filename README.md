# Kolt ESP-Library v3

Uma biblioteca de **ESP (Extra Sensory Perception)** para Roblox, criada para ser **simples, leve e altamente configurável**.  
Ela permite destacar **Players**, **Models** e **Entities sem Humanoid**, com suporte a configurações globais.

---

## Recursos
- Suporte a **Players, Models e Entities 2D**
- **Highlights 3D** nativos
- **Tracers personalizáveis** (Top, Center, Bottom, Left, Right)
- Nome e distância exibidos dinamicamente
- **Configurações globais** em tempo real
- **Modo Rainbow** para cores dinâmicas
- **Opacidade, fonte e espessura ajustáveis**
- Auto limpeza de alvos inválidos

---

## Instalação

Carregue a biblioteca com:

```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()


---

Uso Básico

-- Carregar a library
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()

-- Adicionar ESP para todos os players
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        ModelESP:Add(player.Character, {
            Name = player.Name,
            Color = Color3.fromRGB(130, 200, 255),
            TracerOrigin = "Bottom"
        })
    end
end

Esse exemplo cria ESPs básicos para todos os jogadores, com tracer vindo da parte inferior.


---

Uso Avançado

-- Carregar a library
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()

-- ESP para inimigos (Entities2D)
for _, mob in ipairs(workspace.Monstros:GetChildren()) do
    ModelESP:AddEntities2D(mob, {
        Name = "Monstro",
        Color = Color3.fromRGB(255, 100, 100),
    })
end

-- Configurações globais
ModelESP:SetGlobalTracerOrigin("Center")     -- Origem do tracer
ModelESP:SetGlobalRainbow(true)             -- Ativar modo Rainbow
ModelESP:SetGlobalOpacity(0.9)              -- Transparência
ModelESP:SetGlobalFontSize(15)              -- Fonte
ModelESP:SetGlobalLineThickness(2)          -- Espessura

-- Opções de exibição
ModelESP:SetGlobalESPType("ShowTracer", true)
ModelESP:SetGlobalESPType("ShowName", true)
ModelESP:SetGlobalESPType("ShowDistance", true)
ModelESP:SetGlobalESPType("ShowHighlightFill", true)
ModelESP:SetGlobalESPType("ShowHighlightOutline", true)

Esse exemplo mostra como usar ESP em Entities 2D (sem Humanoid) e aplicar configurações globais em tempo real.


---

API

Funções Principais

ModelESP:Add(target, config) → Adiciona ESP a um Model/Player

ModelESP:AddEntities2D(target, config) → Adiciona ESP a Entities sem Humanoid

ModelESP:Remove(target) → Remove ESP de um objeto específico

ModelESP:Clear() → Remove todos os ESPs ativos


Configurações Globais

SetGlobalTracerOrigin("Top|Center|Bottom|Left|Right")

SetGlobalESPType("ShowTracer|ShowName|ShowDistance|ShowHighlightFill|ShowHighlightOutline", true/false)

SetGlobalOpacity(number)

SetGlobalFontSize(number)

SetGlobalLineThickness(number)

SetGlobalRainbow(true/false)



---

Informações

Autor: DH_SOARES

Versão: v3

Dependências: Drawing API (nativo em exploits compatíveis: Synapse, Script-Ware, etc.)


---
