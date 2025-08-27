
# 📦 Kolt ESP-Library v3

> Uma **ESP Library completa** para Roblox, criada com foco em **simplicidade, desempenho e flexibilidade**.  
> Ideal para **Players ESP**, **Entities ESP** e até **objetos 2D sem Humanoid**.

---

## ✨ Recursos
- 🎯 **Suporte a Models, Parts e Entities sem Humanoid**
- 🎨 **Highlights 3D nativos**
- 🧵 **Tracers personalizáveis** (Top, Center, Bottom, Left, Right)
- 📝 **Nome + Distância em tempo real**
- 🌈 **Modo Rainbow (dinâmico)**
- 🛠️ **Configuração global para todas ESPs**
- 🚮 **Auto limpeza de objetos inválidos**
- ⚡ **API simples e intuitiva**

---

## 📥 Instalação
Basta carregar a library no seu script:

```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()


---

🧰 API da Library

➕ Adicionar ESP

ModelESP:Add(target: Instance, config: table)

Name → Nome exibido no ESP

Color → Cor do ESP (Color3)

TracerOrigin → Origem do tracer ("Top", "Center", "Bottom", "Left", "Right")

Opacity → Transparência (0 a 1)

MinDistance / MaxDistance → Limite de renderização



---

🎭 Adicionar Entities2D

ModelESP:AddEntities2D(target: Model, config: table)

Cria um Humanoid falso para entidades sem humanoide (monstros, mobs, props etc).



---

➖ Remover ESP

ModelESP:Remove(target: Instance)


---

🧹 Limpar Todos ESPs

ModelESP:Clear()


---

⚙️ Configurações Globais

Afetam todos os ESPs já existentes e novos em tempo real:

-- Tracer origin global
ModelESP:SetGlobalTracerOrigin("Bottom")

-- Mostrar/Ocultar elementos
ModelESP:SetGlobalESPType("ShowTracer", true)
ModelESP:SetGlobalESPType("ShowName", true)
ModelESP:SetGlobalESPType("ShowDistance", false)
ModelESP:SetGlobalESPType("ShowHighlightFill", true)
ModelESP:SetGlobalESPType("ShowHighlightOutline", true)

-- Aparência
ModelESP:SetGlobalOpacity(0.8)        -- Transparência
ModelESP:SetGlobalFontSize(16)       -- Tamanho da fonte
ModelESP:SetGlobalLineThickness(2)   -- Espessura das linhas

-- Rainbow 🌈
ModelESP:SetGlobalRainbow(true)


---

🚀 Exemplo Completo

-- Carregar a library
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()

-- 1) Adicionando ESP para Players
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        ModelESP:Add(player.Character, {
            Name = player.Name,
            Color = Color3.fromRGB(130, 200, 255), -- azul claro
            TracerOrigin = "Bottom"
        })
    end
end

-- 2) Adicionando ESP em inimigos (Entities2D)
for _, mob in ipairs(workspace.Monstros:GetChildren()) do
    ModelESP:AddEntities2D(mob, {
        Name = "Monstro",
        Color = Color3.fromRGB(255, 100, 100), -- vermelho
    })
end

-- 3) Configurações globais
ModelESP:SetGlobalTracerOrigin("Center")
ModelESP:SetGlobalRainbow(true)
ModelESP:SetGlobalOpacity(0.9)
ModelESP:SetGlobalFontSize(15)
ModelESP:SetGlobalLineThickness(2)

-- 4) Exemplo de remoção manual
-- ModelESP:Remove(workspace.Monstros.Monstro1)

-- 5) Limpar tudo
-- ModelESP:Clear()


---

📌 Informações

Autor: DH_SOARES

Versão: v3

Estilo: Minimalista e responsivo

Dependências: Drawing API (nativo de exploits compatíveis: Synapse, Script-Ware, etc.)
