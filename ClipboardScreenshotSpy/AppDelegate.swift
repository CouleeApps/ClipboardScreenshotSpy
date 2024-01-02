//
//  AppDelegate.swift
//  ClipboardScreenshotSpy
//
//  Created by Glenn Smith on 12/31/23.
//

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

