# Design: Polymod HTML5 Adaptation

## Technical Approach

Build-time packaging of mod directories into `mods.zip` via Postbuild, plus a runtime `WebModLoader` that fetches and injects mods into a `MemoryZipFileSystem` before `Polymod.init()`. Native paths untouched — `#if html5` guards everywhere. Async loading hooks into the existing preloader state machine.

## Architecture Decisions

### Decision: Postbuild mod packaging strategy

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Zip each mod + bundle into outer `mods.zip` | `MemoryZipFileSystem.addZipFile()` requires one zip per mod; outer zip gives single HTTP fetch | **Chosen** — matches `MemoryZipFileSystem` API, single fetch |
| Modify `MemoryZipFileSystem` to scan directories | Would require Haxe sys.FileSystem which doesn't exist on web | Rejected — breaks Polymod's cross-platform abstraction |
| Bundle mod files directly into outer zip | Would require rewriting `addZipFile()` or manual MemoryFileSystem population | Rejected — more coupling, less reusable |

### Decision: Async loading in preloader

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Sub-state machine within InitializingScripts | Adds complexity but gives real progress | **Chosen** — start+complete callback, simulated progress |
| Blocking fetch in Main.hx constructor | Simplest but freezes preloader UX | Rejected — bad UX on slow connections |
| External preloader phase before everything | Bigger refactor, touches preloader lifecycle | Rejected — `InitializingScripts` exists for this purpose |

### Decision: Export path detection

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Hardcode `export/release/html5/bin/` | Fragile if user changes build target | **Chosen** for now — matches existing `scripts/Postbuild.hx` reference |
| Pass as Lime build define | More robust but needs Lime build config changes | Future improvement — tracked |

## Data Flow

```
Build time:
  mods/introMod/ ──┐
  mods/testing123/ ─┤── haxe.zip.Writer ──→ mods.zip → export/release/html5/bin/
                   │
  example_mods/ ───┘  (fallback if mods/ absent)

Runtime (web):
  browser ──fetch("mods.zip")──→ WebModLoader
                                      │
                                      ▼
                              haxe.zip.Reader
                                      │
                                  [foreach entry]
                                      │
                                      ▼
                              MemoryZipFileSystem.addZipFile()
                                      │
                                      ▼
                              Polymod.init({ customFilesystem: fs })
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `source/Postbuild.hx` | Modify | Add `generateModsZip()` — scans mod dirs, zips individually, bundles into outer `mods.zip`, writes to export dir. Guarded by `#if html5`. |
| `source/funkin/modding/WebModLoader.hx` | Create | Singleton that fetches `mods.zip`, parses with `haxe.zip.Reader`, populates `MemoryZipFileSystem` via `addZipFile()`. Completion callback pattern. |
| `source/funkin/modding/PolymodHandler.hx` | Modify | `buildFileSystem()` returns `WebModLoader.getModFileSystem()` on html5. Add `loadModsAsync()` with callback. |
| `source/Main.hx` | Modify | Wrap `loadAllMods()` in `#if !html5`. |
| `source/funkin/ui/transition/preload/FunkinPreloader.hx` | Modify | Replace `InitializingScripts` stub — start async mod load, simulate progress, advance on completion. Guard by `#if html5`. |

## Interfaces / Contracts

```haxe
// WebModLoader.hx — new public API
class WebModLoader {
    static function loadMods(onComplete:Void->Void, onError:String->Void):Void;
    static function getModFileSystem():MemoryZipFileSystem;
}

// PolymodHandler.hx — additions
#if html5
public static function loadModsAsync(onComplete:Void->Void):Void;
#end

// MemoryZipFileSystem (from polymod, used but not created here)
// Signature: new MemoryZipFileSystem({ modRoot: String, autoScan: Bool })
// .addZipFile(zipName:String, zipBytes:haxe.io.Bytes):Void
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Build | Postbuild produces valid `mods.zip` | Manual: run `lime build html5`, inspect export dir, verify zip structure |
| Unit | WebModLoader parse + filesystem injection | Hard in current setup (no js/html5 test runner) — validate via manual E2E |
| Integration | Preloader advances past InitializingScripts with/without mods.zip | Manual: serve export dir, check preloader logs |
| Edge | Missing `mods.zip` (404) logs warning, game loads without mods | Manual: remove `mods.zip`, verify graceful fallback |
| Edge | Empty `mods/` directory skips zip creation, no crash | Manual: build with empty mods dir |

## Migration / Rollout

No migration required. Native behavior unchanged. Web gains new functionality behind `#if html5`. Rollback: revert the 5 files.

## Open Questions

- [ ] Confirm export path pattern — is it always `export/release/html5/bin/` or does Lime vary it per build config (debug vs release)?
- [ ] `loadScriptsAsync: true` is already set on html5 — confirm there's no ordering issue with async Polymod.init + WebModLoader timing.
- [ ] Should `loadModsAsync` handle the `Polymod.init()` call itself, or should the preloader call it separately?
