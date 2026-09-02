# CodexUI API — Clean Source

CodexUI is the maintained CodexAlpha fork of the UI library used by Codex Alpha projects. This package keeps only the files needed to use, edit, and build the API.

- `dist/main.lua` — production single-file build used by `loadstring`.
- `src/` — CodexUI runtime/API source.
- `build/` — build scripts/config and generated package metadata required by `src/Init.lua`.
- `main.client.lua` — single maintained API example.
- `package.json` / `package-lock.json` — Node development scripts/dependencies.
- `aftman.toml` — DarkLua/Rojo toolchain versions.
- `LICENSE` — MIT license and original copyright notice.

## Attribution

CodexUI is a modified fork of MIT-licensed software originally copyrighted by Footages. The original MIT copyright and permission notice are preserved in `LICENSE`; do not remove them when redistributing substantial portions of the software.

Repository branding, runtime names, storage folders, examples, package metadata, and maintained UI labels use **CodexUI** / **CodexAlpha**.

## Native APIs added in v1.7.0

CodexUI v1.7.0 adds flagged config persistence (`Window:Config`), element lookup (`Window:GetElement`), tracked cleanup (`Track` / `OnCleanup`), opt-in lazy tab building (`Lazy` + `Build`), notification `Id` / `Replace` / `Queue`, and runtime theme editing with `CodexUI:EditTheme`. Existing eager tab/element APIs remain supported. See `main.client.lua` for compact examples.

## Standalone UI (no window required)

Standalone surfaces can be shown immediately after loading CodexUI. They do not require `CodexUI:CreateWindow()`.

```lua
local Loading = CodexUI:Loading({
	Id = "loader",
	Title = "ByteCode Loader",
	Status = "Validating access...",
	Progress = 0,
})

Loading:SetProgress(0.5, "Downloading source...")
Loading:SetStep(3, 4, "Starting script...")
Loading:Complete("Ready!")

CodexUI:Announcement({
	Author = "System",
	Message = "A new version is available.",
})

CodexUI:Limit({
	Title = "Usage limits",
	Daily = { Used = 8, Limit = 10 },
	Weekly = { Used = 42, Limit = 50 },
	Buttons = {
		{ Title = "Close", Primary = false },
	},
})
```

`CodexUI:Info()` is the generic standalone information surface. Standalone surfaces reuse the Key System's lightweight visual structure: one transparent `PopupBackground` squircle, radius 26, padding 16, spacing 18, and the shared Button component. Their surface transparency follows `StandaloneBackgroundTransparency`, then the active theme's positive `ElementBackgroundTransparency`, and finally defaults to `0.55`; a theme is not required. Use `Transparent = false` for a solid surface or tune `Transparency` per surface. Loading and information controllers support `Close()` / `Destroy()`, and matching `Id` values replace older surfaces by default.
