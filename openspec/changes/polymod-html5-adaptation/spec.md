# web-mod-loading Specification

## Purpose

Enable Polymod mod loading on HTML5/web targets with a build-time packaging step and a runtime HTTP-fetch + memory-filesystem injection pipeline. Native platforms remain unchanged.

## Requirements

### Build-time: Postbuild Packaging

| ID | Requirement | Strength |
|----|-------------|----------|
| R1 | After an HTML5 build, scan `mods/` for mod subdirectories. | MUST |
| R2 | Each mod subdirectory MUST be individually zipped via `haxe.zip.Writer`. | MUST |
| R3 | All individual mod zips MUST be bundled into a single `mods.zip`. | MUST |
| R4 | `mods.zip` MUST be placed in the HTML5 export directory alongside the built game. | MUST |

#### Scenario: Mods present (R1-R4 happy path)
- GIVEN an HTML5 build completes and `mods/` contains subdirectories
- WHEN Postbuild runs
- THEN each mod is zipped individually and bundled into `mods.zip` in the export dir

#### Scenario: Empty mods directory (R1-R4 edge)
- GIVEN `mods/` is empty
- WHEN Postbuild runs
- THEN no `mods.zip` is created and the build is not interrupted

#### Scenario: Native build (R1-R4 guard)
- GIVEN a non-HTML5 build target
- WHEN Postbuild runs
- THEN the mods.zip logic is SKIPPED entirely

### Runtime: WebModLoader

| ID | Requirement | Strength |
|----|-------------|----------|
| R5 | Fetch `mods.zip` via HTTP at a configurable URL (default: relative to game URL). | MUST |
| R6 | Parse fetched `mods.zip` with `haxe.zip.Reader`. | MUST |
| R7 | Extract each inner mod zip and pass to `MemoryZipFileSystem.addZipFile()`. | MUST |
| R8 | Loading MUST use async I/O with a completion callback pattern. | MUST |
| R9 | On failure (missing/corrupt mods.zip), log a warning and complete with no mods — never crash. | MUST |

#### Scenario: Successful fetch (R5-R8 happy path)
- GIVEN the game runs on HTML5 and `mods.zip` exists on server
- WHEN `WebModLoader.fetchMods()` is called
- THEN it GETs `mods.zip`, parses it, injects each mod into MemoryZipFileSystem, and fires the completion callback

#### Scenario: 404 or corrupt mods.zip (R9 error)
- GIVEN the server returns 404 or the zip is corrupt
- WHEN `fetchMods()` runs
- THEN a warning is logged, callback fires with no mods, game continues booting

### Integration: PolymodHandler, Main, Preloader

| ID | Requirement | Strength |
|----|-------------|----------|
| R10 | On web, PolymodHandler MUST use WebModLoader to populate the filesystem before `Polymod.init()`. | MUST |
| R11 | On native, keep existing behavior: `SysZipFileSystem` with `autoScan:true`. | MUST |
| R12 | Add `loadModsAsync(callback)` for async initialization. | MUST |
| R13 | The memory filesystem MUST be fully populated before `Polymod.init()` is called. | MUST |
| R14 | On HTML5, `Main.hx` MUST skip synchronous `loadAllMods()`/`loadNoMods()` in its constructor. | MUST |
| R15 | Polymod init on web MUST be deferred to the preloader. | MUST |
| R16 | During `InitializingScripts`, FunkinPreloader MUST call `WebModLoader.fetchMods()`. | MUST |
| R17 | The preloader SHOULD track download progress during fetch. | SHOULD |
| R18 | After mods load, preloader MUST init Polymod via `PolymodHandler.loadModsAsync()`. | MUST |
| R19 | After Polymod init, preloader MUST advance to `CachingGraphics`. | MUST |
| R20 | If mods are unavailable, preloader MUST log warning and continue without mods. | MUST |

#### Scenario: Full web boot (R10, R12-R19 happy path)
- GIVEN the game runs on HTML5 with mods available
- WHEN preloader reaches `InitializingScripts`
- THEN it fetches `mods.zip`, tracks progress, injects mods into MemoryZipFileSystem
- AND calls `PolymodHandler.loadModsAsync()`, `Polymod.init()` succeeds
- AND preloader advances to `CachingGraphics`

#### Scenario: Native unchanged (R11, R14 guard)
- GIVEN the game runs on native (linux, windows, mac, android, ios)
- WHEN `Main.hx` constructor executes
- THEN it calls `loadAllMods()`/`loadNoMods()` synchronously (existing behavior)
- AND PolymodHandler uses `SysZipFileSystem`
- AND no HTTP fetch occurs

#### Scenario: HTML5 skips sync init (R14-R15)
- GIVEN the game runs on HTML5
- WHEN `Main.hx` constructor executes
- THEN it skips `loadAllMods()` and `loadNoMods()`
- AND Polymod init is deferred to preloader

#### Scenario: Preloader recovers from missing mods (R20)
- GIVEN `mods.zip` is missing or corrupt
- WHEN `InitializingScripts` completes
- THEN a warning is logged, game continues to `CachingGraphics` without mods
