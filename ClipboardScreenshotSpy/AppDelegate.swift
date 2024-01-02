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
  var lastHash: Data? = nil;
  var statusBar: NSStatusBar!;
  var statusItem: NSStatusItem!;


  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    lastHash = HashPasteboard();

    NSApp.setActivationPolicy(.accessory);

    self.statusBar = NSStatusBar.system;

    self.statusItem = self.statusBar.statusItem(withLength: NSStatusItem.variableLength);
    if let button = self.statusItem.button {
      button.image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
    }
    self.statusItem.menu = self.menu;

    let timer = Timer(timeInterval: 1, repeats: true) { _ in
      if CheckPasteboard() {
        let hash = HashPasteboard();
        if self.lastHash != hash {
          self.lastHash = hash;
          print("Saving next image...");
          SavePasteboard();
        }
      }
    };
    RunLoop.current.add(timer, forMode: .default);
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

}

