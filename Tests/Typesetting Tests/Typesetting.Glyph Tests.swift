import ISO_14496_22_Test_Support
import Numeric
import Testing
import Typesetting

extension `Typesetting Tests` {
    @Suite
    struct `Glyphs moved, on a circle and along a path` {
        typealias Tests = `Typesetting Tests`

        /// The glyph's frame, read from its box outline: the middle of its advance on its baseline, the way its
        /// baseline runs at unit length, and the corner at the top of its left side.
        static func frame(of glyph: Typesetting.Glyph, width: Double) -> (middle: [Double], way: [Double], top: [Double]) {
            let corners = Tests.corners(glyph.path)[0]
            let way = [(corners[1][0] - corners[0][0]) / width, (corners[1][1] - corners[0][1]) / width]
            let middle = [glyph.origin[0] + way[0] * glyph.advance / 2, glyph.origin[1] + way[1] * glyph.advance / 2]
            return (middle, way, corners[3])
        }

        @Test
        func `A glyph moved by a map has its old path under the map`() throws {
            let text = try Typesetting.Text("AH", font: Tests.typeset(), size: 20)
            let map = Matrix<2, 3, Double>(rows: [[0.6, -0.8, 12], [0.8, 0.6, -3]])
            for glyph in text.glyphs {
                let moved = glyph.transformed(by: map)
                let expected = Tests.corners(glyph.path.transformed(by: map))
                let corners = Tests.corners(moved.path)
                #expect(zip(expected.joined(), corners.joined()).allSatisfy { Tests.close(Tests.at($0[0], $0[1]), Tests.at($1[0], $1[1]), within: 1e-12) })
                #expect(moved.advance == glyph.advance && moved.index == glyph.index)
            }
        }

        @Test
        func `Glyphs on a circle sit at the radius, turned to the tangent, and run clockwise over the top`() throws {
            let text = try Typesetting.Text("HHHH", font: Tests.typeset(), size: 10, tracking: 0.1)
            let center = Tests.at(100, 100)
            let start = Double.pi / 2
            let circled = text.circled(center: center, radius: 50, start: Radian(start))
            #expect(circled.count == 4)
            var angles: [Double] = []
            for (glyph, original) in zip(circled, text.glyphs) {
                let frame = Self.frame(of: glyph, width: 6)
                let out = [frame.middle[0] - center[0], frame.middle[1] - center[1]]
                #expect(Tests.close((out[0] * out[0] + out[1] * out[1]).squareRoot(), 50))
                #expect(Tests.close(out[0] * frame.way[0] + out[1] * frame.way[1], 0))
                #expect(Tests.close(frame.way[0] * frame.way[0] + frame.way[1] * frame.way[1], 1))
                let angle = Double.atan2(out[1], out[0])
                #expect(Tests.close(angle, start - (original.origin[0] + original.advance / 2) / 50))
                let top = [frame.top[0] - center[0], frame.top[1] - center[1]]
                #expect((top[0] * top[0] + top[1] * top[1]).squareRoot() > 50)
                angles.append(angle)
            }
            #expect(Tests.close(angles[3] - angles[0], -3 * 8 / 50))
            let first = try #require(circled.first)
            #expect(Self.frame(of: first, width: 6).way[0] > 0.99)
        }

        @Test
        func `Inside a circle the glyphs run counterclockwise with their tops toward the centre`() throws {
            let text = try Typesetting.Text("HH", font: Tests.typeset(), size: 10)
            let center = Tests.at(0, 0)
            let circled = text.circled(center: center, radius: 40, start: Radian(-Double.pi / 2), side: .inside, anchor: .center, level: .cap(0.5))
            let frames = circled.map { Self.frame(of: $0, width: 6) }
            #expect(Tests.close(Double.atan2(frames[0].middle[1], frames[0].middle[0]), -Double.pi / 2 - 3.5 / 40))
            #expect(Tests.close(Double.atan2(frames[1].middle[1], frames[1].middle[0]), -Double.pi / 2 + 3.5 / 40))
            #expect(frames.allSatisfy { $0.way[0] > 0.99 })
            let reach = frames.map { ($0.middle[0] * $0.middle[0] + $0.middle[1] * $0.middle[1]).squareRoot() }
            #expect(reach.allSatisfy { Tests.close($0, 40 + 3.5) })
            #expect(frames.allSatisfy { ($0.top[0] * $0.top[0] + $0.top[1] * $0.top[1]).squareRoot() < 40 })
            #expect(text.circled(center: center, radius: 0, start: .zero).isEmpty)
            #expect(text.circled(center: center, radius: .infinity, start: .zero).isEmpty)
        }

        @Test
        func `A later line runs on a circle nearer the centre`() throws {
            let text = try Typesetting.Text("H\nH", font: Tests.typeset(), size: 10)
            let circled = text.circled(center: Tests.at(0, 0), radius: 50, start: Radian(Double.pi / 2))
            let reach = circled.map { glyph in (glyph.origin[0] * glyph.origin[0] + glyph.origin[1] * glyph.origin[1]).squareRoot() }
            #expect(reach[0] > reach[1])
            let middle = Self.frame(of: circled[1], width: 6).middle
            #expect(Tests.close((middle[0] * middle[0] + middle[1] * middle[1]).squareRoot(), 50 - 11))
        }

        @Test
        func `Along a straight path the glyphs only move, and along a circle they follow it`() throws {
            let text = try Typesetting.Text("HxH", font: Tests.typeset(), size: 10)
            let line = try #require(Typesetting.Plane.Path.polyline(vertices: [Tests.at(20, 50), Tests.at(60, 50), Tests.at(400, 50)]))
            let along = try text.along(line, tolerance: 0.01)
            for (glyph, original) in zip(along, text.glyphs) {
                let expected = Tests.corners(original.path.transformed(by: .translation(Vector([20, 50]))))
                #expect(zip(expected.joined(), Tests.corners(glyph.path).joined()).allSatisfy { Tests.close(Tests.at($0[0], $0[1]), Tests.at($1[0], $1[1])) })
            }
            let before = try text.along(line, tolerance: 0.01, anchor: .trailing)
            #expect(Tests.close(before[2].origin[0] + before[2].advance, 20))
            let circle = Typesetting.Plane.Path(Typesetting.Plane.Circle(center: Tests.at(0, 0), radius: 30))
            let round = try text.along(circle, tolerance: 0.000001)
            let exact = text.circled(center: Tests.at(0, 0), radius: 30, start: .zero, side: .inside)
            for (glyph, expected) in zip(round, exact) {
                let corners = Tests.corners(glyph.path).joined()
                #expect(zip(Tests.corners(expected.path).joined(), corners).allSatisfy { Tests.close(Tests.at($0[0], $0[1]), Tests.at($1[0], $1[1]), within: 0.01) })
            }
            #expect(try text.along(Typesetting.Plane.Path(subpaths: []), tolerance: 0.1).isEmpty)
        }
    }
}
