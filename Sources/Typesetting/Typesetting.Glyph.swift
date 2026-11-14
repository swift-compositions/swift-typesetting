public import Matrix
import Vector

extension Typesetting {
    /// One glyph of a text: which, where, and its outline.
    public struct Glyph: Sendable, Hashable {
        /// The code point the glyph stands for.
        public let scalar: Unicode.Scalar

        /// The glyph's number in the font.
        public let index: UInt16

        /// The glyph's own origin: where the pen stood on the baseline.
        public let origin: Typesetting.Plane.Point<2>

        /// The glyph's own advance width at the text's size, without kerning.
        public let advance: Double

        /// The glyph's outline around its own origin, at the text's size, y up.
        public let outline: Typesetting.Plane.Path
    }
}

extension Typesetting.Glyph {
    /// The outline at the glyph's place in the text.
    public var path: Typesetting.Plane.Path {
        outline.transformed(by: .translation(Vector([origin[0], origin[1]])))
    }

    /// The glyph moved by an affine map of the text's plane: its origin goes where the map takes it and its
    /// outline is turned, scaled and sheared by the map's linear part, so that the glyph's `path` is its old
    /// path under the map, up to rounding.
    public func transformed(by map: Matrix<2, 3, Double>) -> Self {
        let place = map.applied(to: Vector([origin[0], origin[1]]))
        return Self(
            scalar: scalar,
            index: index,
            origin: Typesetting.Plane.Point<2>([place[0], place[1]]),
            advance: advance,
            outline: outline.transformed(by: Matrix<2, 3, Double>(linear: map.linear))
        )
    }
}
