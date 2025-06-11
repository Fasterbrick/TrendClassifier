import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = ImageClassifierViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        ZStack {
            // Gradient background covering the entire view
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.24),
                    Color(red: 0.02, green: 0.24, blue: 0.31),
                    Color(red: 0.11, green: 0.35, blue: 0.41)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // PhotosPicker button with a glass effect
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Select an image")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)  // Glass (blur) effect
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                .padding(.top)
                
                if let image = viewModel.selectedImage {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50) // Smaller image size
                    #elseif os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                    #endif
                }
                
                ScrollView {
                    VStack(alignment: .leading) {
                        modelResultView(title: "Model 1:", prediction: viewModel.prediction1, probabilities: viewModel.probabilities1)
                        modelResultView(title: "Model 2:", prediction: viewModel.prediction2, probabilities: viewModel.probabilities2)
                        modelResultView(title: "Model 3:", prediction: viewModel.prediction3, probabilities: viewModel.probabilities3)
                        modelResultView(title: "Model 4:", prediction: viewModel.prediction4, probabilities: viewModel.probabilities4)
                           
                    }
                    
                }
                
                // Overall recommendation summary
                Text("Overall Recommendation: \(viewModel.overallRecommendation)")
                    .font(.headline)
                    .padding(.top)
            }
            .padding()
            .foregroundStyle(.white)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let item = newItem else { return }
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        #if os(iOS)
                        if let uiImage = UIImage(data: data) {
                            viewModel.selectedImage = uiImage
                            viewModel.classify()
                        }
                        #elseif os(macOS)
                        if let nsImage = NSImage(data: data) {
                            viewModel.selectedImage = nsImage
                            viewModel.classify()
                        }
                        #endif
                    } else {
                        print("Loaded data is nil")
                    }
                } catch {
                    print("Failed to load image data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Moved outside of body property
    @ViewBuilder
    private func modelResultView(title: String, prediction: String, probabilities: [String: Double]) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text("Prediction: \(prediction)")
                .font(.body)
            if !probabilities.isEmpty {
                ForEach(probabilities.sorted(by: { $0.value > $1.value }), id: \.key) { label, prob in
                    Text("\(label): \(String(format: "%.2f", prob * 100))%")
                        .font(.body)
                        
                }
            }
        }
        .padding()
    }
}
