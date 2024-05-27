import SwiftUI

struct MasterView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var showClassifyView = false
    @State private var showContentView = false
    @State private var nnName = ""
    @State private var responseMessage: String?
    @State private var showAlert = false  // Estado para controlar a exibição do alerta

    var body: some View {
        NavigationView {
            VStack {
                TextField("Nome da Rede Neural", text: $nnName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: nnName) { newValue in
                        audioManager.nnName = newValue
                    }

                List {
                    Section(header: Text("Ações")) {
                        Button(action: {
                            if !nnName.isEmpty {
                                audioManager.initNN(name: nnName) { response in
                                    self.responseMessage = response
                                }
                            } else {
                                self.responseMessage = "O nome da rede neural não pode estar vazio."
                            }
                        }) {
                            Text("Iniciar")
                        }

                        NavigationLink(destination: ClassifyView()) {
                            Text("Classificar")
                        }

                        NavigationLink(destination: ContentView()) {
                            Text("Treinar")
                        }

                        Button(action: {
                            audioManager.saveNN { response in
                                self.responseMessage = response
                            }
                        }) {
                            Text("Salvar")
                        }

                        Button(action: {
                            showAlert = true  // Mostrar o alerta de confirmação
                        }) {
                            Text("Limpar")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Confirmação"),
                        message: Text("Tem certeza de que deseja limpar todos os arquivos?"),
                        primaryButton: .destructive(Text("Limpar")) {
                            audioManager.deleteAllFiles()
                            responseMessage = "Todos os arquivos foram deletados."
                            nnName = ""
                        },
                        secondaryButton: .cancel()
                    )
                }

                if let response = responseMessage {
                    Text(response)
                        .font(.headline)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("Laboratório IA")
            .onAppear {
                self.audioManager.setupAudioSession()
                self.audioManager.requestMicrophonePermission()
                self.audioManager.printDocumentsDirectory()
                if let lastSavedNN = audioManager.loadLastSavedNN() {
                    self.nnName = lastSavedNN
                    self.audioManager.nnName = lastSavedNN
                }
            }
        }
    }
}

struct MasterView_Previews: PreviewProvider {
    static var previews: some View {
        MasterView()
    }
}
