import ISO_14496_22_Test_Support
import Testing
import Typesetting

extension `Typesetting Tests` {
    @Suite
    struct `A text is glyph outlines at places` {}
}

extension `Typesetting Tests`.`A text is glyph outlines at places` {
    typealias Tests = `Typesetting Tests`

    @Test
    func `Every code point but the line feed becomes one glyph, in order, through the font's character map`() throws {
        let text = try Typesetting.Text("AVB A", font: Tests.font(), size: 100)
        #expect(text.glyphs.map(\.index) == [1, 2, 4, 3, 1])
        #expect(text.glyphs.map(\.scalar) == ["A", "V", "B", " ", "A"])
        #expect(text.lines.count == 1)
        #expect(text.lines[0].glyphs == text.glyphs)
        let marked = try Typesetting.Text("A\u{301}", font: Tests.font(), size: 100)
        #expect(marked.glyphs.map(\.index) == [1, 5])
        #expect(marked.glyphs.map(\.scalar) == ["A", "\u{301}"])
    }

    @Test
    func `A string's length is the number of glyphs it is set as, whatever its code points take in UTF-8`() throws {
        for string in ["", "AVB A", "A\nV", "é—𝄞 A", "\n\n"] {
            #expect(Int(bitPattern: Typesetting.Text.length(of: string)) == (try Typesetting.Text(string, font: Tests.font(), size: 100)).glyphs.count)
        }
        #expect(Typesetting.Text.length(of: "é—𝄞 A") == Cardinal(5))
    }

    @Test
    func `A code point the font does not map becomes glyph 0`() throws {
        let text = try Typesetting.Text("AxV", font: Tests.font(), size: 100)
        #expect(text.glyphs.map(\.index) == [1, 0, 2])
        #expect(text.glyphs[1].scalar == "x")
        #expect(text.glyphs[1].advance == 50)
        #expect(Tests.corners(text.glyphs[1].outline) == [[[0, 0], [40, 0], [40, 70], [0, 70], [0, 0]]])
        #expect(Tests.origins(text) == [[0, 0], [60, 0], [110, 0]])
        let wide = try Typesetting.Text("A\u{1F600}\u{E9}V", font: Tests.font(), size: 100)
        #expect(wide.glyphs.map(\.index) == [1, 0, 0, 2])
        #expect(wide.glyphs.map(\.scalar) == ["A", "\u{1F600}", "\u{E9}", "V"])
    }

    @Test
    func `The pen moves by each glyph's advance plus the pair's kerning, scaled by size over units per em`() throws {
        let text = try Typesetting.Text("AVA B", font: Tests.font(), size: 100)
        #expect(Tests.origins(text) == [[0, 0], [50, 0], [105, 0], [167, 0], [197, 0]])
        #expect(text.glyphs.map(\.advance) == [60, 60, 60, 30, 70])
        #expect(text.lines[0].width == 267)
        let half = try Typesetting.Text("AVA B", font: Tests.font(), size: 50)
        #expect(Tests.origins(half) == [[0, 0], [25, 0], [52.5, 0], [83.5, 0], [98.5, 0]])
        let coarse = try Typesetting.Text("AV", font: Tests.font(unitsPerEm: 2000), size: 100)
        #expect(Tests.origins(coarse) == [[0, 0], [25, 0]])
    }

    @Test
    func `An outline is the font's, scaled, y up as the font has it`() throws {
        let text = try Typesetting.Text("AV B", font: Tests.font(), size: 100)
        #expect(Tests.corners(text.glyphs[0].outline) == [[[0, 0], [50, 0], [25, 70], [0, 0]]])
        #expect(Tests.corners(text.glyphs[1].outline) == [[[0, 70], [25, 0], [50, 70], [0, 70]]])
        #expect(text.glyphs[2].outline.isEmpty)
        #expect(Tests.corners(text.glyphs[3].outline).count == 2)
        #expect(text.glyphs[0].outline.subpaths.map(\.isClosed) == [true])
        let small = try Typesetting.Text("A", font: Tests.font(), size: 10)
        #expect(Tests.corners(small.glyphs[0].outline) == [[[0, 0], [5, 0], [2.5, 7], [0, 0]]])
    }

