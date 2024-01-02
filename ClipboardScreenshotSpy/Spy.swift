//
//  Spy.swift
//  ClipboardScreenshotSpy
//
//  Created by Glenn Smith on 12/31/23.
//

import Foundation
import CoreGraphics
import AppKit
import CryptoKit

func ScreenshotLocation(_ then: @escaping (URL) -> Void) {
  // https://stackoverflow.com/a/12155622
  let defaults = UserDefaults();
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

  }

  let scDefaults = UserDefaults(suiteName: "com.apple.screencapture");
  if let location = scDefaults?.string(forKey: "location") {
    let locationURL = URL(fileURLWithPath: NSString(string: location).expandingTildeInPath);
    let absolute = locationURL.absoluteURL;

    print(absolute);
    let panel = NSOpenPanel();
    panel.directoryURL = absolute;
    panel.canChooseDirectories = true;
    panel.canChooseFiles = false;
    panel.begin { response in
      if response == .OK {
        for url in panel.urls {

          do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil);
            defaults.setValue(bookmark, forKey: "PathToFolder");
            defaults.synchronize();

            ScreenshotLocation(then);
          } catch {
            NSApp.presentError(error);
          }
        }
      }
    }
  }
}

func CheckPasteboard() -> Bool {
  let board = NSPasteboard.general;
  let conts = board.types;

  if conts != nil {
    for item in conts! {
      if item.rawValue == "public.tiff" {
        let tiff = board.data(forType: item);
        if tiff != nil {
          let image = NSImage(data: tiff!);
          for rep in image!.representations {
            if let bitmap = rep as? NSBitmapImageRep {
              let value = bitmap.value(forProperty: .exifData);
              if let dict = value as? Dictionary<String, Any> {
                if let comment = dict["UserComment"] as? String {
                  if comment == "Screenshot" {
                    return true;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  return false;
}

func HashPasteboard() -> Data? {
  let board = NSPasteboard.general;
  let conts = board.types;

  if conts != nil {
    for item in conts! {
      if item.rawValue == "public.tiff" {
        if let tiff = board.data(forType: item) {
          var hash = SHA256();
          hash.update(data: tiff)
          let digest = hash.finalize();
          return Data(digest)
        }
      }
    }
  }
  return nil;
}

func SavePasteboard() {
  let board = NSPasteboard.general;
  let conts = board.types;

  if conts != nil {
    for item in conts! {
      if item.rawValue == "public.tiff" {
        if let tiff = board.data(forType: item) {
          let image = NSImage(data: tiff);
          for rep in image!.representations {
            if let bitmap = rep as? NSBitmapImageRep {
              let png = bitmap.representation(using: .png, properties: [:]);
              // Screenshot 2023-12-24 at 17.01.43
              let formatter = DateFormatter();
              formatter.dateFormat = "'Screenshot' yyyy-MM-dd 'at' HH.mm.ss'.png'";
              let name = formatter.string(from: Date());
              ScreenshotLocation { url in
                var locationURL = url;
                locationURL.append(path: name);
                do {
                  try png?.write(to: locationURL)
                } catch {
                  print(error)
                }
              }
            }
          }
        }
      }
    }
  }
}
