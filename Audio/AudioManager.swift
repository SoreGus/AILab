import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    @Published var isRecording = false
    @Published var isSaved = false
    var selectedFolder = "class1"  // Default folder
    let api = AudioClassifierAPI()  // Instância da API

    let userDefaultsKey = "lastSavedNNName"
    var nnName: String?

    func startRecording(duration: TimeInterval, fileURL: URL? = nil) {
        let timestamp = Date().timeIntervalSince1970
        var audioFilename = getDocumentsDirectory().appendingPathComponent(selectedFolder).appendingPathComponent("\(timestamp).wav")
        if let fileURL {
            audioFilename = fileURL
        }

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        do {
            try FileManager.default.createDirectory(at: audioFilename.deletingLastPathComponent(), withIntermediateDirectories: true)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.record(forDuration: duration)
            isRecording = true
            isSaved = false
            print("Recording started: \(audioFilename)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        if let audioRecorder = audioRecorder, audioRecorder.isRecording {
            audioRecorder.stop()
            isRecording = false
            print("Recording stopped")
        }
    }

    func playRecording() {
        guard let audioFilename = getLastRecordedFileURL() else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Playing recording: \(audioFilename)")
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func printDocumentsDirectory() {
        let documentsDirectory = getDocumentsDirectory()
        print("Documents Directory: \(documentsDirectory.path)")
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully")
            isRecording = false
            isSaved = true
        } else {
            print("Recording failed")
            isRecording = false
            isSaved = false
        }
    }

    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission not granted")
            }
        }
    }

    func resetRecordingState() {
        self.isRecording = false
        self.isSaved = false
    }

    func getLastRecordedFileURL() -> URL? {
        let directoryURL = getDocumentsDirectory().appendingPathComponent(selectedFolder)
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            let sortedFiles = files.sorted { $0.lastPathComponent.compare($1.lastPathComponent) == .orderedDescending }
            if let lastFile = sortedFiles.first {
                return lastFile
            }
        } catch {
            print("Failed to list files: \(error.localizedDescription)")
        }
        return nil
    }

    func trainModel(completion: @escaping (String?) -> Void) {
        let class0Files = getAllFiles(from: "class0")
        let class1Files = getAllFiles(from: "class1")
        
        let audioFiles = class0Files + class1Files
        let labels = Array(repeating: 0, count: class0Files.count) + Array(repeating: 1, count: class1Files.count)
        
        api.trainNN(audioFiles: audioFiles, labels: labels) { response in
            DispatchQueue.main.async {
                if response == "Treinamento concluído com sucesso!" {
                    self.deleteAllFiles()
                }
                completion(response)
            }
        }
    }
    
    private func getAllFiles(from folder: String) -> [URL] {
        let directoryURL = getDocumentsDirectory().appendingPathComponent(folder)
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "wav" }  // Filtrar apenas arquivos .wav
        } catch {
            print("Failed to list files: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteAllFiles() {
        let documentsDirectory = getDocumentsDirectory()
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            print("All files deleted successfully.")
            // Remove the last saved neural network name
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            self.nnName = nil
        } catch {
            print("Failed to delete files: \(error.localizedDescription)")
        }
    }

    func initNN(name: String, completion: @escaping (String?) -> Void) {
        guard !name.isEmpty else {
            completion("O nome da rede neural não pode estar vazio.")
            return
        }
        
        api.initNN(name: name) { response in
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }

    func saveNN(completion: @escaping (String?) -> Void) {
        api.saveNN { response in
            if response == "Rede neural \(self.nnName ?? "") salva com sucesso!" {
                // Save the name to UserDefaults
                UserDefaults.standard.set(self.nnName, forKey: self.userDefaultsKey)
            }
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }

    func loadLastSavedNN() -> String? {
        return UserDefaults.standard.string(forKey: userDefaultsKey)
    }

    func classify(audioFile: URL, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        api.classify(audioFile: audioFile) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
