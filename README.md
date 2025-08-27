# 📦 Kolt ESP-Library v3

> Uma biblioteca **minimalista, eficiente e responsiva** para criação de ESP (Extra Sensory Perception) em Roblox.  
> Desenvolvida para **visualizar modelos, entidades e objetos 2D** em tempo real com customização avançada.

---

## ✨ Features
- ✅ **ESP para Models e BaseParts**
- ✅ **Entities2D ESP** (cria um `Humanoid` falso para renderização)
- ✅ **Tracers customizáveis** (Top, Center, Bottom, Left, Right)
- ✅ **Highlights 3D nativos**
- ✅ **Textos dinâmicos** (nome + distância)
- ✅ **Distância mínima/máxima de renderização**
- ✅ **Modo Rainbow 🌈**
- ✅ **Configurações globais em tempo real**
- ✅ **Remoção automática de targets inválidos**
- ✅ **API simples e limpa**

---

## 📥 Instalação
Carregue a library direto no seu script com:

```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()


---

⚡ Uso Básico

-- Adicionando um Model ao ESP
```lua
ModelESP:Add(workspace.MyModel, {Name = "Inimigo", Color = Color3.fromRGB(255,0,0)})
```

-- Adicionando Entity 2D (usando Humanoid falso)
```lua
ModelESP:AddEntities2D(workspace.Monstro, {Name = "Monstro2D", Color = Color3.fromRGB(0,255,0)})
```

-- Removendo um ESP
```lua
ModelESP:Remove(workspace.MyModel)
```
-- Limpando todos ESP
```lua
ModelESP:Clear()
```


---

🎨 Configurações Globais

As configs globais afetam todos os ESP ativos em tempo real.

Tracer Origin
```lua
ModelESP:SetGlobalTracerOrigin("Bottom") 
-- opções: "Top", "Center", "Bottom", "Left", "Right"
```

Mostrar/Ocultar elementos
```lua
ModelESP:SetGlobalESPType("ShowTracer", true)
ModelESP:SetGlobalESPType("ShowName", true)
ModelESP:SetGlobalESPType("ShowDistance", false)
ModelESP:SetGlobalESPType("ShowHighlightFill", true)
ModelESP:SetGlobalESPType("ShowHighlightOutline", true)
```
Opacidade
```lua
ModelESP:SetGlobalOpacity(0.7)
```

Tamanho da Fonte
```lua
ModelESP:SetGlobalFontSize(16)
```
Espessura das Linhas
```lua
ModelESP:SetGlobalLineThickness(2)
```
Modo Rainbow
```lua
ModelESP:SetGlobalRainbow(true) --
```
🌈


---

🧹 Auto Limpeza

Caso um target seja destruído ou removido do jogo, a library pode limpar automaticamente:
```lua
ModelESP.GlobalSettings.AutoRemoveInvalid = true -- default já é true
```

---

🛠️ API Completa

Adicionar ESP
```lua
ModelESP:Add(target: Instance, config: table)
```
Name → nome exibido no ESP

Color → cor base (Color3)



---

Adicionar Entities2D
```lua
ModelESP:AddEntities2D(target: Model, config: table)
```

Cria humanoide falso para suportar 2D ESP em entidades sem humanoide.



---

Remover ESP
```lua
ModelESP:Remove(target: Instance)
```

---

Limpar Todos
```lua
ModelESP:Clear()
```

---

Atualizar Configurações Globais
```lua
ModelESP:UpdateGlobalSettings()
```
Força a atualização de todos os ESPs após mudança manual nos GlobalSettings.


---
```lua
🚀 Exemplo Completo

-- Ativando ESP em vários inimigos
for _, mob in ipairs(workspace.Monstros:GetChildren()) do
    ModelESP:Add(mob, {Name = mob.Name, Color = Color3.fromRGB(255, 100, 100)})
end

-- Configuração global
ModelESP:SetGlobalTracerOrigin("Bottom")
ModelESP:SetGlobalRainbow(true)
ModelESP:SetGlobalOpacity(0.9)
ModelESP:SetGlobalFontSize(15)
ModelESP:SetGlobalLineThickness(2)
```

---

📌 Informações

Autor: DH_SOARES

Versão: v3

Estilo: Minimalista e responsivo

Dependências: Drawing API (nativo de exploits como Synapse, Script-Ware, etc.)



---
