// ImageClassifierModel.swift
import Vision

class ImageClassifierModel {
    private let vnModel: VNCoreMLModel

    init(mlModel: MLModel) throws {
        self.vnModel = try VNCoreMLModel(for: mlModel)
    }

    func classifyImage(_ cgImage: CGImage) async -> (label: String, probabilities: [String: Double]) {
        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(returning: ("", [:]))
                    return
                }
                let label = topResult.identifier
                let probabilities = results.reduce(into: [String: Double]()) { dict, observation in
                    dict[observation.identifier] = Double(observation.confidence)
                }
                continuation.resume(returning: (label, probabilities))
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
