import Cocoa

internal struct DatabaseTable {
    internal let name: String
    internal let columns: [String]
    internal let contents: [[String?]]
}

internal class DatabaseViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet private weak var databaseTablesTableView: NSTableView!
    @IBOutlet private weak var tableContentsTableView: NSTableView!

    private let connection: MySqlConnection
    private var tableNames: [String] = []
    private var selectedTable: DatabaseTable?

    internal init(connection: MySqlConnection) {
        self.connection = connection

        super.init(nibName: String(describing: DatabaseViewController.self), bundle: nil)

        self.tableNames = connection.listTables()

        self.selectedTable = DatabaseTable(
            name: self.tableNames.first ?? "unknown",
            columns: ["Foo", "Bar", "Baz"],
            contents: [
                ["0", "1", nil],
                ["0", nil, "2"],
                [nil, "1", "2"],
            ]
        )
    }

    @available(*, unavailable)
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - NSOutlineViewDelegate

//    internal func outlineViewSelectionIsChanging(_ notification: Notification) {
//        print("Selection changes")
//
//        self.tableContentsTableView.tableColumns.forEach { self.tableContentsTableView.removeTableColumn($0) }
//        self.selectedTable?.columns.forEach { columnName in
//            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DatabaseContentsTableColumn-\(columnName)"))
//            column.headerCell.title = columnName
//
//            self.tableContentsTableView.addTableColumn(column)
//        }
//    }

    // MARK: - NSTableViewDataSource

    internal func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
            case self.databaseTablesTableView:
                return self.tableNames.count
            case self.tableContentsTableView:
                return self.selectedTable?.contents.count ?? 0
            default:
                fatalError("Unknown table view")
        }
    }

    // MARK: - NSTableViewDelegate

    internal func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableView {
            case self.databaseTablesTableView:
                return self.viewFor(databaseTableTableColumn: tableColumn, row: row)
            case self.tableContentsTableView:
                return self.viewFor(tableContentsTableColumn: tableColumn, row: row)
            default:
                fatalError("Unknown table view")
        }
    }

    private  func viewFor(databaseTableTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = self.databaseTablesTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DatabaseTableCell"), owner: self) as? NSTableCellView else {
            return nil
        }

        cell.textField?.stringValue = self.tableNames[row]

        return cell
    }

    private  func viewFor(tableContentsTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard
            let tableColumn = tableColumn,
            let selectedTable = self.selectedTable,
            let columnIndex = self.tableContentsTableView.tableColumns.firstIndex(of: tableColumn)
        else {
            return nil
        }

        let columnName = selectedTable.columns[columnIndex]
        let cellIdentifier = NSUserInterfaceItemIdentifier("TableContentsTableCell-\(columnName)")
        guard let cell = self.tableContentsTableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else {
            return nil
        }

        cell.textField?.stringValue = selectedTable.contents[row][columnIndex] ?? "NULL"

        return cell
    }

    internal func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {
            return
        }

        switch tableView {
            case self.databaseTablesTableView:
                let selectedTableName = self.tableNames[tableView.selectedRow]
                print("selected database: \(selectedTableName)")
            case self.tableContentsTableView:
                let selectedRow = self.selectedTable?.contents[tableView.selectedRow]
                print("selected content row: \(selectedRow ?? [])")
            default:
                fatalError("Unknown table view")
        }
    }
}
