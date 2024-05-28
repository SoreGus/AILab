import SwiftUI
import AVFoundation

struct LiveClassificationView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var isClassifying = false
    @State private var classificationResult = "Categoria"
    @State private var backgroundColor = Color.white
    @State private var timer: Timer?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text(classificationResult)
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .padding()
                
                Button(action: {
                    if isClassifying {
                        stopClassification()
                    } else {
                        startClassification()
                    }
                }) {
                    Text(isClassifying ? "Parar classificação" : "Iniciar classificação ao vivo")
                        .bold()
                        .padding()
                        .background(isClassifying ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private func startClassification() {
        isClassifying = true
        backgroundColor = Color.white
        classificationResult = "Categoria"
        errorMessage = nil
        
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            classifyAudio()
        }
    }
    
    private func stopClassification() {
        isClassifying = false
        timer?.invalidate()
        timer = nil
        backgroundColor = Color.white
        classificationResult = "Categoria"
        audioManager.stopRecording()
    }
    
    private func classifyAudio() {
        let audioFilename = audioManager.getDocumentsDirectory().appendingPathComponent("live_classification.wav")
        audioManager.startRecording(duration: 3, fileURL: audioFilename)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            self.audioManager.stopRecording()
            self.audioManager.classify(audioFile: audioFilename) { result in
                switch result {
                case .success(let result):
                    let classIndex = result["class"] as? Int ?? -1
                    let confidence = result["confidence"] as? Float ?? Float(-1)
                    switch classIndex {
                    case 0:
                        if confidence > 0.9 {
                            self.backgroundColor = Color.green
                            self.classificationResult = "Classe 0"
                        } else {
                            self.backgroundColor = Color.white
                            self.classificationResult = "Classe 0 : \(confidence)"
                        }
                    case 1:
                        if confidence > 0.9 {
                            self.backgroundColor = Color.blue
                            self.classificationResult = "Classe 1"
                        } else {
                            self.backgroundColor = Color.white
                            self.classificationResult = "Classe 1 : \(confidence)"
                        }
                    case -1:
                        self.backgroundColor = Color.white
                        self.classificationResult = "None"
                    default:
                        break
                    }
                case .failure(let error):
                    self.errorMessage = "Erro na classificação: \(error.localizedDescription)"
                    self.stopClassification()
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
