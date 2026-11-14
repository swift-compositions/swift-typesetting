import ISO_14496_22_Test_Support
import Testing
import Typesetting

extension `Typesetting Tests` {
    @Suite
    struct `A font's metrics at a size` {
        typealias Tests = `Typesetting Tests`

        @Test
        func `Cap height and x-height are the font's, at the size`() throws {
            let font = Tests.typeset(os2: ISO_14496_22.OS2(version: 4, sxHeight: 450, sCapHeight: 650))
            let metrics = try Typesetting.Metrics(font: font, size: 100)
            #expect(metrics.size == 100)
            #expect(metrics.cap == 65)
            #expect(metrics.ex == 45)
            #expect(metrics.ascent == 80)
            #expect(metrics.descent == 20)
            #expect(metrics.gap == 10)
            let text = try Typesetting.Text("H", font: font, size: 100)
            #expect(text.metrics == metrics)
            #expect(text.ascent == 80 && text.descent == 20)
        }

        @Test
        func `Without a height in the table, the capital H and the lowercase x are measured`() throws {
            let absent = try Typesetting.Metrics(font: Tests.typeset(), size: 10)
            #expect(absent.cap == 7)
            #expect(absent.ex == 5)
            let early = try Typesetting.Metrics(font: Tests.typeset(os2: ISO_14496_22.OS2(version: 1)), size: 10)
            #expect(early.cap == 7 && early.ex == 5)
        }

        @Test
        func `A font with neither falls back to the ascent, and the x-height to the cap height`() throws {
            let plain = try Typesetting.Metrics(font: Tests.font(), size: 10)
            #expect(plain.cap == plain.ascent)
            #expect(plain.ex == plain.cap)
            let capitals = ISO_14496_22.FontFile(sketches: [.init(advance: 500, contours: [Tests.capital])], mapping: [0x48: 0])
            #expect(try Typesetting.Metrics(font: capitals, size: 10).ex == 7)
        }

        @Test
        func `A monospaced font's pitch is the space's advance`() throws {
            #expect(try Typesetting.Metrics(font: Tests.typeset(), size: 100).pitch == nil)
            #expect(try Typesetting.Metrics(font: Tests.typeset().fixed, size: 100).pitch == 30)
            let monospaced = ISO_14496_22.OS2(version: 0, panose: [2, 0, 0, 9, 0, 0, 0, 0, 0, 0])
            #expect(try Typesetting.Metrics(font: Tests.typeset(os2: monospaced), size: 100).pitch == 30)
            let spaceless = ISO_14496_22.FontFile(sketches: [.init(advance: 450)], mapping: [:]).fixed
            #expect(try Typesetting.Metrics(font: spaceless, size: 100).pitch == 45)
        }

        @Test
        func `The figure is the widest digit's advance`() throws {
            #expect(try Typesetting.Metrics(font: Tests.typeset(), size: 100).figure == 60)
            #expect(try Typesetting.Metrics(font: Tests.font(), size: 100).figure == 50)
        }

        @Test
        func `A level stands its share of a metric above the baseline`() throws {
            let metrics = try Typesetting.Metrics(font: Tests.typeset(), size: 100)
            #expect(Typesetting.Level.baseline.height(in: metrics) == 0)
            #expect(Typesetting.Level.ascent.height(in: metrics) == 80)
            #expect(Typesetting.Level.descent.height(in: metrics) == -20)
            #expect(Typesetting.Level.cap(0.5).height(in: metrics) == 35)
            #expect(Typesetting.Level.ex(1).height(in: metrics) == 50)
        }

        @Test
        func `A size that is not positive and finite, an em of no units, or an outline that fails is refused`() {
            #expect(throws: Typesetting.Error.size) { try Typesetting.Metrics(font: Tests.typeset(), size: 0) }
            #expect(throws: Typesetting.Error.units) { try Typesetting.Metrics(font: Tests.font(unitsPerEm: 0), size: 10) }
            #expect(throws: Typesetting.Error.outline(.absent)) { try Typesetting.Metrics(font: Tests.typeset().outlineless, size: 10) }
        }
    }
}
