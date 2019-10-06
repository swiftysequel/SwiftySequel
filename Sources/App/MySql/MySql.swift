public enum MySql {
    public enum CharacterSet {
        case latin1

        public var stringEncoding: String.Encoding {
            return .isoLatin1
        }
    }
}
