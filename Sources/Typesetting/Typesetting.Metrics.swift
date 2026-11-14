public import ISO_14496_22

extension Typesetting {
    /// The heights and widths a font gives at a size: how far the font rises and falls about a baseline, the
    /// gap it asks between lines, how high its capitals and its lowercase x stand, the advance its figures
    /// share when they are tabular, and its one advance when every glyph has the same.
    public struct Metrics: Sendable, Hashable {
        /// The size the metrics are taken at, the size of an em.
        public let size: Double

        /// How far the font rises above a baseline: the `hhea` ascender.
        public let ascent: Double

        /// How far the font falls below a baseline: minus the `hhea` descender.
        public let descent: Double

        /// The gap the font asks between one line's descent and the next line's ascent: the `hhea` line gap.
        public let gap: Double

        /// The height of the capitals above the baseline, CSS's `cap`: the font's `sCapHeight`.
        public let cap: Double

        /// The height of the lowercase above the baseline, CSS's `ex`: the font's `sxHeight`.
        public let ex: Double

        /// The advance of a tabular figure: the widest advance of the ten digits U+0030 to U+0039.
        public let figure: Double

        /// The advance every glyph has when the font says it is monospaced, and nil when it does not.
        public let pitch: Double?
    }
}

extension Typesetting.Metrics {
    /// The metrics of a font at a size.
    ///
    /// The cap height and the x-height are the font's `sCapHeight` and `sxHeight`: the `OS/2` table's, or the
    /// top of the capital H and the lowercase x where it gives none. A font that has neither falls back to the
    /// ascent for the cap height and to the cap height for the x-height. A monospaced font's pitch is the
    /// advance of the space (U+0020), or of glyph 0 when it maps no space.
    public init(font: ISO_14496_22.FontFile, size: Double) throws(Typesetting.Error) {
        guard size > 0, size.isFinite else { throw .size }
        guard font.unitsPerEm > 0 else { throw .units }
        let scale = size / Double(font.unitsPerEm)
        let ascent = Double(font.ascender)
        let measured: (cap: Int16?, ex: Int16?)
        do throws(ISO_14496_22.Outline.Error) {
            measured = (try font.sCapHeight, try font.sxHeight)
        } catch {
            throw .outline(error)
        }
        let cap = measured.cap.map(Double.init) ?? ascent
        let ex = measured.ex.map(Double.init) ?? cap
        self.size = size
        self.ascent = ascent * scale
        self.descent = -Double(font.descender) * scale
        self.gap = Double(font.lineGap) * scale
        self.cap = cap * scale
        self.ex = ex * scale
        self.figure = Double(Self.figure(of: font)) * scale
        self.pitch = font.isMonospaced ? Double(font.advanceWidth(for: font.glyphIndex(for: 0x20) ?? 0)) * scale : nil
    }

    /// The widest advance of the ten digits U+0030 to U+0039, in the font's units.
    static func figure(of font: ISO_14496_22.FontFile) -> UInt16 {
        (0x30...0x39).map { (scalar: UInt32) in font.advanceWidth(for: font.glyphIndex(for: scalar) ?? 0) }.max() ?? 0
    }
}
