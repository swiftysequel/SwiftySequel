import MySqlClient

public class MySqlConnection {
    public enum Error: Swift.Error {
        case mySql(error: MySqlError)
        case alreadyConnected
        case connectionFailed
        case notConnected
        case unknown
    }

    public enum State {
        case connecting
        case connected
        case connectionLost
        case disconnecting
        case disconnected
    }

    public struct ServerInfo {
        public let version: String
        public let versionNumber: String
    }

    public struct MySqlError {
        public let code: Int
        public let message: String
    }

    private let host: String
    private let username: String
    private let password: String?
    private let port: UInt32
    private let characterSet: MySql.CharacterSet
    private var connection: UnsafeMutablePointer<MYSQL>?
    public private(set) var serverInfo: ServerInfo?
    public private(set) var selectedDatabase: String?

    private var state: State = .disconnected {
        didSet {
            print("[MySqlConnection] New state: \(self.state)")
        }
    }

    public required init(
        host: String,
        username: String,
        password: String? = nil,
        port: UInt32 = 0,
        characterSet: MySql.CharacterSet = .latin1
    ) throws {
        self.host = host
        self.username = username
        self.password = password
        self.port = port
        self.characterSet = characterSet

        try self.connect()
    }

    deinit {
        self.disconnect()
    }

    public func clientVersion() -> String? {
        String(cString: mysql_get_client_info(), encoding: self.characterSet.stringEncoding)
    }

    public func lastError() -> MySqlError? {
        try? self.performIfConnected { connection in
            let errorCode = mysql_errno(connection)
            if errorCode == 0 {
                return nil
            }

            var errorMessage: String?
            if let rawErrorMessage = mysql_error(connection) {
                errorMessage = String(cString: rawErrorMessage, encoding: self.characterSet.stringEncoding)
            }

            return MySqlError(code: Int(errorCode), message: errorMessage ?? "")
        }
    }

    public func ping() -> Bool {
        let result = try? self.performIfConnected { mysql_ping($0) == 0 }

        return result ?? false
    }

    public func listDatabases(wildcard: String? = nil) -> [String] {
        self.fetchStringColumn { mysql_list_dbs($0, wildcard) }
    }

    public func selectDatabase(named databaseName: String) throws {
        self.selectedDatabase = nil
        let wasSuccessful = try self.performIfConnected { mysql_select_db($0, databaseName) == 0 }
        if !wasSuccessful {
            throw self.throwableLastError()
        }

        self.selectedDatabase = databaseName
    }

    public func listTables(wildcard: String? = nil) -> [String] {
        self.fetchStringColumn { mysql_list_tables($0, wildcard) }
    }

    public func commit() throws {
        let wasSuccessful = try self.performIfConnected { mysql_commit($0) }
        if !wasSuccessful {
            throw self.throwableLastError()
        }
    }

    public func rollback() throws {
        let wasSuccessful = try self.performIfConnected { mysql_rollback($0) }
        if !wasSuccessful {
            throw self.throwableLastError()
        }
    }

    public func query(_ statement: String) throws {
        let wasSuccessful = try self.performIfConnected { mysql_real_query($0, statement, UInt(statement.count)) == 0 }
        if !wasSuccessful {
            throw self.throwableLastError()
        }
    }

    public func hasMoreResults() throws -> Bool {
        try self.performIfConnected { mysql_more_results($0) }
    }

    public func nextResult() throws -> Int {
        try self.performIfConnected { Int(mysql_next_result($0)) }
    }

    public func lastInsertId() throws -> Int64 {
        try self.performIfConnected { Int64(mysql_insert_id($0)) }
    }

    public func numberOfAffectedRows() throws -> Int64 {
        try self.performIfConnected { Int64(mysql_affected_rows($0)) }
    }

    private func connect() throws {
        guard self.state == .disconnected else {
            throw Error.alreadyConnected
        }

        self.state = .connecting

        guard let connection = mysql_init(nil) else {
            self.state = .disconnected

            throw Error.connectionFailed
        }
        let connectionStatus = mysql_real_connect(
            connection,
            self.host,
            self.username,
            self.password,
            nil,
            self.port,
            nil,
            0
        )
        guard connectionStatus == connection else {
            self.state = .disconnected

            throw Error.connectionFailed
        }

        self.connection = connection
        self.state = .connected

        // TODO: Check for user interrupt

        if
            let rawServerInfo = mysql_get_server_info(connection),
            // Always use `latin1` encoding here, because no charset has been configured and `latin1` is the most robust
            let serverInfo = String(cString: rawServerInfo, encoding: .isoLatin1)
        {
            self.serverInfo = ServerInfo(
                version: serverInfo,
                versionNumber: String(mysql_get_server_version(connection))
            )
        }
    }

    private func disconnect() {
        guard self.state == .connected || self.state == .connecting else {
            return
        }

        self.state = .disconnecting

        if let connection = self.connection, connection.pointee.net.reading_or_writing == 0 {
            mysql_close(connection)
            self.connection = nil
        }

        self.serverInfo = nil
        self.state = .disconnected
    }

    private func performIfConnected<T>(_ callback: (UnsafeMutablePointer<MYSQL>) -> T) throws -> T {
        guard self.state == .connected, let connection = self.connection else {
            throw Error.notConnected
        }

        return callback(connection)
    }

    private func fetchStringColumn(
        _ fetchResult: (UnsafeMutablePointer<MYSQL>) -> UnsafeMutablePointer<MYSQL_RES>?
    ) -> [String] {
        let column = try? self.performIfConnected { connection -> [String]? in
            guard let rawResult = fetchResult(connection) else {
                return nil
            }

            defer {
                mysql_free_result(rawResult)
            }

            var result: [String] = []
            let encoding = self.characterSet.stringEncoding
            while let row = mysql_fetch_row(rawResult) {
                if let cellPointer = row[0], let cell = String(cString: cellPointer, encoding: encoding) {
                    result.append(cell)
                }
            }

            return result
        }

        return column ?? []
    }

    private func throwableLastError() -> Error {
        guard let error = self.lastError() else {
            return .unknown
        }

        return .mySql(error: error)
    }
}
