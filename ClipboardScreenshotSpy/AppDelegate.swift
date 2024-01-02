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

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet var menu: NSMenu!
  var lastChangeCount: Int!;
  var lastHash: Data!;
  var statusBar: NSStatusBar!;
  var statusItem: NSStatusItem!;

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Set up menu bar icon
    NSApp.setActivationPolicy(.accessory);
    self.statusBar = NSStatusBar.system;
    self.statusItem = self.statusBar.statusItem(withLength: NSStatusItem.variableLength);
    if let button = self.statusItem.button {
      // TODO: Do I want to use a real icon?
      button.image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil);
    }
    self.statusItem.menu = self.menu;

    // Initial state, seeded with state on startup so you don't always save the
    // clipboard contents when the app is opened
    let board = NSPasteboard.general;
    self.lastChangeCount = board.changeCount;
    self.lastHash = HashPasteboard();

    // Make sure our screenshots location is writable before starting
    ScreenshotLocation { _ in

      // Start up polling loop (the whole thing)
      let timer = Timer(timeInterval: 1, repeats: true) { _ in

        // Opimization: If the clipboard hasn't changed, don't bother checking it
        if self.lastChangeCount == board.changeCount {
          return;
        }
        self.lastChangeCount = board.changeCount;

        // If the clipboard does contain a screenshot, save it
        if let bitmap = CheckPasteboard() {
          // If the screenshot is the same one as last time, don't save a duplicate
          // TODO: Is this necessary (or even possible to fail?)
          let hash = HashPasteboard();
          if self.lastHash != hash {
            self.lastHash = hash;
            SavePasteboard(bitmap: bitmap);
          }
        }
      };
      RunLoop.current.add(timer, forMode: .default);
    }
  };
}

