import CoreGraphics
import ImageIO
import Foundation

let size = 1024
let space = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("no se pudo crear el lienzo") }
context.setFillColor(CGColor(red: 0.70, green: 0.77, blue: 0.71, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
context.setStrokeColor(CGColor(red: 0.06, green: 0.08, blue: 0.06, alpha: 1))
context.setLineWidth(115)
context.setLineCap(.round)
context.move(to: CGPoint(x: 288, y: 298))
context.addCurve(to: CGPoint(x: 736, y: 726), control1: CGPoint(x: 786, y: 298), control2: CGPoint(x: 238, y: 726))
context.strokePath()
context.setFillColor(CGColor(red: 0.94, green: 0.43, blue: 0.12, alpha: 1))
context.fillEllipse(in: CGRect(x: 674, y: 664, width: 124, height: 124))
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let image = context.makeImage(), let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { fatalError("no se pudo crear el archivo") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("no se pudo guardar el icono") }
