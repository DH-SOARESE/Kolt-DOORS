# 📦 Kolt ESP Library V1.2

**Minimalista, eficiente e responsivo.**

![Kolt ESP Banner](https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Assets/EspImage.jpg) <!-- Adicione uma imagem ilustrativa se desejar -->

---

## ✨ Sobre

A **Kolt ESP Library** foi criada para facilitar a implementação de ESP (Extra Sensory Perception) em projetos Roblox, especialmente em experiências de jogos como DOORS.  
Simples de integrar, altamente configurável e com visual agradável, a biblioteca oferece recursos avançados para visualização de modelos, partes e entidades no mundo 3D.

- **Autor:** [DH_SOARES](https://github.com/DH-SOARESE)
- **Estilo:** Minimalista
- **Versão:** 1.2

---

## 🚀 Como Usar

A biblioteca é carregada via `loadstring` diretamente do seu repositório no GitHub.  
Basta copiar e executar o snippet abaixo no seu script Roblox:

```lua
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()
```

---

## 🧩 Exemplo Prático

Adicionando ESP em um modelo específico no workspace:

```lua
-- Carregue a library
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()

-- Adicione o ESP em um modelo chamado "Enemy"
local enemyModel = workspace:FindFirstChild("Enemy")
if enemyModel then
    ModelESP:Add(enemyModel, {
        Name = "Inimigo",
        Color = Color3.fromRGB(255,100,100)
    })
end
```

Removendo ESP:

```lua
ModelESP:Remove(enemyModel)
```

Limpando todos os ESPs:

```lua
ModelESP:Clear()
```

---

## ⚙️ API Completa

### Adicionar ESP

```lua
ModelESP:Add(targetInstance, configTable)
```
- `targetInstance`: Model ou BasePart que receberá o ESP.
- `configTable` (opcional): Propriedades customizadas (Name, Color, HighlightOutlineColor, etc).

### Remover ESP

```lua
ModelESP:Remove(targetInstance)
```
- Remove o ESP de um objeto específico.

### Limpar todos ESPs

```lua
ModelESP:Clear()
```
- Remove todos os ESPs ativos.

### Configurações Globais

A library permite alterar configurações globais facilmente:

```lua
ModelESP:SetGlobalTracerOrigin("Center")         -- Origem do tracer: "Top", "Bottom", "Left", "Right", "Center"
ModelESP:SetGlobalESPType("ShowBox", false)      -- Habilita/desabilita Box ESP
ModelESP:SetGlobalRainbow(true)                  -- Ativa cor arco-íris animada
ModelESP:SetGlobalOpacity(0.5)                   -- Opacidade geral (0 a 1)
ModelESP:SetGlobalFontSize(16)                   -- Tamanho da fonte dos textos
ModelESP:SetGlobalLineThickness(2.5)             -- Espessura das linhas do tracer
ModelESP:SetGlobalBoxThickness(2)                -- Espessura da box
ModelESP:SetGlobalSkeletonThickness(1.5)         -- Espessura do esqueleto
ModelESP:SetGlobalBoxTransparency(0.6)           -- Transparência da box
ModelESP:SetGlobalHighlightOutlineTransparency(0.7) -- Transparência do contorno do highlight
ModelESP:SetGlobalHighlightFillTransparency(0.9) -- Transparência do preenchimento do highlight
```

---

## 🌈 Temas e Visual

Personalize as cores e estilos do ESP via tema e configurações globais:

```lua
ModelESP.Theme.PrimaryColor = Color3.fromRGB(130, 200, 255)
ModelESP.Theme.SecondaryColor = Color3.fromRGB(255,255,255)
ModelESP.Theme.OutlineColor   = Color3.fromRGB(0,0,0)
```

---

## 🔗 Documentação das Funções

| Função                                    | Descrição                                              |
|-------------------------------------------|--------------------------------------------------------|
| `ModelESP:Add(target, config)`            | Adiciona ESP ao alvo                                   |
| `ModelESP:Remove(target)`                 | Remove ESP do alvo                                     |
| `ModelESP:Clear()`                        | Remove todos ESPs                                      |
| `ModelESP:SetGlobalTracerOrigin(origin)`  | Origem do tracer ("Top", "Bottom", "Center", etc)      |
| `ModelESP:SetGlobalESPType(type, enabled)`| Liga/desliga tipos de ESP (Box, Skeleton, Tracer, etc) |
| `ModelESP:SetGlobalRainbow(enabled)`      | Ativa modo arco-íris                                   |
| `ModelESP:SetGlobalOpacity(value)`        | Opacidade global                                       |
| `ModelESP:SetGlobalFontSize(size)`        | Tamanho da fonte dos textos                            |
| ...                                       | Veja o código para mais APIs!                          |

---

## 💡 Dicas

- Combine múltiplos tipos de ESP para adaptar à sua necessidade.
- Use o modo arco-íris para destacar objetos especiais.
- Experimente ajustar as transparências para um visual mais clean.

---

## 🤝 Contribua

Sinta-se livre para contribuir.  
Abra issues, envie PRs e compartilhe sugestões no [repositório](https://github.com/DH-SOARESE/Kolt-DOORS).

**Sugestões e feedbacks são bem-vindos!**

---

## 🗂️ Recursos Avançados

- Remoção automática de objetos inválidos (`AutoRemoveInvalid`)
- Suporte a Highlight nativo do Roblox
- Suporte a Skeleton ESP (experimental)
- Configuração de distância mínima/máxima
- Compatível com scripts pessoais e automações

---

## 📝 Observações

- Esta biblioteca foi projetada para uso em experiências Roblox e scripts pessoais.
- O uso indevido pode violar os Termos de Serviço da Roblox. Utilize com responsabilidade.

---

## 📬 Contato

- GitHub: [DH-SOARESE](https://github.com/DH-SOARESE)

---

**Faça parte do desenvolvimento! Experimente, modifique e contribua.**

---
