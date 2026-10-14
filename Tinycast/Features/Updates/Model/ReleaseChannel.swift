import Foundation

/// Side-by-side apps with their own bundle ids, so a build updates within its own.
enum ReleaseChannel: Sendable {
    case stable
    case beta
    /// This fork's own build, which updates from the fork's releases rather than upstream's.
    case fork
    /// A local build. It has no release stream, and never updates itself.
    case development

    init(bundleID: String?) {
        switch bundleID {
        case "com.tinycast.app": self = .stable
        case "com.tinycast.app.beta": self = .beta
        case "com.tinycast.app.plus": self = .fork
        default: self = .development
        }
    }

    var updatesItself: Bool { self != .development }

    /// Where this channel's releases are published; notes still link to upstream's pull requests.
    var releasesRepository: String {
        self == .fork ? "ChamuthuEdirisooriya/tinycast" : ReleaseFeed.repository
    }

    /// Beta ships as a GitHub prerelease and stable does not; neither ever sees the other's.
    func accepts(prerelease: Bool) -> Bool {
        switch self {
        case .stable, .fork: return !prerelease
        case .beta: return prerelease
        case .development: return false
        }
    }
}
