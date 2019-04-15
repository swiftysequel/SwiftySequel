import AppKit

@NSApplicationMain
public class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet public weak var window: NSWindow!

    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")

            return .terminateCancel
        }

        if !context.hasChanges {
            return .terminateNow
        }

        do {
            try context.save()
        } catch {
            if sender.presentError(error as NSError) {
                return .terminateCancel
            }

            let alert = NSAlert()
            alert.messageText = "Could not save changes while quitting. Quit anyway?"
            alert.informativeText = "Quitting now will lose any changes you have made since the last successful save"
            alert.addButton(withTitle: "Quit anyway")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }

        return .terminateNow
    }

    public func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data

    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SwiftySequel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }

        return container
    }()

    @IBAction private func saveAction(_ sender: AnyObject?) {
        let context = persistentContainer.viewContext
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                NSApplication.shared.presentError(error as NSError)
            }
        }
    }

    public func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        return persistentContainer.viewContext.undoManager
    }
}
