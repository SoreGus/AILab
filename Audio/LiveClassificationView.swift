import SwiftUI
import AVFoundation

struct LiveClassificationView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var isRecording = false
    @State private var classificationResult: String?
    @State private var classificationConfidence: Double?
    @State private var classificationColor: Color = Color(.systemBackground)
    @State private var errorMessage: String?
    @State private var isErrorPresented = false

    let recordingDuration: TimeInterval = 3.0

    var body: some View {
        VStack {
            Text(classificationResult ?? "Categoria")
                .font(.largeTitle)
                .padding()
                .background(classificationColor)
                .cornerRadius(10)
                .padding()

            if let confidence = classificationConfidence, let result = classificationResult {
                Text("Classificação: \(result) com \(Int(confidence * 100))% de confiança")
                    .font(.headline)
                    .padding()
                    .foregroundColor(confidence >= 0.8 ? .primary : .red)
            }

            Button(action: {
                if isRecording {
                    stopLiveClassification()
                } else {
                    startLiveClassification()
                }
            }) {
                Text(isRecording ? "Parar Classificação" : "Iniciar Classificação ao Vivo")
                    .bold()
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(classificationColor)
        .alert(isPresented: $isErrorPresented) {
            Alert(title: Text("Erro"), message: Text(errorMessage ?? "Erro desconhecido"), dismissButton: .default(Text("OK")))
        }
    }

    private func startLiveClassification() {
        isRecording = true
        classificationResult = nil
        classificationConfidence = nil
        classificationColor = Color(.systemBackground)
        recordAndClassify()
    }

    private func stopLiveClassification() {
        isRecording = false
        audioManager.stopRecording()
    }

    private func recordAndClassify() {
        guard isRecording else { return }

        audioManager.startRecording(duration: recordingDuration, isLiveClassification: true) {
            if let lastFile = self.audioManager.getLastRecordedFileURL(isLiveClassification: true) {
                self.audioManager.classify(audioFile: lastFile) { result in
                    switch result {
                    case .success(let response):
                        if let classIndex = response["class"] as? Int,
                           let confidence = response["confidence"] as? Float {
                            self.classificationConfidence = Double(confidence)
                            self.classificationResult = "Classe \(classIndex)"
                            if confidence >= 0.8 {
                                self.classificationColor = classIndex == 0 ? .green : .blue
                            } else {
                                self.classificationColor = Color(.systemBackground)
                            }
                            
                            // Exibir mensagens de callback para o usuário
                            if confidence < 0.8 {
                                self.classificationResult = "Classe \(classIndex) com \(Int(confidence * 100))% de confiança"
                            }
                        }
                    case .failure(let error):
                        self.errorMessage = "Erro na classificação: \(error.localizedDescription)"
                        self.isErrorPresented = true
                    }

                    // Inicia a próxima gravação
                    self.recordAndClassify()
                }
            }
        }
    }
}

struct LiveClassificationView_Previews: PreviewProvider {
    static var previews: some View {
        LiveClassificationView()
    }
}
