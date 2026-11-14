public import Angle
public import Byte
public import Cardinal
public import Geometry
public import ISO_14496_22
public import Layout
import Matrix
import Numeric
import Vector

extension Typesetting {
    /// A string set in a font at a size: lines of glyphs, each glyph an outline at a place.
    public struct Text: Sendable, Hashable {
        /// The lines, top to bottom.
        public let lines: [Line]

        /// The width the lines are aligned in.
        public let measure: Double

        /// The font's metrics at the text's size.
        public let metrics: Metrics

        /// The distance from one baseline down to the next.
        public let leading: Double
    }
}

extension Typesetting.Text {
    /// Sets a string in a parsed font.
    ///
    /// `alignment` stands each line in the measure; text is set left to right, so `leading` is the left.
    /// `tracking` is extra advance after every glyph, as a share of the size, so that it scales with the text;
    /// `figures` sets the digits proportional, tabular or in cells with the characters among them.
    public init(
        _ string: String,
        font: ISO_14496_22.FontFile,
        size: Double,
        measure: Double? = nil,
        alignment: Horizontal.Alignment = .leading,
        leading: Double? = nil,
        tracking: Double = 0,
        figures: Typesetting.Figures = .proportional
    ) throws(Typesetting.Error) {
        let metrics = try Typesetting.Metrics(font: font, size: size)
        if let measure {
            guard measure > 0, measure.isFinite else { throw .measure }
        }
        guard tracking.isFinite else { throw .tracking }
        let scale = size / Double(font.unitsPerEm)
        let step = leading ?? (metrics.ascent + metrics.descent + metrics.gap)
        let tracked = tracking * size
        let figure = Typesetting.Metrics.figure(of: font)
        let sized = Matrix<2, 3, Double>(rows: [[scale, 0, 0], [0, scale, 0]])
        var outlines: [UInt16: Typesetting.Plane.Path] = [:]
        var centred: [Cell: Typesetting.Plane.Path] = [:]
        var runs: [Run] = []
        var text: [Unicode.Scalar] = []
        var bytes = string.utf8.makeIterator()
        var decoder = UTF8()
        while case .scalarValue(let scalar) = decoder.decode(&bytes) {
            text.append(scalar)
        }
        for paragraph in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let scalars = Array(paragraph)
            let indices = scalars.map { font.glyphIndex(for: $0.value) ?? 0 }
            let shares = scalars.map { figures.share(of: $0) }
            for index in indices where outlines[index] == nil {
                do throws(ISO_14496_22.Outline.Error) {
                    outlines[index] = try font.outline(for: index).transformed(by: sized, to: Typesetting.Space.self)
                } catch {
                    throw .outline(error)
                }
            }
            for (index, share) in zip(indices, shares) {
                guard let share, centred[Cell(index: index, share: share)] == nil else { continue }
                let shift = (Double(figure) * share - Double(font.advanceWidth(for: index))) / 2 * scale
                centred[Cell(index: index, share: share)] = outlines[index]?.transformed(by: .translation(Vector([shift, 0])))
            }
            let units = zip(indices, shares).map { index, share in share.map { Double(figure) * $0 } ?? Double(font.advanceWidth(for: index)) }
            var starts: [Double] = [0]
            for position in indices.indices {
                var advance = units[position]
                if position + 1 < indices.count, shares[position] == nil, shares[position + 1] == nil {
                    do throws(ISO_14496_22.FontFile.ParsingError) {
                        advance += try font.kerning(left: indices[position], right: indices[position + 1]).underlying
                    } catch {
                        throw .font(error)
                    }
                }
                starts.append(starts[position] + advance * scale + tracked)
            }
            let widths = units.map { $0 * scale }
            let blank = scalars.map { $0 == " " }
            var start = 0
            var opportunity: Int?
            if let measure {
                for position in indices.indices where !blank[position] {
                    if position > start, blank[position - 1] { opportunity = position }
                    if let cut = opportunity, starts[position] - starts[start] + widths[position] > measure {
                        runs.append(Run(scalars: scalars, indices: indices, shares: shares, starts: starts, widths: widths, blank: blank, range: start..<cut))
                        start = cut
                        opportunity = nil
                    }
                }
            }
            runs.append(Run(scalars: scalars, indices: indices, shares: shares, starts: starts, widths: widths, blank: blank, range: start..<indices.count))
        }
        let widest = runs.reduce(0) { Swift.max($0, $1.width) }
        let within = measure ?? widest
        self.lines = runs.enumerated().map { number, run in
            let baseline = 0 - Double(number) * step
            let indent = alignment.indent(of: run.width, in: within, direction: .leftToRight)
            let glyphs = run.range.map { position in
                let index = run.indices[position]
                return Typesetting.Glyph(
                    scalar: run.scalars[position],
                    index: index,
                    origin: Typesetting.Plane.Point<2>([indent + run.starts[position] - run.starts[run.range.lowerBound], baseline]),
                    advance: run.widths[position],
                    outline: (run.shares[position].map { centred[Cell(index: index, share: $0)] } ?? outlines[index])
                        ?? Typesetting.Plane.Path(subpaths: [])
                )
            }
            return Typesetting.Line(glyphs: glyphs, baseline: baseline, width: run.width)
        }
        self.measure = within
        self.metrics = metrics
        self.leading = step
    }

    /// Sets a string in the font a font file's bytes hold.
    public init(
        _ string: String,
        bytes: [Byte],
        size: Double,
        measure: Double? = nil,
        alignment: Horizontal.Alignment = .leading,
        leading: Double? = nil,
        tracking: Double = 0,
        figures: Typesetting.Figures = .proportional
    ) throws(Typesetting.Error) {
        let font: ISO_14496_22.FontFile
        do throws(ISO_14496_22.FontFile.ParsingError) {
            font = try ISO_14496_22.FontFile(data: bytes)
        } catch {
            throw .font(error)
        }
        try self.init(string, font: font, size: size, measure: measure, alignment: alignment, leading: leading, tracking: tracking, figures: figures)
    }
}

