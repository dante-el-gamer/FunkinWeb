package funkin.modding;

import haxe.io.Bytes;
import haxe.io.Path;
import polymod.PolymodConfig;
import polymod.fs.MemoryZipFileSystem;

#if html5
import js.html.XMLHttpRequest;
import js.html.XMLHttpRequestResponseType;
#end

/**
 * Loads mods from a mods.zip file on web targets.
 * Fetches mods.zip from the server, reads the mod directories directly,
 * and populates a MemoryZipFileSystem for Polymod to use.
 *
 * The mods.zip is expected to have the structure:
 *   mods.zip/
 *     ModName/
 *       _polymod_meta.json
 *       data/...
 *       scripts/...
 *       ...
 */
class WebModLoader
{
  static var modFileSystem:MemoryZipFileSystem = null;
  static var isLoading:Bool = false;
  static var loadedModIds:Array<String> = [];

  /**
   * Start loading mods asynchronously.
   * @param onComplete Called when loading completes (success or error)
   */
  public static function loadMods(onComplete:Void->Void):Void
  {
    if (isLoading) return;
    isLoading = true;

    #if html5
    var request = new XMLHttpRequest();
    // Fetch mods.zip relative to the HTML page.
    // Place mods.zip alongside index.html for production deployment.
    request.open('GET', 'mods.zip', true);
    request.responseType = XMLHttpRequestResponseType.ARRAYBUFFER;

    request.onload = function(e)
    {
      if (request.status == 200)
      {
        var bytes = Bytes.ofData(request.response);
        parseModsZip(bytes);
        trace('WebModLoader: Successfully loaded mods.zip');
      }
      else if (request.status == 404)
      {
        trace('WebModLoader: mods.zip not found (404). Continuing without mods.');
      }
      else
      {
        trace('WebModLoader: HTTP ${request.status} when fetching mods.zip. Continuing without mods.');
      }
      isLoading = false;
      onComplete();
    };

    request.onerror = function(e)
    {
      trace('WebModLoader: Network error fetching mods.zip. Continuing without mods.');
      isLoading = false;
      onComplete();
    };

    request.send();
    #else
    trace('WebModLoader: Not on HTML5 target, skipping.');
    isLoading = false;
    onComplete();
    #end
  }

  #if html5
  static function parseModsZip(zipBytes:Bytes):Void
  {
    if (modFileSystem == null)
    {
      modFileSystem = new MemoryZipFileSystem({ modRoot: 'mods' });
    }

    var input = new haxe.io.BytesInput(zipBytes);
    var reader = new haxe.zip.Reader(input);
    var entries:List<haxe.zip.Entry>;

    try
    {
      entries = reader.read();
    }
    catch (e:Dynamic)
    {
      trace('WebModLoader: Failed to parse mods.zip: $e');
      return;
    }

    loadedModIds = [];
    var modFiles = new Map<String, Array<haxe.zip.Entry>>();

    // Group file entries by top-level directory (mod ID).
    for (entry in entries)
    {
      if (entry.fileName == '' || entry.fileName.charAt(entry.fileName.length - 1) == '/')
      {
        continue; // skip directory-only entries
      }

      var parts = entry.fileName.split('/');
      if (parts.length < 2) continue;

      var modId = parts[0]; // first path component = mod directory
      if (!modFiles.exists(modId))
      {
        modFiles.set(modId, []);
      }
      modFiles.get(modId).push(entry);
    }

    var modCount = 0;

    for (modId in modFiles.keys())
    {
      var entriesList = modFiles.get(modId);

      // Verify it has a _polymod_meta.json before registering.
      var hasMeta = false;
      for (entry in entriesList)
      {
        if (entry.fileName == modId + '/' + PolymodConfig.modMetadataFile)
        {
          hasMeta = true;
          break;
        }
      }
      if (!hasMeta)
      {
        trace('WebModLoader: Skipping "$modId" — no ${PolymodConfig.modMetadataFile} found');
        continue;
      }

      // Register all files under this mod directory.
      var modPathPrefix = modId + '/';
      for (entry in entriesList)
      {
        if (entry.fileName.indexOf(modPathPrefix) == 0)
        {
          var relativePath = entry.fileName.substring(modPathPrefix.length);
          if (relativePath == '') continue; // shouldn't happen, but just in case

          var filePath = Path.join(['mods', modId, relativePath]);
          var data = entry.data;

          // Decompress if the zip entry is stored compressed.
          if (entry.compressed)
          {
            data = polymod.util.Util.unzipBytes(data);
          }

          try
          {
            modFileSystem.addFileBytes(filePath, data);
          }
          catch (e:Dynamic)
          {
            trace('WebModLoader: Failed to register $filePath: $e');
          }
        }
      }

      loadedModIds.push(modId);
      modCount++;
      trace('WebModLoader: Loaded mod: $modId');
    }

    trace('WebModLoader: Loaded $modCount mod(s) from mods.zip.');
  }
  #end

  /**
   * Get the populated file system. Must call loadMods() first.
   */
  public static function getModFileSystem():MemoryZipFileSystem
  {
    if (modFileSystem == null)
    {
      modFileSystem = new MemoryZipFileSystem({ modRoot: 'mods' });
    }
    return modFileSystem;
  }

  /**
   * Get the list of mod IDs loaded from mods.zip.
   */
  public static function getLoadedModIds():Array<String>
  {
    return loadedModIds.copy();
  }
}
