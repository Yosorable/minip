//
//  DiagnosticOverlayView.swift
//  minip
//

import UIKit

class DiagnosticOverlayView: UIView {
    struct DiagnosticRect {
        let rect: CGRect
        let isError: Bool
    }

    var diagnosticRects: [DiagnosticRect] = [] {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        for diag in diagnosticRects {
            let r = diag.rect
            guard r.intersects(rect) else { continue }

            let color: UIColor = diag.isError ? .systemRed : .systemYellow
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(1.5)

            let path = UIBezierPath()
            let waveHeight: CGFloat = 2.0
            let waveLength: CGFloat = 4.0
            let y = r.maxY - 1

            var x = r.minX
            path.move(to: CGPoint(x: x, y: y))
            var i = 0
            while x < r.maxX {
                let nextX = min(x + waveLength, r.maxX)
                let controlY = (i % 2 == 0) ? y - waveHeight : y + waveHeight
                path.addQuadCurve(to: CGPoint(x: nextX, y: y),
                                  controlPoint: CGPoint(x: (x + nextX) / 2, y: controlY))
                x = nextX
                i += 1
            }

            ctx.addPath(path.cgPath)
            ctx.strokePath()
        }
    }
}
