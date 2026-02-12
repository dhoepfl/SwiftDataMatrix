# SwiftDataMatrix

## Usage

The main (and only) public entry point is the following function:

```swift
dataMatrix(for data: Data,
           codeType: SwiftDataMatrixCodeType = .default,
           codeForm: SwiftDataMatrixCodeForm = .square)
    throws -> SwiftDataMatrixResult
```

By calling it, you get all information required to render the given data as DataMatrix code.

### Arguments

* `data`: The data to encode in the DataMatrix code
* `codeType`: The kind of DataMatrix code to generate:
              `.default` for standard codes, `.gs1` for codes with the GS1 marker
              (if the data start with FNC1, code 232, that code is removed),
              `.readerProgramming` for codes that are used to program barcode readers.
              Use `.format05`/`.format06` to set the appropriate markers for the formats
              defined by ISO/IEC 15434. Note that in these cases, the start/end markers
              in the data are removed, if present.
* `codeForm`: DataMatrix codes can be square or rectangular. Normally, `.square` codes
              are created. Using `.rectangular` enforces the use of rectangular codes
              that are, compared to square codes, limited in the maximum amount of data
              they can hold. By using `.preferRectangular`, you can request to get
              rectangular codes when they are not larger than the square equivalent.

### Errors thrown

The function might throw one of the following errors:

* `SwiftDataMatrixError.outOfSpace`: Thrown if the given amount of data cannot be encoded as DataMatrix code. The exact amount of data that can be encoded depends on the data, digits usually require less space than letters, binary data needs the most space.
* `SwiftDataMatrixError.invalidBlockSize`: This should never happen but can be treated the same as the previous error.

### Return Value

The `SwiftDataMatrixResult` structure contains the following information:

* `rawBitmap`: The image data as raw bytes. Every pixel is one bit, starting in the top left, going line by line until the bottom right pixel. If the width of the DataMatrix code is not a multiple of 8, padding bits are added at the right.
* `bytesPerRow`: The number of bytes each row in `rawBitmap` uses. (Currently that’s always `(width + 7)/8`)
* `width`: The width of the DataMatrix code/image in modules/pixel, including the finder patterns.
* `height`: The height of the DataMatrix code/image in modules/pixel, including the finder patterns.

## Example

```swift
import Foundation
import CoreGraphics
import UniformTypeIdentifiers
import SwiftDataMatrix

let width = 180
let height = 180
let content = "SwiftDataMatrix".data(using: .utf8)!

do {
    // Create DataMatrix code
    let dataMatrix = try dataMatrix(for: content)

    // Create a CGImage from the data:

    if let colorSpace = CGColorSpace(name: CGColorSpace.linearGray),
       let dataProvider = CGDataProvider(data: dataMatrix.rawBitmap as CFData),
       let cgImage = CGImage(width: dataMatrix.width,
                                height: dataMatrix.height,
                                bitsPerComponent: 1,
                                bitsPerPixel: 1,
                                bytesPerRow: dataMatrix.bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGBitmapInfo.byteOrderDefault,
                                provider: dataProvider,
                                decode: nil,
                                shouldInterpolate: false,
                                intent: .saturation) {
        // Scale result image
        if let colorSpace = CGColorSpace(name: CGColorSpace.linearGray),
           let context = CGContext(data: nil,
                                   width: width + 20,
                                   height: height + 20,
                                   bitsPerComponent: 8,
                                   bytesPerRow: width + 20,
                                   space: colorSpace,
                                   bitmapInfo: .byteOrderDefault) {
            // Fill background (creating white border)
            context.setFillColor(.white)
            context.fill(CGRect(x: 0, y: 0, width: width+20, height: height+20))

            // draw image to context (resizing it)
            context.interpolationQuality = .none
            context.draw(cgImage, in: CGRect(x: 10, y: 10, width: Int(width), height: Int(height)))

            // extract resulting image from context
            if let image = context.makeImage() {
                // Write the image to disk
                let targetURL = URL(filePath: "SwiftDataMatrix.png", directoryHint: .notDirectory) as CFURL
                if let destination = CGImageDestinationCreateWithURL(targetURL,
                                                                     UTType.png.identifier as CFString,
                                                                     1,
                                                                     nil) {
                    CGImageDestinationAddImageAndMetadata(destination,
                                                          image,
                                                          nil,
                                                          nil)
                    CGImageDestinationFinalize(destination)
                }
            }
        }
    }
} catch {
    print("Failed to create SwiftDataMatrix.png due to \(error.localizedDescription)")
}
```

## License

See [License](LICENSE.txt)
