import Foundation

class AudioClassifierAPI {
    let baseURL = "http://192.168.0.93:8080"
    
    func initNN(name: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/initNN") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["name": name]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let errorMsg = "Error: \(error?.localizedDescription ?? "No data")"
                print(errorMsg)
                completion(errorMsg)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("initNN Response: \(responseString ?? "No response")")
            completion(responseString)
        }.resume()
    }
    
    func saveNN(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/saveNN") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let errorMsg = "Error: \(error?.localizedDescription ?? "No data")"
                print(errorMsg)
                completion(errorMsg)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("saveNN Response: \(responseString ?? "No response")")
            completion(responseString)
        }.resume()
    }
    
    func trainNN(audioFiles: [URL], labels: [Int], completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/trainNN") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        for (index, audioFile) in audioFiles.enumerated() {
            let filename = audioFile.lastPathComponent
            guard let data = try? Data(contentsOf: audioFile) else { continue }
            let mimetype = "audio/wav"
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio_files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        for label in labels {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"labels\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(label)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let errorMsg = "Error: \(error?.localizedDescription ?? "No data")"
                print(errorMsg)
                completion(errorMsg)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("trainNN Response: \(responseString ?? "No response")")
            completion(responseString)
        }.resume()
    }
    
    func classify(audioFile: URL, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/classify") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        let filename = audioFile.lastPathComponent
        guard let data = try? Data(contentsOf: audioFile) else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid file data"])
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        let mimetype = "audio/wav"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let classIndex = json["class"] as? Int, let confidence = json["confidence"] as? Float {
                    print("classify Response: class -> \(classIndex) | confidence -> \(confidence)")
                    let resultDict = ["class": classIndex, "confidence": confidence]
                    completion(.success(resultDict))
                } else {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// Extension to append data to Data object
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
