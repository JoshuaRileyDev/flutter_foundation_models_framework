import Foundation
import FoundationModels

@available(iOS 26.0, macOS 15.0, *)
actor SessionManager {
    private var sessions: [String: LanguageModelSession] = [:]
    private var transcripts: [String: [Transcript.Entry]] = [:]

    func store(_ session: LanguageModelSession, for id: String) {
        sessions[id] = session
        // Initialize empty transcript for new sessions
        transcripts[id] = []
    }

    func session(for id: String) -> LanguageModelSession? {
        return sessions[id]
    }

    func transcript(for id: String) -> [Transcript.Entry] {
        return transcripts[id] ?? []
    }

    func setTranscript(_ transcript: [Transcript.Entry], for id: String) {
        transcripts[id] = transcript
    }

    func appendToTranscript(_ entry: Transcript.Entry, for id: String) {
        if transcripts[id] != nil {
            transcripts[id]?.append(entry)
        } else {
            transcripts[id] = [entry]
        }
    }

    func removeSession(for id: String) {
        sessions.removeValue(forKey: id)
        transcripts.removeValue(forKey: id)
    }

    func removeAll() {
        sessions.removeAll()
        transcripts.removeAll()
    }
}
