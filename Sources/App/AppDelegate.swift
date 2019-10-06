import AppKit

@NSApplicationMain
public class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet public weak var window: NSWindow!
    @IBOutlet private weak var databaseSelectionToolbarItem: NSToolbarItem!
    @IBOutlet private weak var tableStructureToolbarItem: NSToolbarItem!
    @IBOutlet private weak var tableContentToolbarItem: NSToolbarItem!
    @IBOutlet private weak var queryEditorToolbarItem: NSToolbarItem!
    @IBOutlet private weak var consoleToolbarItem: NSToolbarItem!

    private var connection: MySqlConnection?

    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.connection = try? MySqlConnection(host: "127.0.0.1", username: "root")
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
        self.connection = nil
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

    // MARK: - IBActions

    @IBAction private func databaseSelectionToolbarItemChanged(_ sender: NSPopUpButton) {
        print("\(sender.title)")
    }

    @IBAction private func tableStructureToolbarItemClicked(_ sender: NSToolbarItem) {
        print("\(sender.label)")
    }

    @IBAction private func tableContentToolbarItemClicked(_ sender: NSToolbarItem) {
        print("\(sender.label)")
    }

    @IBAction private func queryEditorToolbarItemClicket(_ sender: NSToolbarItem) {
        print("\(sender.label)")
    }

    @IBAction private func consoleToolbarItemClicked(_ sender: NSToolbarItem) {
        print("\(sender.label)")
    }
}
