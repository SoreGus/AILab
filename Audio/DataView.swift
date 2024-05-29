import SwiftUI
import AVFoundation

struct DataView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var isClass0Expanded = false
    @State private var isClass1Expanded = false
    @State private var selectedClass: Int = 0
    @State private var isRecording = false
    @State private var recordingDuration: Double = 5.0
    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var playingFile: URL? = nil
    @State private var trainingResponse: String?
    @State private var showingTrainingResult = false

    let durations = Array(stride(from: 5, through: 60, by: 5))

    var body: some View {
        VStack {
            List {
                Section(header: Text("Classe 0")) {
                    DisclosureGroup(isExpanded: $isClass0Expanded) {
                        ForEach(audioManager.getAllFiles(from: "class0"), id: \.self) { fileURL in
                            DataViewRow(fileURL: fileURL, audioManager: audioManager, playingFile: $playingFile)
                        }
                        .onDelete { indexSet in
                            deleteFiles(at: indexSet, from: "class0")
                        }
                    } label: {
                        Text("Classe 0")
                    }
                }

                Section(header: Text("Classe 1")) {
                    DisclosureGroup(isExpanded: $isClass1Expanded) {
                        ForEach(audioManager.getAllFiles(from: "class1"), id: \.self) { fileURL in
                            DataViewRow(fileURL: fileURL, audioManager: audioManager, playingFile: $playingFile)
                        }
                        .onDelete { indexSet in
                            deleteFiles(at: indexSet, from: "class1")
                        }
                    } label: {
                        Text("Classe 1")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            VStack {
                Picker("Duração da Gravação", selection: $recordingDuration) {
                    ForEach(durations, id: \.self) { duration in
                        Text("\(duration) segundos").tag(Double(duration))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                HStack {
                    Button(action: {
                        selectedClass = 0
                        startRecording()
                    }) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(isRecording && selectedClass == 0 ? .red : .gray)
                            Text("Gravar Classe 0")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    Button(action: {
                        selectedClass = 1
                        startRecording()
                    }) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(isRecording && selectedClass == 1 ? .red : .gray)
                            Text("Gravar Classe 1")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }

                if isRecording {
                    Text("Tempo Restante: \(Int(remainingTime)) segundos")
                        .font(.headline)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Registros Locais")
        .navigationBarItems(trailing: Button(action: {
            sendTrainings()
        }) {
            Text("Enviar Treinamentos")
        })
        .sheet(isPresented: $showingTrainingResult) {
            TrainingResultView(isPresented: $showingTrainingResult, result: trainingResponse ?? "Erro desconhecido")
        }
        .onAppear {
            audioManager.setupAudioSession()
            audioManager.requestMicrophonePermission()
        }
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        remainingTime = recordingDuration
        audioManager.selectedFolder = selectedClass == 0 ? "class0" : "class1"
        audioManager.startRecording(duration: recordingDuration) {
            self.isRecording = false
            self.stopTimer()
            DispatchQueue.main.async {
                audioManager.objectWillChange.send()
            }
        }
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func sendTrainings() {
        audioManager.trainModel { response in
            self.trainingResponse = response
            self.showingTrainingResult = true
        }
    }

    private func deleteFiles(at offsets: IndexSet, from folder: String) {
        let files = audioManager.getAllFiles(from: folder)
        for index in offsets {
            do {
                try FileManager.default.removeItem(at: files[index])
            } catch {
                print("Erro ao deletar arquivo: \(error)")
            }
        }
        audioManager.objectWillChange.send()
    }
}

struct DataViewRow: View {
    var fileURL: URL
    @StateObject var audioManager: AudioManager
    @Binding var playingFile: URL?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(fileURL.lastPathComponent)
                Text("Duração: \(audioManager.getAudioDuration(fileURL: fileURL)) segundos")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: {
                if playingFile == fileURL {
                    audioManager.stopPlaying()
                    playingFile = nil
                } else {
                    audioManager.playAudio(fileURL: fileURL)
                    playingFile = fileURL
                }
            }) {
                Image(systemName: playingFile == fileURL ? "stop.fill" : "play.fill")
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        .padding(.vertical, 4)
    }
}

struct DataView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataView()
        }
    }
}