extension Typesetting.Text {
    /// Every glyph, line after line, in the order of the string.
    public var glyphs: [Typesetting.Glyph] {
        lines.flatMap(\.glyphs)
    }

    /// Every glyph's outline at its place, as one path.
    public var path: Typesetting.Plane.Path {
        Self.path(of: glyphs)
    }

    /// Glyphs as one path: every glyph's path in order.
    public static func path(of glyphs: some Swift.Sequence<Typesetting.Glyph>) -> Typesetting.Plane.Path {
        Typesetting.Plane.Path(subpaths: glyphs.flatMap(\.path.subpaths))
    }

    /// The box of the ink the text puts down: the bounding box of `path`, nil for a text that draws nothing, as
    /// one of spaces.
    public var bounds: Typesetting.Plane.Rectangle? {
        path.boundingBox
    }

    /// How far the font rises above a baseline at this size: the metrics' ascent.
    public var ascent: Double { metrics.ascent }

    /// How far the font falls below a baseline at this size: the metrics' descent.
    public var descent: Double { metrics.descent }

    /// The width of the widest line.
    public var width: Double {
        lines.reduce(0) { Swift.max($0, $1.width) }
    }

    /// The point on the first line's level at the left end, the middle or the right end of the measure: the
    /// point a text is put at or turned about.
    public func point(at anchor: Horizontal.Alignment, level: Typesetting.Level = .baseline) -> Typesetting.Plane.Point<2> {
        Typesetting.Plane.Point<2>([anchor.indent(of: 0, in: measure, direction: .leftToRight), level.height(in: metrics)])
    }

    /// The size at which the widest line is as wide as a measure, and at most `maximum`.
    ///
    /// Every advance, kerning and tracking scales with the size, so the width does too, and the size is the
    /// text's size times the measure over its width; set again at that size, the text's widest line is the
    /// measure up to rounding. The lines are taken as they are set, so a text that breaks into lines at a
    /// measure may break otherwise at the new size. A text with no width gives `maximum`.
    public func size(fitting measure: Double, maximum: Double = .infinity) -> Double {
        let width = width
        guard width > 0 else { return maximum }
        return Swift.min(metrics.size * measure / width, maximum)
    }

    /// How many glyphs a string is set as: one for each Unicode scalar that is not a line break, counted as the
    /// first bytes of its UTF-8, which is how `init(_:font:size:measure:alignment:leading:tracking:figures:)`
    /// reads it. A string's glyphs are the next `length(of:)` glyphs of a text it is part of.
    public static func length(of string: String) -> Cardinal {
        Cardinal(
            string.utf8.reduce(into: UInt(0)) { count, byte in
                if byte & 0xc0 != 0x80, byte != 0x0a { count += 1 }
            }
        )
    }
}

