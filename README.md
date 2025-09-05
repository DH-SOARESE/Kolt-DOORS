# Kolt ESP-LIBRARY

**Versão:** 1.4  
**Autor:** DH_SOARES  
**Estilo:** Minimalista, eficiente e responsivo, orientado a endereço de objetos

---

## 📦 Sobre

Kolt ESP-LIBRARY é uma biblioteca poderosa para criação de ESP (Extra Sensory Perception) e Tracers em Roblox, focada em performance, visualização eficiente e facilidade de uso. Ela oferece detecção e renderização avançada para modelos e partes, permitindo visualizar jogadores, mobs, itens ou qualquer objeto em 3D de forma clara e responsiva.

**Principais recursos:**
- Tracer e ESP altamente customizáveis
- Origem agrupada de Tracers (stack)
- Suporte a múltiplas referências de tela (box corners)
- Team Color para personagens de jogadores
- Função de descarregamento (unload)
- Configurações globais dinâmicas
- Box ESP dinâmico ou fixo
- Rainbow Mode (cores arco-íris)
- Remoção automática de objetos inválidos
- Overlay com Highlight Roblox (Fill/Outline)
- Textos de nome e distância

---

## 🚀 Instalação e Carregamento

Carregue diretamente via `loadstring`:

```lua
local Kolt = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()
```

---

## 🧩 Categorias de ESP

Kolt suporta múltiplos tipos de ESP, que podem ser combinados:

### 1. ESP Box
- Renderiza uma caixa ao redor do alvo (dinâmica ou fixa)
- Transparência e cor customizáveis

### 2. Tracer ESP
- Linhas desenhadas da origem definida até o alvo
- Stack horizontal/vertical e múltiplas referências de tela

### 3. Highlight ESP
- Utiliza o objeto Highlight do Roblox, com fill e outline
- Cores e transparências controláveis

### 4. Text ESP
- Mostra o nome do alvo e a distância (em metros)
- Fonte, cor e tamanho customizáveis

---

## ⚙️ Configuração Global

Altere facilmente o comportamento da biblioteca:

```lua
Kolt.GlobalSettings.ShowBox = true        -- Mostra Box ESP
Kolt.GlobalSettings.ShowTracer = true     -- Mostra Tracer ESP
Kolt.GlobalSettings.ShowHighlightFill = true
Kolt.GlobalSettings.ShowHighlightOutline = true
Kolt.GlobalSettings.ShowName = true       -- Mostra nome
Kolt.GlobalSettings.ShowDistance = true   -- Mostra distância
Kolt.GlobalSettings.RainbowMode = false   -- Cores arco-íris
Kolt.GlobalSettings.MaxDistance = 500     -- Distância máxima para aparecer
Kolt.GlobalSettings.MinDistance = 0       -- Distância mínima para aparecer
Kolt.GlobalSettings.ShowTeamColor = true  -- Usa cor do time para players
Kolt.GlobalSettings.BoxType = "Dynamic"   -- "Fixed" ou "Dynamic"
Kolt:SetGlobalTracerOrigin("Bottom")      -- Origem do Tracer ("Bottom", "Top", "Center", "Left", "Right")
Kolt:SetGlobalTracerStack(true)           -- Agrupa origens dos tracers
Kolt:SetGlobalTracerScreenRefs(true)      -- Usa múltiplos refs (box corners)
Kolt:SetGlobalOpacity(0.8)                -- Opacidade dos desenhos
Kolt:SetGlobalFontSize(14)                -- Tamanho do texto
Kolt:SetGlobalLineThickness(2)            -- Espessura do tracer
Kolt:SetGlobalBoxThickness(2)             -- Espessura da box
Kolt:SetGlobalBoxTransparency(0.5)        -- Transparência da box
Kolt:SetGlobalHighlightOutlineTransparency(0.65)
Kolt:SetGlobalHighlightFillTransparency(0.85)
```

---

## ➕ Adicionando ESP

Adicione ESP para qualquer Model ou BasePart:

```lua
-- Exemplo básico: Adiciona ESP a um player
for _,plr in ipairs(game.Players:GetPlayers()) do
    if plr.Character then
        Kolt:Add(plr.Character)
    end
end

-- Exemplo customizado: Adiciona ESP com configurações específicas
Kolt:Add(somePartOrModel, {
    Name = "Item Especial",
    Color = Color3.fromRGB(255,100,100),
    HighlightOutlineColor = Color3.fromRGB(0,0,0),
    HighlightOutlineTransparency = 0.5,
    FilledTransparency = 0.8,
    BoxColor = Color3.fromRGB(255,255,0),
    TracerColor = Color3.fromRGB(0,255,0),
})
```

