import UIKit
import Foundation
import UniformTypeIdentifiers
import SwiftUI

// MARK: - PDF Transferable Wrapper

struct PanchangPDF: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { pdf in pdf.data }
    }
}

// MARK: - Panchang PDF Exporter

enum PanchangPDFExporter {

    static func generatePDF(
        context: CalculationContext
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4 at 72 dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            let pdfCtx = ctx.cgContext

            // Colours
            let gold    = UIColor(red: 1.0,  green: 0.84, blue: 0.0,  alpha: 1)
            let dark    = UIColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1)
            let subtle  = UIColor(red: 0.45, green: 0.42, blue: 0.55, alpha: 1)

            // Background
            dark.setFill()
            pdfCtx.fill(pageRect)

            // Header stripe
            gold.withAlphaComponent(0.15).setFill()
            pdfCtx.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: 120))

            // Title
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let subtitleFont = UIFont.systemFont(ofSize: 13, weight: .regular)
            let headerFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 13, weight: .regular)
            let labelFont = UIFont.systemFont(ofSize: 10, weight: .regular)

            // Compute all values before drawing so the header and body share the
            // same sunrise-based reference instant.
            let p = CosmicEngine.getPanchang(context: context)
            let nak = CosmicEngine.getMoonNakshatraPada(context: context)
            let sunNak = CosmicEngine.getSunNakshatra(context: context)
            let sunSignIdx = Int(sunNak.degree / 30.0) % 12
            let ss = CosmicEngine.getSunriseSunset(context: context)

            func transitionSuffix(_ transition: PanchangTransition?) -> String {
                transition.map {
                    let ending = $0.endTime.ritualTransitionLabel(
                        relativeTo: p.date,
                        in: context.timeZone
                    )
                    return " · until \(ending), then \($0.nextName)"
                } ?? ""
            }

            draw("✦ Cosmic Rituals", at: CGPoint(x: 36, y: 24), font: titleFont, color: gold)

            let dateStr = longDate(context.localNoon, timeZone: context.timeZone)
            draw(dateStr, at: CGPoint(x: 36, y: 60), font: subtitleFont, color: .white)
            let referenceLabel = p.sunriseTime == nil ? "local-noon fallback" : "sunrise reference"
            draw("Vedic Panchang · \(referenceLabel) · \(context.timeZoneIdentifier)", at: CGPoint(x: 36, y: 80), font: labelFont, color: subtle.withAlphaComponent(0.8))

            var y: CGFloat = 140

            // Section: Pancha Anga
            y = drawSection(title: "✦ Pancha Anga (Five Limbs)", at: y, width: pageRect.width,
                            headerFont: headerFont, color: gold, bgColor: gold.withAlphaComponent(0.1))

            let limbs: [(String, String)] = [
                ("Vara (Weekday)", p.weekdayName),
                ("Tithi (Lunar Day)", p.tithiName + (p.tithiIndex < 15 ? " · Shukla Paksha" : " · Krishna Paksha")
                 + transitionSuffix(p.transitions.tithi)),
                ("Nakshatra", "\(p.nakshatraName) · Pada \(nak.pada) · Lord: \(nak.nakshatraLord.rawValue)"
                 + transitionSuffix(p.transitions.nakshatra)),
                ("Yoga", p.yogaName + transitionSuffix(p.transitions.yoga)),
                ("Karana", p.karanaName + transitionSuffix(p.transitions.karana)),
            ]
            for (label, value) in limbs {
                draw(label, at: CGPoint(x: 48, y: y), font: labelFont, color: subtle)
                let valueHeight = drawWrapped(
                    value,
                    in: CGRect(x: 200, y: y, width: pageRect.width - 236, height: 58),
                    font: bodyFont,
                    color: .white
                )
                y += max(22, valueHeight + 6)
            }

            y += 12

            // Section: validated solar values only. Moonrise is intentionally hidden
            // until a real lunar altitude-crossing solver is available.
            y = drawSection(title: "✦ Solar Times", at: y, width: pageRect.width,
                            headerFont: headerFont, color: gold, bgColor: gold.withAlphaComponent(0.08))

            let times: [(String, String)] = [
                ("Sunrise", ss.map { shortTime($0.sunrise, timeZone: context.timeZone) } ?? "Unavailable"),
                ("Sunset",  ss.map { shortTime($0.sunset, timeZone: context.timeZone) } ?? "Unavailable"),
                ("Surya Rashi", ZodiacSign.fromIndex(sunSignIdx).name),
                ("Surya Nakshatra", sunNak.nakshatraName),
                ("Chandra Rashi", p.moonSignName),
            ]
            for (label, value) in times {
                draw(label, at: CGPoint(x: 48, y: y), font: labelFont, color: subtle)
                draw(value, at: CGPoint(x: 200, y: y), font: bodyFont, color: .white)
                y += 22
            }

            y += 12

            // Section: Muhurtas
            y = drawSection(title: "✦ Today's Muhurtas (top 10)", at: y, width: pageRect.width,
                            headerFont: headerFont, color: gold, bgColor: gold.withAlphaComponent(0.08))

            let muhurtas = CosmicEngine.getMuhurtas(context: context)
            let notable = muhurtas.filter { $0.quality == .excellent || $0.quality == .auspicious }.prefix(10)
            for m in notable {
                let start = m.startTime.ritualTransitionLabel(relativeTo: p.date, in: context.timeZone)
                let end = m.endTime.ritualTransitionLabel(relativeTo: p.date, in: context.timeZone)
                let timeStr = "\(start)–\(end)"
                draw(m.quality.emoji + " " + m.name, at: CGPoint(x: 48, y: y), font: bodyFont, color: .white)
                let timeHeight = drawWrapped(
                    timeStr,
                    in: CGRect(x: 300, y: y, width: pageRect.width - 336, height: 38),
                    font: labelFont,
                    color: subtle
                )
                y += max(20, timeHeight + 4)
                if y > pageRect.height - 80 { break }
            }

            y += 20

            // Footer
            let footerY = pageRect.height - 36
            subtle.setStroke()
            pdfCtx.move(to: CGPoint(x: 36, y: footerY - 8))
            pdfCtx.addLine(to: CGPoint(x: pageRect.width - 36, y: footerY - 8))
            pdfCtx.strokePath()
            draw("Generated by Cosmic Rituals · on-device, private · \(Date().ritualDate(template: "yMd", in: context.timeZone))",
                 at: CGPoint(x: 36, y: footerY), font: labelFont, color: subtle)
        }
    }

    // MARK: - Drawing Helpers

    @discardableResult
    private static func drawSection(title: String, at y: CGFloat, width: CGFloat,
                                    headerFont: UIFont, color: UIColor, bgColor: UIColor) -> CGFloat {
        let rect = CGRect(x: 24, y: y - 4, width: width - 48, height: 24)
        bgColor.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
        draw(title, at: CGPoint(x: 36, y: y), font: headerFont, color: color)
        return y + 28
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        (text as NSString).draw(at: point, withAttributes: attrs)
    }

    @discardableResult
    private static func drawWrapped(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor
    ) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 1
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: rect.width, height: rect.height),
            options: options,
            attributes: attrs,
            context: nil
        )
        let height = min(rect.height, ceil(bounds.height))
        (text as NSString).draw(
            with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height),
            options: options,
            attributes: attrs,
            context: nil
        )
        return height
    }

    private static func shortTime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    private static func longDate(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
}