extension Typesetting.Text {
    /// The glyphs set along a circle, each turned to the circle's tangent and none bent.
    ///
    /// A glyph's place along the circle is the middle of its advance on its baseline, its distance along the
    /// line from the left end, the middle or the right end of the measure as `anchor` says, taken as arc
    /// length on the circle from the angle `start`, counterclockwise from x. `outside` runs clockwise, against
    /// the angle, so the text reads across the top; `inside` runs with it and reads across the bottom. The
    /// circle passes through the first line's `level`, so a later line runs on a circle that much nearer the
    /// centre, or farther for `inside`, at the same angles. Each glyph is `transformed(by:)` the map that takes
    /// its middle to its place, x to the way the text runs there and y to the way the glyph's top points. A
    /// radius that is not positive and finite gives no glyphs.
    public func circled(
        center: Typesetting.Plane.Point<2>,
        radius: Double,
        start: Radian<Double>,
        side: Typesetting.Side = .outside,
        anchor: Horizontal.Alignment = .leading,
        level: Typesetting.Level = .baseline
    ) -> [Typesetting.Glyph] {
        guard radius > 0, radius.isFinite else { return [] }
        let point = point(at: anchor, level: level)
        let turn: Double = side == .outside ? 1 : -1
        return glyphs.map { glyph in
            let along = glyph.origin[0] + glyph.advance / 2 - point[0]
            let rise = glyph.origin[1] - point[1]
            let angle = start.underlying - turn * along / radius
            let (cosine, sine) = (Double.cos(angle), Double.sin(angle))
            let reach = radius + turn * rise
            let place = Typesetting.Plane.Point<2>([center[0] + reach * cosine, center[1] + reach * sine])
            return Self.turned(glyph, to: place, along: (x: turn * sine, y: -turn * cosine))
        }
    }

    /// The glyphs set along a path by arc length, each turned to the path's direction and none bent.
    ///
    /// The path is flattened to within `tolerance`, its subpaths taken in order as one track and a closed
    /// subpath with its closing line. A glyph's place is the middle of its advance on its baseline, its
    /// distance along the line from the left end, the middle or the right end of the measure as `anchor`
    /// says, taken as length along the track from its start; before the start and past the end the track goes
    /// straight on. The track passes through the first line's `level`, and the glyphs' tops face the left of
    /// the way the path runs, up for a path running toward x. A path with no length gives no glyphs.
    public func along(
        _ path: Typesetting.Plane.Path,
        tolerance: Typesetting.Plane.Length,
        anchor: Horizontal.Alignment = .leading,
        level: Typesetting.Level = .baseline
    ) throws(Typesetting.Plane.Path.Error) -> [Typesetting.Glyph] {
        let flat = try path.flattened(tolerance: tolerance)
        var pieces: [(from: Typesetting.Plane.Point<2>, way: (x: Double, y: Double), start: Double)] = []
        var travelled = 0.0
        for subpath in flat.subpaths {
            var points = [subpath.startPoint]
            for segment in subpath.segments {
                guard case .line(let line) = segment else { continue }
                points.append(line.end)
            }
            if subpath.isClosed { points.append(subpath.startPoint) }
            for (from, to) in zip(points, points.dropFirst()) {
                let (x, y) = (to[0] - from[0], to[1] - from[1])
                let length = (x * x + y * y).squareRoot()
                guard length > 0, length.isFinite else { continue }
                pieces.append((from, (x / length, y / length), travelled))
                travelled += length
            }
        }
        guard let first = pieces.first else { return [] }
        let point = point(at: anchor, level: level)
        return glyphs.map { glyph in
            let along = glyph.origin[0] + glyph.advance / 2 - point[0]
            let rise = glyph.origin[1] - point[1]
            let piece = pieces.last { $0.start <= along } ?? first
            let into = along - piece.start
            let place = Typesetting.Plane.Point<2>([
                piece.from[0] + into * piece.way.x - rise * piece.way.y,
                piece.from[1] + into * piece.way.y + rise * piece.way.x,
            ])
            return Self.turned(glyph, to: place, along: piece.way)
        }
    }

    /// A glyph moved so that the middle of its advance on its baseline lies at a place, its x turned to a
    /// direction of unit length and its y, its up, to that direction turned a quarter counterclockwise.
    static func turned(_ glyph: Typesetting.Glyph, to place: Typesetting.Plane.Point<2>, along way: (x: Double, y: Double)) -> Typesetting.Glyph {
        let middle = (x: glyph.origin[0] + glyph.advance / 2, y: glyph.origin[1])
        let map = Matrix<2, 3, Double>(rows: [
            [way.x, -way.y, place[0] - way.x * middle.x + way.y * middle.y],
            [way.y, way.x, place[1] - way.y * middle.x - way.x * middle.y],
        ])
        return glyph.transformed(by: map)
    }
}