    @Test
    func `A glyph's path is its outline moved to its origin, and the text's path is every glyph's path in order`() throws {
        let text = try Typesetting.Text("AV\nA", font: Tests.font(), size: 100)
        #expect(Tests.corners(text.glyphs[1].path) == [[[50, 70], [75, 0], [100, 70], [50, 70]]])
        #expect(Tests.corners(text.glyphs[2].path) == [[[0, -110], [50, -110], [25, -40], [0, -110]]])
        #expect(text.path.subpaths == text.glyphs.flatMap(\.path.subpaths))
        #expect(text.path.subpaths.count == 3)
        #expect(Typesetting.Text.path(of: text.glyphs.prefix(2)).subpaths.count == 2)
    }

    @Test
    func `A line feed starts a new line one leading lower, and kerning does not reach across it`() throws {
        let text = try Typesetting.Text("AV\n\nVA", font: Tests.font(), size: 100)
        #expect(text.lines.count == 3)
        #expect(text.lines.map(\.baseline) == [0, -110, -220])
        #expect(text.lines[0].baseline.sign == .plus)
        #expect(text.lines.map(\.glyphs.count) == [2, 0, 2])
        #expect(text.lines[1].width == 0)
        #expect(Tests.origins(text) == [[0, 0], [50, 0], [0, -220], [55, -220]])
        let apart = try Typesetting.Text("A\nV", font: Tests.font(), size: 100)
        #expect(Tests.origins(apart) == [[0, 0], [0, -110]])
        #expect(try Typesetting.Text("", font: Tests.font(), size: 100).lines.map(\.glyphs.count) == [0])
        #expect(try Typesetting.Text("A\n", font: Tests.font(), size: 100).lines.map(\.glyphs.count) == [1, 0])
    }

    @Test
    func `The font's ascender, descender and line gap give ascent, descent and leading, and a leading given wins`() throws {
        let text = try Typesetting.Text("A", font: Tests.font(), size: 100)
        #expect(text.ascent == 80)
        #expect(text.descent == 20)
        #expect(text.leading == 110)
        let tight = try Typesetting.Text("A\nA", font: Tests.font(), size: 100, leading: 64)
        #expect(tight.leading == 64)
        #expect(tight.lines.map(\.baseline) == [0, -64])
        #expect(tight.ascent == 80)
    }

