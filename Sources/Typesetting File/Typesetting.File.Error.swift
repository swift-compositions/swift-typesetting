#if File
    public import File_System
    public import ISO_14496_22
    public import Path
    public import Typesetting

    extension Typesetting.File {
        /// Why a file gives no font.
        public enum Error: Swift.Error {
            case path(Path.Error)
            case read(File_System::File.System.Read.Full.Error)
            case font(ISO.`14496`.`22`.FontFile.ParsingError)
        }
    }
#endif
