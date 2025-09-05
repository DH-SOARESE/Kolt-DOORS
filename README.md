# Kolt ESP Library

## Introduction

Kolt is a minimalist, efficient, and responsive ESP (Extra Sensory Perception) library for Roblox. It is designed to be object-oriented, focusing on 3D objects (such as Models or BaseParts) by their instance addresses. This allows for precise targeting and rendering of visual overlays like tracers, boxes, highlights, names, and distances on in-game objects.

Key features include:
- Improved tracers and ESP rendering.
- Grouped tracer origins for better organization.
- Multiple screen references for tracers (e.g., from box corners).
- Support for team colors (for player characters).
- Rainbow mode for dynamic coloring.
- Unload function for clean cleanup.
- Automatic removal of invalid targets.

**Version:** V1.4  
**Author:** DH_SOARES  
**Style:** Minimalist and performant, with a focus on responsiveness.

This library is loaded via `loadstring` and runs in a RenderStepped loop for real-time updates.

## Installation

To load the library, use Roblox's `loadstring` with an HTTP request to fetch the script:

```lua
local Kolt = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/main/Kolt%20ESP-LIBRARY.lua"))()
```

Once loaded, `Kolt` is a table with methods and properties ready for use.

**Note:** Ensure HTTP requests are enabled in your game settings. The library requires access to `RunService`, `Players`, and `workspace.CurrentCamera`.

## Basic Usage

### Adding an ESP to an Object
Use `Kolt:Add(target, config)` to attach an ESP to a 3D object.

- `target`: A Roblox Instance (must be a `Model` or `BasePart`).
- `config`: An optional table to override global settings for this specific ESP (e.g., custom name, color, or type-specific options).

Example:
```lua
Kolt:Add(workspace.EnemyModel, {
    Name = "Enemy",
    Color = Color3.fromRGB(255, 0, 0),  -- Custom color
    ShowTracer = true,                 -- Enable tracer for this ESP
    TracerOrigin = "Bottom"            -- Custom tracer origin
})
```

### Removing an ESP
- `Kolt:Remove(target)`: Removes the ESP from a specific target.
- `Kolt:Clear()`: Removes all ESPs.

Example:
```lua
Kolt:Remove(workspace.EnemyModel)
```

### Unloading the Library
- `Kolt:Unload()`: Clears all ESPs, disconnects the render loop, and disables the library.

Example:
```lua
Kolt:Unload()
```

### Enabling/Disabling
- Set `Kolt.Enabled = false` to pause all rendering without unloading.

## Global Settings

These apply to all ESPs unless overridden in the per-object `config`. Access them via `Kolt.GlobalSettings`.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `TracerOrigin` | string | "Bottom" | Origin point for tracers (options: "Bottom", "Top", "Center", "Left", "Right"). |
| `TracerStack` | boolean | true | If true, groups tracer origins together to avoid overlap. |
| `TracerScreenRefs` | boolean | true | If true, uses multiple screen references (e.g., box corners) for tracers. |
| `ShowTracer` | boolean | true | Enables tracers globally. |
| `ShowHighlightFill` | boolean | true | Enables highlight fills. |
| `ShowHighlightOutline` | boolean | true | Enables highlight outlines. |
| `ShowName` | boolean | true | Shows the object's name. |
| `ShowDistance` | boolean | true | Shows the distance to the object. |
| `ShowBox` | boolean | true | Enables bounding boxes. |
| `RainbowMode` | boolean | false | Enables rainbow color cycling. |
| `MaxDistance` | number | math.huge | Maximum distance to render ESP (in studs). |
| `MinDistance` | number | 0 | Minimum distance to render ESP (in studs). |
| `Opacity` | number (0-1) | 0.8 | Overall opacity for drawings. |
| `LineThickness` | number | 1.5 | Thickness of tracer lines. |
| `BoxThickness` | number | 1.5 | Thickness of box lines. |
| `BoxTransparency` | number (0-1) | 0.5 | Transparency of boxes. |
| `HighlightOutlineTransparency` | number (0-1) | 0.65 | Transparency of highlight outlines. |
| `HighlightFillTransparency` | number (0-1) | 0.85 | Transparency of highlight fills. |
| `FontSize` | number | 14 | Font size for text (name and distance). |
| `AutoRemoveInvalid` | boolean | true | Automatically removes ESP if the target is invalid/destroyed. |
| `BoxPadding` | number | 5 | Padding around boxes. |
| `TracerPadding` | number | 0 | Spacing between stacked tracers (0 = fully stacked). |
| `BoxType` | string | "Dynamic" | Box type ("Dynamic" uses object bounds; "Fixed" uses a set size). |
| `ShowTeamColor` | boolean | false | Uses team colors for player characters if available. |

### Updating Global Settings
Use setter functions for convenience (they clamp values and update all ESPs):
- `Kolt:SetGlobalTracerOrigin("Bottom")`
- `Kolt:SetGlobalTracerStack(true)`
- `Kolt:SetGlobalTracerScreenRefs(true)`
- `Kolt:SetGlobalESPType("ShowTracer", true)` (works for any `Show*` type)
- `Kolt:SetGlobalRainbow(true)`
- `Kolt:SetGlobalOpacity(0.8)`
- `Kolt:SetGlobalFontSize(14)`
- `Kolt:SetGlobalLineThickness(1.5)`
- `Kolt:SetGlobalBoxThickness(1.5)`
- `Kolt:SetGlobalBoxTransparency(0.5)`
- `Kolt:SetGlobalHighlightOutlineTransparency(0.65)`
- `Kolt:SetGlobalHighlightFillTransparency(0.85)`