---

## ➖ Removendo e Limpando ESP

Remova um ESP individual:
```lua
Kolt:Remove(target)
```

Remova todos os ESPs (Clear):
```lua
Kolt:Clear()
```

Descarregue a biblioteca (desfaz tudo e desconecta):
```lua
Kolt:Unload()
```

---

## 🌈 Rainbow Mode

Ative cores dinâmicas arco-íris em todos os elementos:
```lua
Kolt:SetGlobalRainbow(true)
```

---

## 🏷️ Suporte a Team Color

Ao adicionar ESP em personagens de jogadores, ative para usar a cor do time:
```lua
Kolt.GlobalSettings.ShowTeamColor = true
```

---

## 💡 Dicas Avançadas

- **Empilhamento de Tracers:** Use `TracerStack` para agrupar todos os tracers na origem (ótimo para jogos com muitos alvos).
- **Múltiplas Referências:** `TracerScreenRefs` permite que tracers sejam desenhados para cada canto da caixa do alvo — ideal para precisão.
- **Performance:** O ESP é removido automaticamente se o objeto for destruído/invalidado.
- **Overlay nativo:** O Highlight é aplicado diretamente no alvo, não apenas overlay 2D.

---

## 📚 API Completa

```lua
Kolt:Add(target, config)             -- Adiciona ESP
Kolt:Remove(target)                  -- Remove ESP do alvo
Kolt:Clear()                         -- Remove todos ESPs
Kolt:Unload()                        -- Descarrega/desativa a library
Kolt:SetGlobalTracerOrigin(origin)   -- Define origem dos tracers ("Bottom", "Top", etc)
Kolt:SetGlobalTracerStack(bool)      -- Agrupa/empilha origens
Kolt:SetGlobalTracerScreenRefs(bool) -- Usa múltiplos refs na tela
Kolt:SetGlobalESPType(type, bool)    -- Ativa/desativa tipo de ESP global ("ShowBox", "ShowTracer", etc)
Kolt:SetGlobalRainbow(bool)          -- Ativa/desativa modo arco-íris
Kolt:SetGlobalOpacity(value)         -- Opacidade de todos os desenhos
Kolt:SetGlobalFontSize(size)         -- Tamanho dos textos
Kolt:SetGlobalLineThickness(value)   -- Espessura dos tracers
Kolt:SetGlobalBoxThickness(value)    -- Espessura das boxes
Kolt:SetGlobalBoxTransparency(value) -- Transparência das boxes
Kolt:SetGlobalHighlightOutlineTransparency(value) -- Transparência do outline
Kolt:SetGlobalHighlightFillTransparency(value)    -- Transparência do fill
```

---

## 🧪 Exemplos Avançados

### ESP para todos os itens de um mapa

```lua
for _,item in ipairs(workspace.Items:GetChildren()) do
    Kolt:Add(item, {
        Name = item.Name,
        Color = Color3.fromRGB(0,255,180),
        BoxColor = Color3.fromRGB(255,255,255),
        TracerColor = Color3.fromRGB(140,140,255),
    })
end
```

### Configuração personalizada e dinâmica

```lua
Kolt:SetGlobalTracerOrigin("Top")
Kolt:SetGlobalBoxType("Fixed")
Kolt:SetGlobalFontSize(16)
Kolt.GlobalSettings.MaxDistance = 1000

-- Adiciona ESP em NPCs
for _,npc in ipairs(workspace.NPCs:GetChildren()) do
    Kolt:Add(npc, { Name = "NPC", Color = Color3.fromRGB(255,150,50) })
end
```

### Remover ESP quando não precisar mais

```lua
Kolt:Unload() -- Remove tudo e desconecta do RenderStepped
```

---

## 📝 Observações

- Funciona em qualquer jogo Roblox que permita execução de scripts externos.
- Requer Drawing API disponível (executores compatíveis).
- Suporte nativo ao Highlight Roblox.
- Para suporte ou feedback, acesse [GitHub Kolt-DOORS](https://github.com/DH-SOARESE/Kolt-DOORS).

---

## 📜 Licença

MIT

---

**Powered by DH_SOARES • Kolt ESP-LIBRARY V1.4**