    @Test
    func `A line takes as many words as fit the measure, and the spaces at the break stay at its end`() throws {
        let text = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 320)
        #expect(text.lines.map(\.glyphs.count) == [6, 2])
        #expect(text.lines.map(\.width) == [310, 140])
        #expect(text.lines[0].glyphs.map(\.scalar) == ["B", "B", " ", "B", "B", " "])
        #expect(text.lines[0].glyphs.last?.origin == Tests.at(310, 0))
        #expect(text.lines[1].glyphs.map(\.origin) == [Tests.at(0, -110), Tests.at(70, -110)])
        let exact = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 310)
        #expect(exact.lines.map(\.glyphs.count) == [6, 2])
        let narrow = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 309)
        #expect(narrow.lines.map(\.glyphs.count) == [3, 3, 2])
        let wide = try Typesetting.Text("BB  BB", font: Tests.font(), size: 100, measure: 150)
        #expect(wide.lines.map(\.glyphs.count) == [4, 2])
        #expect(wide.lines[0].width == 140)
        let even = try Typesetting.Text("B B B B", font: Tests.font(), size: 100, measure: 180)
        #expect(even.lines.map(\.glyphs.count) == [4, 3])
    }

    @Test
    func `A word wider than the measure stands alone on its line and is not broken`() throws {
        let text = try Typesetting.Text("B BBBB B", font: Tests.font(), size: 100, measure: 150)
        #expect(text.lines.map(\.glyphs.count) == [2, 5, 1])
        #expect(text.lines.map(\.width) == [70, 280, 70])
        let first = try Typesetting.Text("BBBB B", font: Tests.font(), size: 100, measure: 150)
        #expect(first.lines.map(\.glyphs.count) == [5, 1])
        #expect(try Typesetting.Text("B BBBB B", font: Tests.font(), size: 100).lines.count == 1)
        let breaks = try Typesetting.Text("B B\nB B", font: Tests.font(), size: 100, measure: 150)
        #expect(breaks.lines.map(\.glyphs.count) == [2, 1, 2, 1])
        #expect(breaks.lines.map(\.baseline) == [0, -110, -220, -330])
    }

    @Test
    func `Lines are aligned in the measure by their width without trailing spaces`() throws {
        let left = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 320)
        #expect(left.measure == 320)
        #expect(left.lines.map { $0.glyphs.first?.origin[0] } == [0, 0])
        let center = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 320, alignment: .center)
        #expect(center.lines.map { $0.glyphs.first?.origin[0] } == [5, 90])
        let right = try Typesetting.Text("BB BB BB", font: Tests.font(), size: 100, measure: 320, alignment: .trailing)
        #expect(right.lines.map { $0.glyphs.first?.origin[0] } == [10, 180])
        #expect(right.lines[1].glyphs.map(\.origin) == [Tests.at(180, -110), Tests.at(250, -110)])
    }

    @Test
    func `Without a measure, lines are aligned in the width of the widest`() throws {
        let text = try Typesetting.Text("BBB\nB\nBB ", font: Tests.font(), size: 100, alignment: .trailing)
        #expect(text.measure == 210)
        #expect(text.lines.map { $0.glyphs.first?.origin[0] } == [0, 140, 70])
        let center = try Typesetting.Text("BBB\nB", font: Tests.font(), size: 100, alignment: .center)
        #expect(center.lines.map { $0.glyphs.first?.origin[0] } == [0, 70])
    }

    @Test
    func `The point of an anchor and a level is on the first line's level at an end or the middle of the measure`() throws {
        let text = try Typesetting.Text("BBB\nB", font: Tests.typeset(), size: 100)
        #expect(text.point(at: .leading) == Tests.at(0, 0))
        #expect(text.point(at: .center, level: .cap(0.5)) == Tests.at(75, 35))
        #expect(text.point(at: .trailing, level: .descent) == Tests.at(150, -20))
    }

    @Test
    func `A text's bounds are the box of its ink, none for a text of spaces`() throws {
        let text = try Typesetting.Text("AV\nB", font: Tests.font(), size: 100)
        let bounds = try #require(text.bounds)
        #expect(bounds == text.path.boundingBox)
        #expect(bounds.llx.underlying == 0 && bounds.lly.underlying == -110 && bounds.urx.underlying == 100 && bounds.ury.underlying == 70)
        #expect(try Typesetting.Text("  ", font: Tests.font(), size: 10).bounds == nil)
    }

    @Test
    func `A size, a measure or an em that is not positive and finite is refused`() {
        #expect(throws: Typesetting.Error.size) { try Typesetting.Text("A", font: Tests.font(), size: 0) }
        #expect(throws: Typesetting.Error.size) { try Typesetting.Text("A", font: Tests.font(), size: -12) }
        #expect(throws: Typesetting.Error.size) { try Typesetting.Text("A", font: Tests.font(), size: .nan) }
        #expect(throws: Typesetting.Error.size) { try Typesetting.Text("A", font: Tests.font(), size: .infinity) }
        #expect(throws: Typesetting.Error.measure) { try Typesetting.Text("A", font: Tests.font(), size: 10, measure: 0) }
        #expect(throws: Typesetting.Error.measure) { try Typesetting.Text("A", font: Tests.font(), size: 10, measure: .nan) }
        #expect(throws: Typesetting.Error.measure) { try Typesetting.Text("A", font: Tests.font(), size: 10, measure: .infinity) }
        #expect(throws: Typesetting.Error.units) { try Typesetting.Text("A", font: Tests.font(unitsPerEm: 0), size: 10) }
    }

    @Test
    func `Bytes that are not a font, and a font without outlines, fail with the font package's errors`() {
        #expect(throws: Typesetting.Error.outline(.absent)) { try Typesetting.Text("A", font: Tests.font().outlineless, size: 10) }
        let junk = [0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0].map(Byte.init(_:))
        var failure: Typesetting.Error?
        do throws(Typesetting.Error) {
            _ = try Typesetting.Text("A", bytes: junk, size: 10)
        } catch {
            failure = error
        }
        guard case .font = failure else {
            Issue.record("Bytes that are not a font fail with .font, not \(String(describing: failure))")
            return
        }
    }
}
