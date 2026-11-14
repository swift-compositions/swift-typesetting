import ISO_14496_22_Test_Support
import Testing
import Typesetting
import Vector

extension `Typesetting Tests` {
    @Suite
    struct `Tracking and figures` {
        typealias Tests = `Typesetting Tests`

        @Test
        func `Tracking adds its share of the size after every glyph, so a line of n glyphs widens by n − 1 times it`() throws {
            let plain = try Typesetting.Text("AVA B\nAV", font: Tests.font(), size: 100)
            let tracked = try Typesetting.Text("AVA B\nAV", font: Tests.font(), size: 100, tracking: 0.05)
            #expect(tracked.lines.map(\.width) == zip(plain.lines, [4.0, 1.0]).map { $0.width + $1 * 5 })
            #expect(Tests.origins(tracked) == [[0, 0], [55, 0], [115, 0], [182, 0], [217, 0], [0, -110], [55, -110]])
            #expect(tracked.glyphs.map(\.advance) == plain.glyphs.map(\.advance))
            #expect(tracked.glyphs.map(\.outline) == plain.glyphs.map(\.outline))
            let tight = try Typesetting.Text("AVA B", font: Tests.font(), size: 50, tracking: -0.1)
            #expect(Tests.close(tight.width, try Typesetting.Text("AVA B", font: Tests.font(), size: 50).width - 4 * 5))
            #expect(throws: Typesetting.Error.tracking) { try Typesetting.Text("A", font: Tests.font(), size: 10, tracking: .nan) }
            #expect(throws: Typesetting.Error.tracking) { try Typesetting.Text("A", font: Tests.font(), size: 10, tracking: .infinity) }
        }

        @Test
        func `Tracking counts toward the measure a line breaks at`() throws {
            #expect(try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 320).lines.map(\.glyphs.count) == [6, 2])
            let text = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 320, tracking: 0.05)
            #expect(text.lines.map(\.glyphs.count) == [3, 3, 2])
            #expect(text.lines.map(\.width) == [145, 145, 145])
            let slight = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 320, tracking: 0.01)
            #expect(slight.lines.map(\.glyphs.count) == [6, 2])
            #expect(slight.lines[0].width == 314)
        }

        @Test
        func `Tabular figures share the widest digit's advance, centred in it, and are not kerned`() throws {
            let font = Tests.typeset()
            let proportional = try Typesetting.Text("10", font: font, size: 100)
            #expect(proportional.glyphs.map(\.advance) == [40, 60])
            #expect(Tests.origins(proportional) == [[0, 0], [35, 0]])
            let tabular = try Typesetting.Text("1028", font: font, size: 100, figures: .tabular)
            #expect(tabular.metrics.figure == 60)
            #expect(tabular.glyphs.map(\.advance) == [60, 60, 60, 60])
            #expect(Tests.origins(tabular) == [[0, 0], [60, 0], [120, 0], [180, 0]])
            #expect(Tests.corners(tabular.glyphs[0].outline) == [[[10, 0], [30, 0], [30, 70], [10, 70], [10, 0]]])
            #expect(Tests.corners(tabular.glyphs[1].outline) == [[[0, 0], [50, 0], [50, 70], [0, 70], [0, 0]]])
            #expect(Tests.corners(tabular.glyphs[3].outline) == [[[2.5, 0], [47.5, 0], [47.5, 70], [2.5, 70], [2.5, 0]]])
            let letters = try Typesetting.Text("AV", font: font, size: 100, figures: .tabular)
            #expect(Tests.origins(letters) == [[0, 0], [50, 0]])
        }

        @Test
        func `A tabular number's width depends only on how many digits it has`() throws {
            let font = Tests.typeset()
            let numbers = ["1111", "0000", "1010", "8018", "0101", "9999"]
            let tabular = try numbers.map { number throws(Typesetting.Error) in try Typesetting.Text(number, font: font, size: 37, figures: .tabular).width }
            #expect(Set(tabular).count == 1)
            #expect(Tests.close(tabular[0], 4 * 0.6 * 37))
            let proportional = try numbers.map { number throws(Typesetting.Error) in try Typesetting.Text(number, font: font, size: 37).width }
            #expect(Set(proportional).count > 1)
        }

        @Test
        func `Figures in cells keep every digit still as a number changes, its point in half a cell`() throws {
            let font = Tests.typeset()
            let cells = Typesetting.Figures.cells(.init(punctuation: 0.5))
            let numbers = ["10.8", "88.0", "01.1", "80.8"]
            let set = try numbers.map { number throws(Typesetting.Error) in try Typesetting.Text(number, font: font, size: 100, figures: cells) }
            for text in set {
                #expect(Tests.origins(text) == [[0, 0], [60, 0], [120, 0], [150, 0]])
                #expect(text.glyphs.map(\.advance) == [60, 60, 30, 60])
            }
            let natural = try numbers.map { number throws(Typesetting.Error) in try Typesetting.Text(number, font: font, size: 100, figures: .tabular) }
            #expect(natural.allSatisfy { Tests.origins($0) == [[0, 0], [60, 0], [120, 0], [170, 0]] })
            let point = set[0].glyphs[2]
            let alone = try Typesetting.Text(".", font: font, size: 100).glyphs[0].outline
            #expect(point.outline == alone.transformed(by: .translation(Vector([-10, 0]))))
        }

        @Test
        func `Cells with no share for a class leave the tabular setting as it was`() throws {
            let font = Tests.typeset()
            for string in ["1028", "10 8", "AV 10", "8.1"] {
                let tabular = try Typesetting.Text(string, font: font, size: 37, tracking: 0.02, figures: .tabular)
                let cells = try Typesetting.Text(string, font: font, size: 37, tracking: 0.02, figures: .cells(.init()))
                #expect(tabular == cells)
            }
            #expect(Typesetting.Figures.proportional.share(of: "1") == nil)
            #expect(Typesetting.Figures.tabular.share(of: "1") == 1)
            #expect(Typesetting.Figures.tabular.share(of: ".") == nil)
            let all = Typesetting.Figures.Cells(punctuation: 0.5, symbols: 0.75, spaces: 0.25)
            #expect(all.share(of: ",") == 0.5 && all.share(of: "%") == 0.5 && all.share(of: "+") == 0.75 && all.share(of: " ") == 0.25)
            #expect(all.share(of: "A") == nil)
        }

        @Test
        func `The size fitting a measure sets the widest line to that measure`() throws {
            let font = Tests.typeset()
            let cases: [(string: String, tracking: Double, figures: Typesetting.Figures)] = [
                ("AVA B", 0, .proportional), ("AVA B\nAV", 0.05, .proportional), ("1018 Hx", -0.02, .tabular),
            ]
            for (string, tracking, figures) in cases {
                let text = try Typesetting.Text(string, font: font, size: 31, tracking: tracking, figures: figures)
                for measure in [100.0, 523.25, 1920] {
                    let size = text.size(fitting: measure)
                    let fitted = try Typesetting.Text(string, font: font, size: size, tracking: tracking, figures: figures)
                    #expect(Tests.close(fitted.width, measure, within: 1e-9 * measure))
                }
            }
            let text = try Typesetting.Text("AVA B", font: font, size: 100)
            #expect(text.size(fitting: 1000, maximum: 120) == 120)
            #expect(Tests.close(text.size(fitting: text.width, maximum: 120), 100))
            #expect(try Typesetting.Text("", font: font, size: 100).size(fitting: 50, maximum: 80) == 80)
            #expect(try Typesetting.Text(" ", font: font, size: 100).size(fitting: 50) == .infinity)
        }
    }
}
