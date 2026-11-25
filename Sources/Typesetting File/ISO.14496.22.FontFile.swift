#if File
    import File_System
    public import ISO_14496_22
    public import Path
    public import Typesetting

    extension ISO.`14496`.`22`.FontFile {
        /// The font in the file at `path`, read whole.
        public init(reading path: Path) throws(Typesetting.File.Error) {
            let bytes: [Byte]
            do throws(File_System::File.System.Read.Full.Error) {
                bytes = try File_System::File(path).read.bytes()
            } catch {
                throw .read(error)
            }
            do throws(ParsingError) {
                try self.init(data: bytes)
            } catch {
                throw .font(error)
            }
        }

        /// The font in the file at the path `text` spells, read whole.
        public init(reading text: Swift.String) throws(Typesetting.File.Error) {
            let path: Path
            do throws(Path.Error) {
                path = try Path(validating: text)
            } catch {
                throw .path(error)
            }
            try self.init(reading: path)
        }
    }
#endif
