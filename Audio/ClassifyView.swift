import SwiftUI

struct ClassifyView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var selectedDuration = 5.0
    @State private var remainingTime = 0.0
    @State private var timer: Timer?
    @State private var classificationResponse: String?

    let durations = Array(stride(from: 5, through: 60, by: 5))

    var body: some View {
        VStack(spacing: 20) {
            Picker("Duration", selection: $selectedDuration) {
                ForEach(durations, id: \.self) { duration in
                    Text("\(duration) seconds").tag(Double(duration))
                }
            }
            .pickerStyle(WheelPickerStyle())

            if audioManager.isRecording {
                Text("Remaining Time: \(Int(remainingTime)) seconds")
                    .font(.headline)
            }

            Button(action: {
                if self.audioManager.isRecording {
                    self.audioManager.stopRecording()
                    self.stopTimer()
                } else {
                    self.audioManager.selectedFolder = "classify"
                    self.audioManager.startRecording(duration: self.selectedDuration)
                    self.startTimer()
                }
            }) {
                Circle()
                    .fill(self.audioManager.isRecording ? Color.green : (self.audioManager.isSaved ? Color.blue : Color.gray))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(self.audioManager.isRecording ? "Gravando" : (self.audioManager.isSaved ? "Nova Gravação" : "Iniciar"))
                            .foregroundColor(.white)
                            .bold()
                    )
            }

            if audioManager.isSaved || audioManager.isRecording {
                HStack(spacing: 40) {
                    Button(action: {
                        self.audioManager.playRecording()
                    }) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                            )
                    }

                    Button(action: {
                        if self.audioManager.isRecording {
                            self.audioManager.stopRecording()
                            self.stopTimer()
                        } else if self.audioManager.audioPlayer?.isPlaying == true {
                            self.audioManager.audioPlayer?.stop()
                        }
                        self.audioManager.resetRecordingState()
                    }) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.white)
                            )
                    }
                }
            }

            Button(action: {
                if let lastRecordedFile = audioManager.getLastRecordedFileURL() {
                    audioManager.api.classify(audioFile: lastRecordedFile) { result in
                        switch result {
                        case .success(let classIndex):
                            let responseString = "Classificação: \(classIndex)"
                            print(responseString)
                            DispatchQueue.main.async {
                                self.classificationResponse = responseString
                            }
                        case .failure(let error):
                            let errorMsg = "Erro: \(error.localizedDescription)"
                            print(errorMsg)
                            DispatchQueue.main.async {
                                self.classificationResponse = errorMsg
                            }
                        }
                    }
                }
            }) {
                Text("Classify Recording")
                    .bold()
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let response = classificationResponse {
                Text(response)
                    .font(.headline)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            self.audioManager.setupAudioSession()
            self.audioManager.requestMicrophonePermission()
        }
    }

    private func startTimer() {
        remainingTime = selectedDuration
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.stopTimer()
                self.audioManager.stopRecording()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
