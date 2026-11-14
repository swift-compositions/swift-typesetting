public import Geometry

/// Setting type: a string in a font at a size becomes glyphs at places in lines, with the measures of the
/// font and of the lines.
public enum Typesetting {}

extension Typesetting {
    /// The plane a text is set in: lengths at the text's size, y up, the first line's baseline at y 0 and
    /// the left of the measure at x 0.
    public typealias Plane = Geometry<Double, Space>
}
