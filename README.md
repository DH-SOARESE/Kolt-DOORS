
# Kolt ESP-Library v3

Biblioteca ESP para Roblox, desenvolvida para ser **leve, eficiente e totalmente configurável**. Permite adicionar ESP em **Players, Models e Entities 2D**, com **tracers, highlights, nomes e distâncias**.

---

## Recursos

- ESP para **Players, Models e Entities sem Humanoid**
- **Highlights 3D** (com preenchimento e contorno ajustáveis)
- **Tracers** com origem personalizável: Top, Center, Bottom, Left, Right
- Exibição de **nome e distância**
- **Configurações globais** aplicáveis a todos os ESPs existentes e novos
- **Modo Rainbow** para cores dinâmicas
- Ajuste de **opacidade, fonte e espessura**
- Remoção automática de targets inválidos

---

## Instalação

Carregue a biblioteca diretamente de GitHub:

```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()
```

---

Uso Básico

Adiciona ESP para todos os jogadores no jogo:

for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        ModelESP:Add(player.Character, {
            Name = player.Name,
            Color = Color3.fromRGB(130, 200, 255),
            TracerOrigin = "Bottom"
        })
    end
end

Name: Nome exibido acima do target

Color: Cor da ESP

TracerOrigin: Origem da linha (Bottom, Top, Center, Left, Right)



---

Uso Avançado

Adiciona ESP para monstros/Entities sem Humanoid e aplica configurações globais:

-- ESP para monstros
for _, mob in ipairs(workspace.Monstros:GetChildren()) do
    ModelESP:AddEntities2D(mob, {
        Name = "Monstro",
        Color = Color3.fromRGB(255, 100, 100)
    })
end

-- Configurações globais
ModelESP:SetGlobalTracerOrigin("Center")     
ModelESP:SetGlobalRainbow(true)             
ModelESP:SetGlobalOpacity(0.9)              
ModelESP:SetGlobalFontSize(15)              
ModelESP:SetGlobalLineThickness(2)          
ModelESP:SetGlobalESPType("ShowTracer", true)
ModelESP:SetGlobalESPType("ShowName", true)
ModelESP:SetGlobalESPType("ShowDistance", true)
ModelESP:SetGlobalESPType("ShowHighlightFill", true)
ModelESP:SetGlobalESPType("ShowHighlightOutline", true)

AddEntities2D: Cria ESP para models sem Humanoid, deixando partes invisíveis

Configurações globais afetam todas as ESPs, existentes e futuras



---

Funções Principais

Função	Descrição

Add(target, config)	Adiciona ESP a um Model/Player
AddEntities2D(target, config)	Adiciona ESP a Entities sem Humanoid
Remove(target)	Remove ESP de um alvo específico
Clear()	Remove todos os ESPs ativos



---

Configurações Globais

Método	Descrição

`SetGlobalTracerOrigin("Top	Center
SetGlobalESPType(typeName, true/false)	Ativa/desativa: ShowTracer, ShowName, ShowDistance, ShowHighlightFill, ShowHighlightOutline
SetGlobalOpacity(number)	Define transparência de ESPs (0 a 1)
SetGlobalFontSize(number)	Define tamanho da fonte
SetGlobalLineThickness(number)	Define espessura da linha do tracer
SetGlobalRainbow(true/false)	Ativa modo Rainbow dinâmico
Enabled	Habilita/desabilita todos ESPs



---

Informações

Autor: DH_SOARES

Versão: v3

Dependências: Drawing API (Sinapse, Script-Ware, etc.)

Estilo: Minimalista, eficiente e responsivo



---

Observações

A ESP segue configurações globais automaticamente para novos e existentes targets

Targets inválidos podem ser removidos automaticamente usando AutoRemoveInvalid

Tracers sempre respeitam o valor definido em SetGlobalTracerOrigin


