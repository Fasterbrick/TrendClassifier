import SwiftUI
import Vision

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

class ImageClassifierViewModel: ObservableObject {
    @Published var selectedImage: PlatformImage?
    @Published var prediction1: String = ""
    @Published var probabilities1: [String: Double] = [:]
    @Published var prediction2: String = ""
    @Published var probabilities2: [String: Double] = [:]
    @Published var prediction3: String = ""
    @Published var probabilities3: [String: Double] = [:]
    @Published var prediction4: String = ""
    @Published var probabilities4: [String: Double] = [:]
    
    private let model1: ImageClassifierModel
    private let model2: ImageClassifierModel
    private let model3: ImageClassifierModel
    private let model4: ImageClassifierModel
    private var isClassifying = false

    init() {
        do {
            let config = MLModelConfiguration()
            let Modeln1 = try Chart_Patterns_1(configuration: config).model
            self.model1 = try ImageClassifierModel(mlModel: Modeln1)
            let Modeln2 = try Chart_Patterns_2(configuration: config).model
            self.model2 = try ImageClassifierModel(mlModel: Modeln2)
            let Modeln3 = try Chart_Patterns_3(configuration: config).model
            self.model3 = try ImageClassifierModel(mlModel: Modeln3)
            let Modeln4 = try Chart_Patterns_4(configuration: config).model
            self.model4 = try ImageClassifierModel(mlModel: Modeln4)
            
        } catch {
            fatalError("Failed to load models: \(error)")
        }
    }
    
    // Computed property to summarize predictions from both models.
    var overallRecommendation: String {
        // Split the comma-separated prediction strings into arrays.
        let predictions1 = prediction1.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let predictions2 = prediction2.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let predictions3 = prediction3.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let predictions4 = prediction4.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Define bullish and bearish patterns for Model 1.
        let bullishModel1 = ["Morning Star", "Hammer", "Bullish Engulfing", "Three White Soldiers"]
        let bearishModel1 = ["Three Black Crows", "Bearish Engulfing", "Evening Star", "Hanging Man"]
        
        // Define bullish and bearish patterns for Model 2.
        let bullishModel2 = ["MMBM"]
        let bearishModel2 = ["MMSM"]
        
        // bullish and bearish patterns for Model 3
        let bullishModel3 = ["Bullish Bat", "Bullish Pennant", "Bullish Rectangle", "Cup and Handle", "Double Bottom", "Falling Wedge", "Inverse Head and Shoulders", "Rounding Bottom", "Triple Bottom"];
        let bearishModel3 = ["Bearish Bat", "Bearish Diamond", "Bearish Pennant", "Bearish Rectangle", "Double Top", "Head and Shoulders", "Inverse Cap and Handle", "Rising Wedge", "Rounding Top", "Triple Top"]
        
        // Define bullish and bearish direction Model 4.
        let bullishModel4 = ["Buy"]
        let bearishModel4 = ["Sell"];
        
        var score = 0
        
        for prediction in predictions1 {
            if bullishModel1.contains(String(prediction)) {
                score += 1
            } else if bearishModel1.contains(String(prediction)) {
                score -= 1
            }
        }
        
        for prediction in predictions2 {
            if bullishModel2.contains(String(prediction)) {
                score += 1
            } else if bearishModel2.contains(String(prediction)) {
                score -= 1
            }
        }
        for prediction in predictions3 {
            if bullishModel3.contains(String(prediction)) {
                score += 1
            } else if bearishModel3.contains(String(prediction)) {
                score -= 1
            }
        }
        for prediction in predictions4 {
            if bullishModel4.contains(String(prediction)) {
                score += 1
            } else if bearishModel4.contains(String(prediction)) {
                score -= 1
            }
        }
        
        if score > 0 {
            return "Buy"
        } else if score < 0 {
            return "Sell"
        } else {
            return "Neutral"
        }
    }
    
    func classify() {
        guard !isClassifying else { return }
        isClassifying = true
        
        guard let image = selectedImage else {
            print("No image selected")
            isClassifying = false
            return
        }
        
        Task {
            let cgImage: CGImage?
            #if os(iOS)
            cgImage = image.cgImage
            #elseif os(macOS)
            cgImage = image.cgImage
            #endif
            
            guard let cgImage else {
                print("Failed to convert image to CGImage")
                await MainActor.run { isClassifying = false }
                return
            }
            
            // Removed 'try' since classifyImage doesn't throw
            async let result1 = model1.classifyImage(cgImage)
            async let result2 = model2.classifyImage(cgImage)
            async let result3 = model3.classifyImage(cgImage)
            async let result4 = model4.classifyImage(cgImage)
            
            let (res1, res2, res3, res4) = await (result1, result2, result3, result4)
            
            await MainActor.run {
                self.prediction1 = res1.label
                self.probabilities1 = res1.probabilities
                self.prediction2 = res2.label
                self.probabilities2 = res2.probabilities
                self.prediction3 = res3.label
                self.probabilities3 = res3.probabilities
                self.prediction4 = res4.label
                self.probabilities4 = res4.probabilities
                self.isClassifying = false
            }
        }
    }
}

#if os(macOS)
extension NSImage {
    var cgImage: CGImage? {
        guard let imageData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData) else {
            return nil
        }
        return bitmap.cgImage
    }
}
#endif
