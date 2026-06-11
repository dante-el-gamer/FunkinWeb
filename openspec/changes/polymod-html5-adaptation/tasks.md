# Tasks: Polymod HTML5 Adaptation

## Review Workload Forecast

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: single-pr
400-line budget risk: Low

| Field | Value |
|-------|-------|
| Estimated changed lines | ~250 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |

## Phase 1: Build-Time Packaging (Postbuild)

- [x] 1.1 In `source/Postbuild.hx`, add `generateModsZip()` that scans `mods/` subdirs at project root
- [x] 1.2 For each mod subdir, create an individual zip via `haxe.zip.Writer` with `haxe.zip.Entry` per file
- [x] 1.3 Bundle all individual mod zips into a single outer `mods.zip`
- [x] 1.4 Write `mods.zip` to the HTML5 export dir: check `export/release/html5/bin/` then `export/debug/html5/bin/`; fallback to project root if neither exists
- [x] 1.5 Guard: skip if `mods/` is empty or absent; log status either way
- [x] 1.6 Wire `generateModsZip()` into the existing `main()` alongside `printBuildTime()`

## Phase 2: WebModLoader Runtime (NEW)

- [x] 2.1 Create `source/funkin/modding/WebModLoader.hx` with singleton pattern and `#if html5` guard
- [x] 2.2 Implement `loadMods(onComplete:Void->Void)` that fetches `mods.zip` via XMLHttpRequest
- [x] 2.3 Parse fetched bytes with `haxe.zip.Reader` into entry list
- [x] 2.4 For each inner entry, call `MemoryZipFileSystem.addZipFile(zipName, zipBytes)` to populate the filesystem
- [x] 2.5 Implement `getModFileSystem():MemoryZipFileSystem` returning the populated filesystem
- [x] 2.6 Handle 404/corrupt gracefully: log warning, fire callback, never crash
- [x] 2.7 Support a configurable fetch URL (default: `mods.zip` relative to game URL)

## Phase 3: PolymodHandler Web Integration

- [x] 3.1 In `source/funkin/modding/PolymodHandler.hx`, import `WebModLoader`
- [x] 3.2 Add `loadModsAsync(onComplete:Void->Void)` guarded by `#if html5` — calls `WebModLoader.loadMods()`, then `loadAllMods()` on completion
- [x] 3.3 Modify `buildFileSystem()`: return `WebModLoader.getModFileSystem()` when `#if html5`, keep existing `ZipFileSystem` otherwise
- [x] 3.4 On native, keep `SysZipFileSystem` with `autoScan:true` unchanged

## Phase 4: Main.hx Sync Loading Guard

- [x] 4.1 In `source/Main.hx` constructor, wrap `PolymodHandler.loadAllMods()` in `#if !html5` so web skips synchronous mod init

## Phase 5: Preloader Async Mod Loading

- [x] 5.1 In `source/funkin/ui/transition/preload/FunkinPreloader.hx`, in `InitializingScripts` state: on web (`#if html5`), call `PolymodHandler.loadModsAsync()` with simulated progress
- [x] 5.2 On fetch completion, `loadModsAsync` internally triggers `loadAllMods()` via callback
- [x] 5.3 On failure, log warning and advance to `CachingGraphics` without mods
- [x] 5.4 On native, keep existing stub behavior (no-op, immediate advance)
