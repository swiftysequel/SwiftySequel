import AppKit

@NSApplicationMain
internal class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet internal weak var window: NSWindow!
    @IBOutlet private weak var databaseSelectionToolbarItem: NSToolbarItem!
    @IBOutlet private weak var databaseSelectionPopUpButton: NSPopUpButton!
    @IBOutlet private weak var tableStructureToolbarItem: NSToolbarItem!
    @IBOutlet private weak var tableContentToolbarItem: NSToolbarItem!
    @IBOutlet private weak var queryEditorToolbarItem: NSToolbarItem!
    @IBOutlet private weak var consoleToolbarItem: NSToolbarItem!

    private var connection: MySqlConnection?

    internal func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.databaseSelectionPopUpButton.setTitle("Select database...")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.databaseSelectionWillPopUp),
            name: NSPopUpButton.willPopUpNotification,
            object: self.databaseSelectionPopUpButton
        )

        self.connection = try? MySqlConnection(host: "127.0.0.1", username: "root")
    }

    internal func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
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

    internal func applicationWillTerminate(_ aNotification: Notification) {
        self.connection = nil
    }

    // MARK: - Core Data

    internal lazy var persistentContainer: NSPersistentContainer = {
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

    internal func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        return persistentContainer.viewContext.undoManager
    }

    // MARK: - IBActions

    @IBAction private func databaseSelectionToolbarItemChanged(_ sender: NSPopUpButton) {
        guard let selectedDatabase = self.databaseSelectionPopUpButton.titleOfSelectedItem else {
            self.databaseSelectionPopUpButton.setTitle("Select database...")

            return
        }

        self.databaseSelectionPopUpButton.synchronizeTitleAndSelectedItem()
        print("Display tables of database \(selectedDatabase)")
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

    // MARK: - Notification callbacks

    @objc
    private func databaseSelectionWillPopUp(_ notification: NSNotification) {
        // Refresh the list of available databases
        self.databaseSelectionPopUpButton.removeAllItems()
        self.databaseSelectionPopUpButton.setTitle("Select database...")
        self.databaseSelectionPopUpButton.addItems(withTitles: self.connection?.listDatabases() ?? [])
    }
}
