internal enum MySql {
    internal enum CharacterSet {
        case latin1

        internal var stringEncoding: String.Encoding {
            return .isoLatin1
        }
    }
}
