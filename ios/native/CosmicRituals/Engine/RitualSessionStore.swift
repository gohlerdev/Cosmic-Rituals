import Combine
import Foundation

enum RitualSessionStatus: String, Codable, Equatable, Sendable {
    case preparing
    case inProgress
    case completed
}

/// The minimum durable state needed to recover a household ritual after an
/// interruption. It intentionally stores no location, religious profile,
/// analytics identifier, or cloud account data.
struct RitualSession: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var catalogVersion: Int
    var status: RitualSessionStatus
    var preparedMaterialIDs: Set<String>
    var currentStepIndex: Int
    var startedAt: Date?
    var completedAt: Date?
    var updatedAt: Date

    var hasUserProgress: Bool {
        status != .preparing || !preparedMaterialIDs.isEmpty
    }
}

private struct RitualSessionEnvelope: Codable {
    let schemaVersion: Int
    let sessions: [String: RitualSession]
}

/// Local-only owner of recoverable preparation and guided-practice progress.
/// Writes are deliberately small and synchronous so every tap has reached
/// durable storage before the app can be backgrounded or terminated.
@MainActor
final class RitualSessionStore: ObservableObject {
    static let schemaVersion = 1
    static let defaultStorageKey = "cosmicRituals.ritualSessions.v1"

    @Published private(set) var sessions: [String: RitualSession] = [:]

    private let defaults: UserDefaults?
    private let storageKey: String
    private let now: () -> Date

    init(
        defaults: UserDefaults? = .standard,
        storageKey: String = "cosmicRituals.ritualSessions.v1",
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.now = now
        sessions = Self.loadSessions(from: defaults, storageKey: storageKey)
        reconcileWithCatalog()
    }

    var mostRecentUnfinishedSession: RitualSession? {
        sessions.values
            .filter { $0.status != .completed && $0.hasUserProgress }
            .max { $0.updatedAt < $1.updatedAt }
    }

    func session(for vidhi: PoojaVidhi) -> RitualSession {
        sanitized(sessions[vidhi.id] ?? newSession(for: vidhi), for: vidhi)
    }

    func toggleMaterial(_ materialID: String, for vidhi: PoojaVidhi) {
        guard vidhi.materials.contains(where: { $0.id == materialID }) else { return }
        mutate(vidhi) { session in
            if session.preparedMaterialIDs.contains(materialID) {
                session.preparedMaterialIDs.remove(materialID)
            } else {
                session.preparedMaterialIDs.insert(materialID)
            }
        }
    }

    func begin(_ vidhi: PoojaVidhi) {
        mutate(vidhi) { session in
            if session.status == .completed {
                session.currentStepIndex = 0
                session.completedAt = nil
                session.startedAt = self.now()
            } else if session.startedAt == nil {
                session.startedAt = self.now()
            }
            session.status = .inProgress
        }
    }

    func previousStep(in vidhi: PoojaVidhi) {
        mutate(vidhi) { session in
            guard session.status != .completed else { return }
            session.status = .inProgress
            session.currentStepIndex = max(0, session.currentStepIndex - 1)
        }
    }

    func advance(in vidhi: PoojaVidhi) {
        mutate(vidhi) { session in
            let finalIndex = max(0, vidhi.steps.count - 1)
            if session.currentStepIndex >= finalIndex {
                session.currentStepIndex = finalIndex
                session.status = .completed
                session.completedAt = self.now()
            } else {
                session.status = .inProgress
                session.currentStepIndex += 1
            }
        }
    }

    func restartGuidedPractice(_ vidhi: PoojaVidhi) {
        mutate(vidhi) { session in
            session.status = .inProgress
            session.currentStepIndex = 0
            session.startedAt = self.now()
            session.completedAt = nil
        }
    }

    private func mutate(_ vidhi: PoojaVidhi, change: (inout RitualSession) -> Void) {
        var value = session(for: vidhi)
        change(&value)
        value.updatedAt = now()
        sessions[vidhi.id] = sanitized(value, for: vidhi)
        persist()
    }

    private func newSession(for vidhi: PoojaVidhi) -> RitualSession {
        RitualSession(
            id: vidhi.id,
            catalogVersion: PoojaContentPolicy.catalogVersion,
            status: .preparing,
            preparedMaterialIDs: [],
            currentStepIndex: 0,
            startedAt: nil,
            completedAt: nil,
            updatedAt: .distantPast
        )
    }

    private func sanitized(_ session: RitualSession, for vidhi: PoojaVidhi) -> RitualSession {
        var value = session
        let validMaterialIDs = Set(vidhi.materials.map(\.id))
        value.catalogVersion = PoojaContentPolicy.catalogVersion
        value.preparedMaterialIDs.formIntersection(validMaterialIDs)
        value.currentStepIndex = value.currentStepIndex.clamped(to: 0...max(0, vidhi.steps.count - 1))
        if value.status == .completed {
            value.currentStepIndex = max(0, vidhi.steps.count - 1)
        } else {
            value.completedAt = nil
        }
        return value
    }

    private func reconcileWithCatalog() {
        let catalogByID = Dictionary(uniqueKeysWithValues: PoojaVidhiCatalog.all.map { ($0.id, $0) })
        sessions = sessions.reduce(into: [:]) { result, entry in
            guard let vidhi = catalogByID[entry.key] else { return }
            result[entry.key] = sanitized(entry.value, for: vidhi)
        }
        persist()
    }

    private func persist() {
        guard let defaults else { return }
        let envelope = RitualSessionEnvelope(schemaVersion: Self.schemaVersion, sessions: sessions)
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func loadSessions(from defaults: UserDefaults?, storageKey: String) -> [String: RitualSession] {
        guard let data = defaults?.data(forKey: storageKey),
              let envelope = try? JSONDecoder().decode(RitualSessionEnvelope.self, from: data),
              envelope.schemaVersion == schemaVersion else {
            return [:]
        }
        return envelope.sessions
    }
}
