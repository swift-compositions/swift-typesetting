public import ISO_14496_22

extension Typesetting.Text {
    /// `string` set on one line at `size`, or 5% smaller at a time until it is no wider than `measure` or no larger
    /// than `least`.
    public init(
        _ string: Swift.String,
        font: ISO.`14496`.`22`.FontFile,
        size: Double,
        fitting measure: Double,
        least: Double
    ) throws(Typesetting.Error) {
        var size = size
        var text = try Self(string, font: font, size: size)
        while text.width > measure, size > least {
            size *= 0.95
            text = try Self(string, font: font, size: size)
        }
        self = text
    }
}
