import ISO_14496_22_Test_Support
import Testing
import Typesetting

enum `Typesetting Tests` {}

extension `Typesetting Tests` {
    typealias Corner = (x: Int, y: Int)

    static func at(_ x: Double, _ y: Double) -> Typesetting.Plane.Point<2> { .init([x, y]) }

    static func close(_ a: Double, _ b: Double, within tolerance: Double = 1e-9) -> Bool {
        abs(a - b) <= tolerance
    }

    static func close(_ a: Typesetting.Plane.Point<2>, _ b: Typesetting.Plane.Point<2>, within tolerance: Double = 1e-9) -> Bool {
        close(a[0], b[0], within: tolerance) && close(a[1], b[1], within: tolerance)
    }

    static let box: [Corner] = [(0, 0), (400, 0), (400, 700), (0, 700)]
    static let triangle: [Corner] = [(0, 0), (500, 0), (250, 700)]
    static let wedge: [Corner] = [(0, 700), (250, 0), (500, 700)]

    /// Glyph 0 is a box, 1 is "A", 2 is "V", 3 is the space, 4 is "B" and 5 is U+0301. "A" and "V" kern both
    /// ways, and "A" before the space.
    static func font(unitsPerEm: UInt16 = 1000) -> ISO_14496_22.FontFile {
        ISO_14496_22.FontFile(
            sketches: [
                .init(advance: 500, contours: [box]), .init(advance: 600, contours: [triangle]),
                .init(advance: 600, contours: [wedge]), .init(advance: 300), .init(advance: 700, contours: [box, triangle]),
                .init(advance: 0, contours: [triangle]),
            ],
            mapping: [0x41: 1, 0x56: 2, 0x20: 3, 0x42: 4, 0x301: 5],
            kerning: [(1, 2, -100), (2, 1, -50), (1, 3, 20)],
            unitsPerEm: unitsPerEm
        )
    }

    static let capital: [Corner] = [(0, 0), (600, 0), (600, 700), (0, 700)]
    static let small: [Corner] = [(0, 0), (400, 0), (400, 500), (0, 500)]
    static let one: [Corner] = [(0, 0), (200, 0), (200, 700), (0, 700)]
    static let zero: [Corner] = [(0, 0), (500, 0), (500, 700), (0, 700)]
    static let eight: [Corner] = [(0, 0), (450, 0), (450, 700), (0, 700)]

    /// Glyph 0 is a box, 1 is "A", 2 is "V", 3 the space, 4 "H" (a box 700 high), 5 "x" (a box 500 high),
    /// 6 "1" (advance 400), 7 "0" (advance 600) and 8 "8" (advance 550). The other digits are glyph 0, of
    /// advance 500. "1" and "0" kern both ways, as do "A" and "V".
    static func typeset(os2: ISO_14496_22.OS2? = nil) -> ISO_14496_22.FontFile {
        ISO_14496_22.FontFile(
            sketches: [
                .init(advance: 500, contours: [box]), .init(advance: 600, contours: [triangle]),
                .init(advance: 600, contours: [wedge]), .init(advance: 300), .init(advance: 700, contours: [capital]),
                .init(advance: 500, contours: [small]), .init(advance: 400, contours: [one]),
                .init(advance: 600, contours: [zero]), .init(advance: 550, contours: [eight]),
            ],
            mapping: [0x41: 1, 0x56: 2, 0x20: 3, 0x48: 4, 0x78: 5, 0x31: 6, 0x30: 7, 0x38: 8],
            kerning: [(1, 2, -100), (6, 7, -50), (7, 6, -30)],
            os2: os2
        )
    }

    /// Each subpath's points of a path of lines: its start and the end of every line.
    static func corners(_ path: Typesetting.Plane.Path) -> [[[Double]]] {
        path.subpaths.map { subpath in
            [[subpath.startPoint[0], subpath.startPoint[1]]]
                + subpath.segments.compactMap { segment in
                    guard case .line(let line) = segment else { return nil }
                    return [line.end[0], line.end[1]]
                }
        }
    }

    static func origins(_ text: Typesetting.Text) -> [[Double]] {
        text.glyphs.map { [$0.origin[0], $0.origin[1]] }
    }
}
