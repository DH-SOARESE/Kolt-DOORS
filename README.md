# Kolt ESP Library v3

![Lua](https://img.shields.io/badge/Lua-5.1-blue.svg) ![Roblox](https://img.shields.io/badge/Platform-Roblox-green.svg) ![Version](https://img.shields.io/badge/Version-3.0-brightgreen.svg) ![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## Overview

Kolt ESP Library is a lightweight, efficient, and responsive Extra Sensory Perception (ESP) tool designed for Roblox game development. It provides visual enhancements such as tracers, name tags, distance indicators, and model highlights to help track and visualize in-game models or parts. Built with a minimalist style, it focuses on performance without sacrificing functionality.

This library is ideal for developers creating cheats, debugging tools, or enhanced user interfaces in Roblox experiences. It supports dynamic updates, rainbow color modes, and global configuration for easy customization.

**Author:** DH_SOARES  
**Style:** Minimalist, efficient, and responsive  
**Repository:** [GitHub - DH-SOARESE/Kolt-DOORS](https://github.com/DH-SOARESE/Kolt-DOORS)  

## Features

- **Tracers:** Draw lines from screen origins (Top, Center, Bottom, Left, Right) to target positions.
- **Name and Distance Display:** Show customizable names and real-time distance metrics.
- **Highlights:** Use Roblox's built-in `Highlight` instance for outline and fill effects, with adjustable transparency.
- **Rainbow Mode:** Cycle through rainbow colors for a dynamic visual effect.
- **Global Settings:** Control visibility, opacity, thickness, font size, and distance thresholds across all ESP instances.
- **Auto-Removal:** Automatically remove invalid or destroyed targets.
- **Support for Models and Parts:** Works with `Model` and `BasePart` instances.
- **Entities2D Mode:** Special handling for 2D-like entities by adding fake humanoids and adjusting transparencies.
- **Performance Optimized:** Runs on `RenderStepped` for smooth, frame-by-frame updates without lag.
- **Rainbow Color Generation:** Sinusoidal RGB interpolation for smooth color transitions.

## Installation

The library is loaded via Lua's `loadstring` function from a raw GitHub URL. This allows easy integration without local files.

### Usage Example

```lua
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()
```

- **Note:** Ensure `HttpGet` is enabled in your Roblox environment (e.g., via `game:HttpGet`).
- This returns the `ModelESP` table, which you can use to add and manage ESP elements.

## API Documentation

The library exposes a single table: `ModelESP`. All methods and properties are accessed through this.

### Properties

- **`Objects`** (table): Internal list of active ESP configurations. Do not modify directly.
- **`Enabled`** (boolean): Global toggle for all ESP rendering. Default: `true`.
- **`Theme`** (table): Color scheme settings.
  - `PrimaryColor` (Color3): Main color for tracers and text. Default: `Color3.fromRGB(130, 200, 255)`.
  - `SecondaryColor` (Color3): Secondary color (e.g., for outlines). Default: `Color3.fromRGB(255, 255, 255)`.
  - `OutlineColor` (Color3): Outline color for text and highlights. Default: `Color3.fromRGB(0, 0, 0)`.
- **`GlobalSettings`** (table): Configurable options applied to all ESP instances.
  - `TracerOrigin` (string): Origin point for tracers ("Top", "Center", "Bottom", "Left", "Right"). Default: "Bottom".
  - `ShowTracer` (boolean): Toggle tracers. Default: `true`.
  - `ShowHighlightFill` (boolean): Toggle highlight fill. Default: `true`.
  - `ShowHighlightOutline` (boolean): Toggle highlight outline. Default: `true`.
  - `ShowName` (boolean): Toggle name display. Default: `true`.
  - `ShowDistance` (boolean): Toggle distance display. Default: `true`.
  - `RainbowMode` (boolean): Enable rainbow color cycling. Default: `false`.
  - `MaxDistance` (number): Maximum render distance. Default: `math.huge`.
  - `MinDistance` (number): Minimum render distance. Default: `0`.
  - `Opacity` (number): Transparency for drawings (0-1). Default: `0.8`.
  - `LineThickness` (number): Thickness of tracer lines. Default: `1.5`.
  - `FontSize` (number): Size of text fonts. Default: `14`.
  - `AutoRemoveInvalid` (boolean): Auto-remove destroyed targets. Default: `true`.

### Methods

- **`Add(target: Instance, config: table?)`**
  - Adds ESP to a `Model` or `BasePart`.
  - **Parameters:**
    - `target`: The instance to track.
    - `config` (optional): Table with `Name` (string) and `Color` (Color3).
  - **Example:**
    ```lua
    ESP:Add(workspace.SomeModel, {Name = "Enemy", Color = Color3.fromRGB(255, 0, 0)})
    ```

- **`AddEntities2D(target: Model, config: table?)`**
  - Specialized for 2D entities: Adds a fake humanoid and sets part transparencies.
  - **Parameters:** Same as `Add`.
  - **Example:**
    ```lua
    ESP:AddEntities2D(workspace.FlatEntity, {Name = "2D Target"})
    ```

- **`Remove(target: Instance)`**
  - Removes ESP from a specific target.
  - **Example:**
    ```lua
    ESP:Remove(workspace.SomeModel)
    ```

- **`Clear()`**
  - Removes all active ESP instances.
  - **Example:**
    ```lua
    ESP:Clear()
    ```

- **`UpdateGlobalSettings()`**
  - Applies global settings changes to all active ESPs. Called internally by setters.

- **`SetGlobalTracerOrigin(origin: string)`**
  - Sets the tracer origin globally.
  - **Example:**
    ```lua
    ESP:SetGlobalTracerOrigin("Center")
    ```

- **`SetGlobalESPType(typeName: string, enabled: boolean)`**
  - Toggles a global setting (e.g., "ShowTracer").
  - **Example:**
    ```lua
    ESP:SetGlobalESPType("ShowName", false)
    ```

- **`SetGlobalRainbow(enable: boolean)`**
  - Enables/disables rainbow mode.
  - **Example:**
    ```lua
    ESP:SetGlobalRainbow(true)
    ```

- **`SetGlobalOpacity(value: number)`**
  - Sets global opacity (clamped 0-1).
  - **Example:**
    ```lua
    ESP:SetGlobalOpacity(0.5)
    ```

- **`SetGlobalFontSize(size: number)`**
  - Sets global font size (min 10).
  - **Example:**
    ```lua
    ESP:SetGlobalFontSize(16)
    ```

- **`SetGlobalLineThickness(thick: number)`**
  - Sets global line thickness (min 1).
  - **Example:**
    ```lua
    ESP:SetGlobalLineThickness(2)
    ```

### Internal Functions (Not for Direct Use)

- `getRainbowColor(t: number)`: Generates rainbow Color3 based on time.
- `tracerOrigins`: Table of functions for origin positions.
- `getModelCenter(model: Model)`: Calculates average position of visible parts.
- `createDrawing(class: string, props: table)`: Creates and configures a Drawing object.

## Configuration Examples

### Basic Setup

```lua
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()

ESP.Theme.PrimaryColor = Color3.fromRGB(0, 255, 0)  -- Green theme
ESP.GlobalSettings.MaxDistance = 500  -- Limit to 500 studs

ESP:Add(workspace.PlayerModel, {Name = "Player"})
```

### Advanced Customization

```lua
ESP:SetGlobalRainbow(true)
ESP:SetGlobalTracerOrigin("Top")
ESP:SetGlobalESPType("ShowDistance", false)
ESP:SetGlobalOpacity(0.9)
ESP:SetGlobalFontSize(12)
ESP:SetGlobalLineThickness(1)

-- Add multiple targets
for _, model in ipairs(workspace.Enemies:GetChildren()) do
    ESP:Add(model, {Color = Color3.fromRGB(255, 0, 0)})
end
```

## Performance Considerations

- The library uses `RunService.RenderStepped` for updates, ensuring smooth rendering.
- Limit the number of tracked objects to avoid performance hits in large games.
- Highlights use Roblox's native instances, which are efficient but may impact older devices if overused.

## Troubleshooting

- **ESP Not Showing:** Ensure `Enabled` is `true` and the target is within distance thresholds.
- **Invalid Targets:** Use `AutoRemoveInvalid` to clean up automatically.
- **Color Issues:** Rainbow mode overrides per-target colors.
- **Compatibility:** Tested on Roblox Lua 5.1; may require adjustments for non-standard environments.

## License

This library is released under the MIT License. See [LICENSE](LICENSE) for details.

## Credits

- **Author:** DH_SOARES
- Inspired by common Roblox ESP patterns, optimized for minimalism.

For issues or contributions, visit the [GitHub repository](https://github.com/DH-SOARESE/Kolt-DOORS).
