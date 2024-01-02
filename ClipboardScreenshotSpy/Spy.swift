// Copyright (c) 2023 Glenn Smith

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import CoreGraphics
import AppKit
import CryptoKit
import os

/// Get a URL to which screenshots can be saved (sandbox-approved)
/// Pops a UI and everything, so URL is provided in a callback
func ScreenshotLocation(_ then: @escaping (URL) -> Void) {
  // https://stackoverflow.com/a/12155622
  let defaults = UserDefaults();

  // Try to get existing value out of prefs, if we can. Otherwise, fallback and
  // try to authorize it.
  do {
    if let bookmark = defaults.value(forKey: "PathToFolder") {
      if let data = bookmark as? Data {
        var isStale: Bool = false;
        let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &isStale);
        if url.startAccessingSecurityScopedResource() {
          then(url.absoluteURL);
          return;
        }
      }
    }
  } catch {
    // TODO: Do we have to care about errors here?
  }

  // Could not use or get saved authorization for url, so go look it up and ask
  // the user to authorize it (via open panel dialog lol)

  // Pull location screen capture prefs
  let scDefaults = UserDefaults(suiteName: "com.apple.screencapture");
  if let location = scDefaults?.string(forKey: "location") {
    let locationURL = URL(fileURLWithPath: NSString(string: location).expandingTildeInPath);
    let absolute = locationURL.absoluteURL;

    // And pop a dialog so the user can confirm access
    let panel = NSOpenPanel();
    panel.directoryURL = absolute;
    panel.canChooseDirectories = true;
    panel.canChooseFiles = false;
    panel.message = "To grant access to screenshots directory, press Open. Something something macOS sandbox :)";
    panel.begin { response in
      if response != .OK || panel.urls.isEmpty {
        NSApp.terminate(nil);
        return;
      }
      let url = panel.urls[0];
      do {
        // Save a bookmark to this url with a security scope so we can write
        // to there in the future
        let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil);
        defaults.setValue(bookmark, forKey: "PathToFolder");
        defaults.synchronize();

        then(url.absoluteURL);
      } catch {
        // TODO: How to handle errors for this
        NSApp.presentError(error);
      }
    }
  } else {
    let alert = NSAlert();
    alert.messageText = "No screenshots directory specified. Press Cmd+Shift+5 and choose a directory from the popup.";
    alert.addButton(withTitle: "Retry");
    alert.addButton(withTitle: "Exit");
    let response = alert.runModal();
    if response == .alertFirstButtonReturn {
      // Try again? Tailcall
      return ScreenshotLocation(then);
    } else if response == .alertSecondButtonReturn {
      // Exit
      NSApp.terminate(nil);
    } else {
      // ???
      NSApp.terminate(nil);
    }
  }
}

/// Determine if the current contents of the clipboard are a screenshot
func CheckPasteboard() -> NSBitmapImageRep? {
  let board = NSPasteboard.general;

  if let conts = board.types {
    for item in conts {
      // Screenshots are stored as TIFF images in the pasteboard which have an
      // EXIF user comment of "Screenshot"
      if item.rawValue == "public.tiff" {
        if let tiff = board.data(forType: item) {
          if let image = NSImage(data: tiff) {
            for rep in image.representations {
              if let bitmap = rep as? NSBitmapImageRep {
                let value = bitmap.value(forProperty: .exifData);
                if let dict = value as? Dictionary<String, Any> {
                  if let comment = dict["UserComment"] as? String {
                    if comment == "Screenshot" {
                      return bitmap;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  return nil;
}

/// SHA256 Hash of image contents of clipboard (if an image is present)
func HashPasteboard() -> Data? {
  let board = NSPasteboard.general;

  if let conts = board.types {
    for item in conts {
      if item.rawValue == "public.tiff" {
        if let tiff = board.data(forType: item) {
          var hash = SHA256();
          hash.update(data: tiff)
          let digest = hash.finalize();
          return Data(digest);
        }
      }
    }
  }
  return nil;
}

/// Save contents of image (if one exists) to screenshots location
/// Also authorizes saving to screenshots location if necessary
func SavePasteboard(bitmap: NSBitmapImageRep) {
  // In the format: Screenshot 2023-12-24 at 17.01.43.png
  // Apparently this changed from "Screen shot 2023-12-24 at 17.01.43.png" in 14.0
  let formatter = DateFormatter();
  formatter.dateFormat = "'Screenshot' yyyy-MM-dd 'at' HH.mm.ss";
  let name = formatter.string(from: Date());

  // Authorize screenshots dir and then save
  ScreenshotLocation { url in
    var locationURL = url;
    locationURL.append(path: name + ".png");

    // Dedupe if we somehow possibly conflict in the same second
    var i = 1;
    while FileManager.default.fileExists(atPath: locationURL.absoluteString) {
      locationURL = url;
      locationURL.append(path: name + " \(i).png");
      i += 1;
    }

    do {
      Logger().info("Saving image to \(locationURL.absoluteString)...");
      let png = bitmap.representation(using: .png, properties: [:]);
      try png?.write(to: locationURL);
    } catch {
      // TODO: Better way to handle errors
      NSApp.presentError(error);
    }
  }
}
