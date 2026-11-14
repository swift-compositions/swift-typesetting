extension Typesetting {
    /// Which side of a circle the tops of the glyphs face.
    public enum Side: Sendable, Hashable, CaseIterable {
        /// Tops away from the centre: the text runs clockwise, against a positive angle, and stands upright
        /// along the top of the circle.
        case outside

        /// Tops toward the centre: the text runs counterclockwise, with a positive angle, and stands upright
        /// along the bottom of the circle.
        case inside
    }
}
