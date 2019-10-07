import Foundation
import MySqlClient

extension MySql {
    internal struct DatabaseDefinition {
        internal let name: String
    }

    internal struct TableDefinition {
        internal let name: String
        internal let database: DatabaseDefinition
    }

    internal enum FieldType {
        case int(length: Int)
        case varchar(length: Int)

        internal init?(rawType: enum_field_types) {
            switch rawType {
                case MYSQL_TYPE_LONG:
                    self = .int(length: 11)
                case MYSQL_TYPE_VARCHAR:
                    self = .varchar(length: 255)
                default:
                    return nil
            }
        }
    }

    internal struct FieldDefinition {
        internal let name: String
        internal let type: FieldType
        internal let defaultValue: String?
        internal let characterSet: CharacterSet
        internal let table: TableDefinition?

        internal static func make(
            fromMySqlField field: MYSQL_FIELD,
            usingStringEncoding stringEncoding: String.Encoding
        ) -> Self? {
            guard
                let name = String.make(fromCString: field.name, length: field.name_length, encoding: stringEncoding),
                let type = FieldType(rawType: field.type),
                let defaultValue = String.make(fromCString: field.def, length: field.def_length, encoding: stringEncoding)
            else {
                return nil
            }

            var table: TableDefinition?
            if field.table_length > 0 {
                guard
                    let tableName = String.make(fromCString: field.table, length: field.table_length, encoding: stringEncoding),
                    let databaseName = String.make(fromCString: field.db, length: field.db_length, encoding: stringEncoding)
                else {
                    return nil
                }

                table = TableDefinition(name: tableName, database: DatabaseDefinition(name: databaseName))
            }

            return FieldDefinition(
                name: name,
                type: .int(length: 11),
                defaultValue: defaultValue,
                characterSet: .latin1,
                table: table
            )
        }
    }
}

internal class MySqlResult {
    internal let numberOfFields: Int
    internal let numberOfRows: Int
    internal let fieldDefinitions: [MySql.FieldDefinition]

    internal var fieldNames: [String] {
        self.fieldDefinitions.map { $0.name }
    }

    private let result: UnsafeMutablePointer<MYSQL_RES>
    private let stringEncoding: String.Encoding
    private var currentRowIndex: Int = 0

    internal init(result: UnsafeMutablePointer<MYSQL_RES>, stringEncoding: String.Encoding = .ascii) {
        self.result = result
        self.stringEncoding = stringEncoding
        self.numberOfFields = Int(mysql_num_fields(self.result))
        self.numberOfRows = Int(mysql_num_rows(self.result))

        let rawFields = mysql_fetch_fields(self.result)
        var fieldDefinitions: [MySql.FieldDefinition] = []
        for fieldIndex in 0..<self.numberOfFields {
            if
                let rawField = rawFields?[fieldIndex],
                let field = MySql.FieldDefinition.make(fromMySqlField: rawField, usingStringEncoding: self.stringEncoding)
            {
                fieldDefinitions.append(field)
            }
        }
        self.fieldDefinitions = fieldDefinitions
    }
}

extension String {
    fileprivate static func make(fromCString cString: UnsafePointer<Int8>?, length: UInt32, encoding: String.Encoding) -> String? {
        guard let cString = cString else {
            return nil
        }

        return String(data: Data(bytes: cString, count: Int(length)), encoding: encoding)
    }
}
