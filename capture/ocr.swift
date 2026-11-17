// ocr.swift - print the text found in an image file (Vision, accurate, language auto).
// Usage: ocr <image-path>. Exit 0 with text on stdout, 1 on error or no text.
// Needs macOS 13+ for automatic language detection; builds for macOS 15.
import Foundation
import Vision
import ImageIO

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

let args = CommandLine.arguments
if args.count != 2 || args[1] == "-h" || args[1] == "--help" {
    print("usage: ocr <image-path>   print recognised text (Vision, accurate, auto language)")
    exit(args.count == 2 ? 0 : 2)
}

let url = URL(fileURLWithPath: args[1])
guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    fail("ocr: cannot read image \(args[1])")
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
request.automaticallyDetectsLanguage = true

do {
    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
} catch {
    fail("ocr: Vision failed: \(error.localizedDescription)")
}

let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
let text = lines.joined(separator: "\n")
if text.isEmpty { fail("ocr: no text found") }
print(text)
