#if File
    import ISO_14496_22
    import Testing
    import Typesetting
    import Typesetting_File

    @Suite
    struct `File Tests` {
        @Test
        func `a file that is not there gives no font, and says it could not be read`() throws {
            do throws(Typesetting.File.Error) {
                _ = try ISO.`14496`.`22`.FontFile(reading: "/no/such/font.ttf")
                Issue.record("a font was read")
            } catch {
                guard case .read = error else {
                    Issue.record("\(error)")
                    return
                }
            }
        }
    }
#endif