Calling these updates all existing ESPs via `Kolt:UpdateGlobalSettings()`.

## Theme Customization

Customize colors via `Kolt.Theme`:
- `PrimaryColor`: Color3.fromRGB(130, 200, 255) – Main color (e.g., for tracers/boxes).
- `SecondaryColor`: Color3.fromRGB(255, 255, 255) – Secondary (e.g., text).
- `OutlineColor`: Color3.fromRGB(0, 0, 0) – Outlines.

These are used unless overridden by rainbow mode or per-object colors.

## Per-Object Configuration

When adding an ESP with `Kolt:Add(target, config)`, the `config` table can override globals. Supported keys (case-sensitive, based on library structure):
- `Name`: string – Custom display name (defaults to target.Name).
- `Color`: Color3 – Custom color (overrides theme/team color).
- Any global setting key (e.g., `ShowTracer`, `TracerOrigin`, `FontSize`), applied only to this ESP.

Example:
```lua
Kolt:Add(workspace.Part, {
    Name = "Important Part",
    Color = Color3.fromRGB(0, 255, 0),
    ShowBox = false,  -- Disable box for this one
    MaxDistance = 100 -- Only show if within 100 studs
})
```

## ESP Types

Below are details for each ESP type. Each can be enabled/disabled globally or per-object.

### Tracers
Tracers draw lines from a screen origin point to the target object, helping track off-screen or distant items.

**Key Properties:**
- `ShowTracer`: Enable/disable.
- `TracerOrigin`: Screen starting point ("Bottom", "Top", "Center", "Left", "Right").
- `TracerStack`: Group multiple tracers to share origins (prevents clutter).
- `TracerScreenRefs`: Use multiple references (e.g., connect to box corners for better visibility).
- `TracerPadding`: Spacing between stacked tracers.
- `LineThickness`: Line width.
- `Opacity`: Line opacity.

**Intuitive Tips:**
- Use "Bottom" for a HUD-like feel.
- Enable `TracerScreenRefs` for complex targets like models.
- In rainbow mode, tracers cycle colors dynamically.

Example Override:
```lua
{ ShowTracer = true, TracerOrigin = "Center", LineThickness = 2 }
```

### Boxes
Boxes draw 2D bounding rectangles around the object's screen projection.

**Key Properties:**
- `ShowBox`: Enable/disable.
- `BoxType`: "Dynamic" (adapts to object bounds) or "Fixed" (static size).
- `BoxPadding`: Extra space around the box.
- `BoxThickness`: Line width.
- `BoxTransparency`: Line transparency.
- `Opacity`: Overall opacity.

**Intuitive Tips:**
- "Dynamic" is great for varying object sizes (e.g., characters).
- Combine with highlights for a glowing effect.

Example Override:
```lua
{ ShowBox = true, BoxType = "Fixed", BoxPadding = 10 }
```

### Highlights
Highlights use Roblox's Highlight instance for a 3D glow effect on the object.

**Key Properties:**
- `ShowHighlightFill`: Enable filled glow.
- `ShowHighlightOutline`: Enable outline glow.
- `HighlightFillTransparency`: Fill transparency.
- `HighlightOutlineTransparency`: Outline transparency.

**Intuitive Tips:**
- Fills make objects stand out in dark areas.
- Outlines are subtle for minimalism.
- Works best on models with multiple parts.

Example Override:
```lua
{ ShowHighlightFill = false, ShowHighlightOutline = true, HighlightOutlineTransparency = 0.5 }
```

### Names
Displays the object's name above or near the ESP.

**Key Properties:**
- `ShowName`: Enable/disable.
- `FontSize`: Text size.

**Intuitive Tips:**
- Useful for identifying specific targets in crowded scenes.
- Text uses `SecondaryColor` by default.

Example Override:
```lua
{ ShowName = true, FontSize = 16 }
```

### Distances
Shows the distance (in studs) from the camera to the object.

**Key Properties:**
- `ShowDistance`: Enable/disable.
- `FontSize`: Text size (distance text is slightly smaller by default).
- `MinDistance` / `MaxDistance`: Control visibility based on range.

**Intuitive Tips:**
- Helps gauge threats or objectives.
- Text appears near the name or box.

Example Override:
```lua
{ ShowDistance = true, MinDistance = 10, MaxDistance = 500 }
```

## Advanced Tips
- **Performance:** The library uses `RenderStepped` for updates—disable unused types to optimize.
- **Rainbow Mode:** Colors cycle based on time; great for visual flair.
- **Team Colors:** Enable `ShowTeamColor` for player-based ESPs (e.g., red for enemies).
- **Bounds Calculation:** Supports Models (scans descendants for visible BaseParts) and single BaseParts.
- **Error Handling:** If target is invalid, it's auto-removed if `AutoRemoveInvalid` is true.
- **Customization Depth:** Mix global and per-object configs for flexible setups (e.g., different colors per enemy type).

## Troubleshooting
- ESP not showing? Check `Kolt.Enabled`, distances, and if the target is a valid Model/BasePart.
- Colors not updating? Rainbow mode overrides static colors.
- Overlap issues? Adjust `TracerStack` and `TracerPadding`.

For issues, check the script source or contact the author.
