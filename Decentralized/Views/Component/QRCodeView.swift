//
//  SwiftUIView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/28.
//
import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeView: View {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    let data: String?

    var size: CGFloat = 100
    

    var body: some View {
        if let data = data {
            if let qrCodeImage = generateQRCode(from: data) {
                Image(nsImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size, height: size)
            }
        } else {
            Image(systemName: "exclamationmark.triangle")
                .interpolation(.none)
                .resizable()
                .frame(width: size, height: size)
        }
    }

    func generateQRCode(from string: String) -> NSImage? {
        filter.message = Data(string.utf8)

        guard let outputImage = filter.outputImage else { return nil }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 200, height: 200))
            return nsImage
        }

        return nil
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            QRCodeView(data: "https://www.example.com")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
