# Proposal: Polymod HTML5 Adaptation

## Intent

Polymod mod loading only works on native. On HTML5, `ZipFileSystem` → `MemoryZipFileSystem`, but nobody feeds it zip bytes. The preloader's `InitializingScripts` stub was built for this but never wired. We need mods on web.

## Scope

### In Scope
1. **Postbuild.hx** — After HTML5 build, zip each mod dir, bundle into `mods.zip` in export dir
2. **WebModLoader.hx** (NEW) — Static class: HTTP GET `mods.zip`, parse with `haxe.zip.Reader`, call `MemoryZipFileSystem.addZipFile()` per inner entry
3. **PolymodHandler.hx** — Add async init for web; use `MemoryZipFileSystem` via WebModLoader; native path unchanged
4. **Main.hx** — On HTML5, skip synchronous `loadAllMods()` (defer to preloader)
5. **FunkinPreloader.hx** — Wire `InitializingScripts`: fetch mods.zip, track progress, init Polymod, advance

### Out of Scope
- Hot-reload on web; mod config UI on web; compressed entry handling (already handled by Polymod); multi-file download

## Capabilities

### New Capabilities
- `web-mod-loading`: Loading Polymod mods on HTML5 via remote `mods.zip` fetch and memory filesystem injection

### Modified Capabilities
- None

## Approach

**Postbuild**: `source/Postbuild.hx` detects HTML5 target, scans `mods/`, creates individual zips per mod dir with `haxe.zip.Writer`, bundles into `mods.zip`, writes to export folder.

**Preloader**: `FunkinPreloader` in `InitializingScripts` calls `WebModLoader.fetchMods()` (HTTP GET). Progress updates `initializingScriptsPercent`. On complete, `WebModLoader.loadModsIntoFS()` iterates inner entries, calls `addZipFile()` per mod. `PolymodHandler.initAsync()` calls `Polymod.init()` with populated filesystem. Preloader advances.

**Native**: unchanged — all `#if sys` guards stay.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `source/Postbuild.hx` | Modified | HTML5 mods.zip generation |
| `source/Main.hx` | Modified | Skip loadAllMods on HTML5 (line 71) |
| `source/funkin/modding/PolymodHandler.hx` | Modified | Add `initAsync()`, guard native code |
| `source/funkin/ui/transition/preload/FunkinPreloader.hx` | Modified | Wire InitializingScripts |
| `source/funkin/modding/WebModLoader.hx` | **New** | HTTP fetch + FS population |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Large mods.zip = slow download | Medium | Preloader tracks progress; pattern exists |
| haxe.zip parse failures | Low | Polymod uses same parser on native |
| Postbuild path resolution | Low | Reuse MOD_FOLDER logic from PolymodHandler |

## Rollback Plan

Revert Main.hx, FunkinPreloader.hx, PolymodHandler.hx; delete WebModLoader.hx and mods.zip. Each step independent. Postbuild change is `#if html5` guarded — no native impact.

## Dependencies

Haxe std (`haxe.zip.Reader/Writer`), Polymod 1.8.0 (`MemoryZipFileSystem.addZipFile`), HTTP client (`lime.app.Future` or `openfl.net.URLLoader`).

## Success Criteria

- [ ] Postbuild generates valid `mods.zip` in HTML5 export dir
- [ ] WebModLoader fetches `mods.zip` (200 OK)
- [ ] MemoryZipFileSystem populates with mod entries
- [ ] Polymod.init() succeeds on HTML5 with memory filesystem
- [ ] Preloader shows progress during fetch, advances past InitializingScripts
- [ ] Game loads with mods on HTML5; native builds unaffected
