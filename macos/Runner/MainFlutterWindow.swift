import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // No chrome above the page. The title bar is transparent and unnamed, and
    // the window background is Seedling's paper, so all that remains is the
    // three traffic lights sitting on the same colour as the page.
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.backgroundColor = NSColor(
      srgbRed: 0xF9 / 255.0, green: 0xF5 / 255.0, blue: 0xEC / 255.0, alpha: 1)
    self.isMovableByWindowBackground = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
