import Flutter
import UIKit
import GameKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let audio = AppleAudio()
  private var gameCenter: OrbitalGameCenter?
  private let saveFiles = OrbitalSaveFiles()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    gameCenter = OrbitalGameCenter(messenger: engineBridge.applicationRegistrar.messenger())
    FlutterMethodChannel(
      name: "atomic_orbital/platform",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "The game is closing.", details: nil))
        return
      }
      switch call.method {
      case "exportSave":
        let args = call.arguments as? [String: Any]
        self.saveFiles.open(contents: args?["contents"] as? String, exporting: true, result: result)
      case "importSave":
        self.saveFiles.open(contents: nil, exporting: false, result: result)
      case "loadSoundEffects", "playSoundEffect", "disposeSoundEffects",
           "playBackgroundMusic", "pauseBackgroundMusic":
        do {
          if call.method == "loadSoundEffects" {
            try self.audio.load()
          } else if call.method == "disposeSoundEffects" {
            self.audio.dispose()
          } else if call.method == "playBackgroundMusic" {
            try self.audio.playBackgroundMusic()
          } else if call.method == "pauseBackgroundMusic" {
            let arguments = call.arguments as? [String: Any]
            if let value = arguments?["rewind"], !(value is Bool) {
              result(FlutterError(
                code: "invalid_rewind", message: "The rewind flag must be a boolean.", details: nil))
              return
            }
            self.audio.pauseBackgroundMusic(rewind: arguments?["rewind"] as? Bool ?? true)
          } else {
            guard let arguments = call.arguments as? [String: Any],
                  let name = arguments["name"] as? String else {
              result(FlutterError(
                code: "invalid_sound", message: "A sound name is required.", details: nil))
              return
            }
            try self.audio.play(name)
          }
          result(nil)
        } catch {
          result(FlutterError(code: "audio_failed", message: error.localizedDescription, details: nil))
        }
      case "appInfo":
        result(["version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—",
                "build": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"])
      case "openUrl":
        let args = call.arguments as? [String: Any]
        guard let raw = args?["url"] as? String, let url = URL(string: raw),
              url.scheme == "https", url.host == "marvinmaerz.com",
              ["/atomic-orbital/privacy/", "/atomic-orbital/support/", "/atomic-orbital/delete-data/"].contains(url.path + (url.path.hasSuffix("/") ? "" : "/")),
              url.query == nil, url.fragment == nil, url.user == nil else {
          result(FlutterError(code: "invalid_url", message: "Unknown support link.", details: nil))
          return
        }
        UIApplication.shared.open(url) { opened in
          result(opened ? nil : FlutterError(code: "unavailable", message: "No browser is available.", details: nil))
        }
      case "rate":
        // A user-tapped review action needs the published App Store listing.
        result(FlutterError(
          code: "unavailable",
          message: "App Store reviews will be available after the iOS release.",
          details: nil))
      case "share":
        guard let arguments = call.arguments as? [String: Any],
              let score = arguments["score"] as? Int, score >= 0 else {
          result(FlutterError(
            code: "invalid_score", message: "A nonnegative score is required.", details: nil))
          return
        }
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              var controller = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
          result(FlutterError(
            code: "unavailable", message: "The game window is not ready to share.", details: nil))
          return
        }
        while let presented = controller.presentedViewController {
          controller = presented
        }
        let text = String(((arguments["message"] as? String) ?? "I got \(score) points in Atomic Orbital. Can you do better?").prefix(1000))
        let share = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = share.popoverPresentationController {
          popover.sourceView = controller.view
          popover.sourceRect = CGRect(
            x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
          popover.permittedArrowDirections = []
        }
        controller.present(share, animated: true)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

private final class OrbitalSaveFiles: NSObject, UIDocumentPickerDelegate {
  private var pending: FlutterResult?
  private var exporting = false
  private var temporary: URL?
  private let maximumBytes = 1024 * 1024

  func open(contents: String?, exporting: Bool, result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: "A save file is already open.", details: nil)); return
    }
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      var presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "unavailable", message: "The game window is unavailable.", details: nil)); return
    }
    while let presented = presenter.presentedViewController { presenter = presented }
    do {
      let picker: UIDocumentPickerViewController
      if exporting {
        guard let data = contents?.data(using: .utf8), data.count <= maximumBytes else {
          throw NSError(domain: "AtomicOrbitalSave", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid save file."])
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporary = directory
        let file = directory.appendingPathComponent("atomic-orbital-save.json")
        try data.write(to: file, options: .atomic)
        picker = UIDocumentPickerViewController(forExporting: [file], asCopy: true)
      } else {
        picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
      }
      self.exporting = exporting
      pending = result
      picker.delegate = self
      picker.allowsMultipleSelection = false
      presenter.present(picker, animated: true)
    } catch {
      cleanup()
      result(FlutterError(code: "save_file_failed", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pending
    pending = nil
    result?(exporting ? false : nil)
    cleanup()
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pending else { return }
    pending = nil
    if exporting { result(true); cleanup(); return }
    guard let url = urls.first else { result(nil); return }
    DispatchQueue.global(qos: .userInitiated).async {
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      do {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let data = try file.read(upToCount: self.maximumBytes + 1) ?? Data()
        guard data.count <= self.maximumBytes, let text = String(data: data, encoding: .utf8) else {
          throw NSError(domain: "AtomicOrbitalSave", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid or oversized save file."])
        }
        DispatchQueue.main.async { result(text) }
      } catch {
        DispatchQueue.main.async { result(FlutterError(code: "save_file_failed", message: error.localizedDescription, details: nil)) }
      }
    }
  }

  private func cleanup() {
    if let temporary { try? FileManager.default.removeItem(at: temporary) }
    temporary = nil
  }
}

private final class OrbitalGameCenter: NSObject, GKGameCenterControllerDelegate {
  private let channel: FlutterMethodChannel
  private let legacyAchievements = [
    "CgkItOGapf0GEAIQCg": "normal20", "CgkItOGapf0GEAIQDA": "normal35", "CgkItOGapf0GEAIQDg": "normal50",
    "CgkItOGapf0GEAIQCw": "hardcore20", "CgkItOGapf0GEAIQDQ": "hardcore35", "CgkItOGapf0GEAIQDw": "hardcore50",
    "CgkItOGapf0GEAIQEA": "points500", "CgkItOGapf0GEAIQEQ": "points1000", "CgkItOGapf0GEAIQEg": "points10000",
    "CgkItOGapf0GEAIQBw": "games50", "CgkItOGapf0GEAIQCA": "games150", "CgkItOGapf0GEAIQCQ": "games500",
    "CgkItOGapf0GEAIQFw": "firstContact", "CgkItOGapf0GEAIQFA": "findingOrbit", "CgkItOGapf0GEAIQFQ": "hardcoreCadet", "CgkItOGapf0GEAIQGQ": "steadyHands", "CgkItOGapf0GEAIQGA": "newHorizons", "CgkItOGapf0GEAIQFg": "worldTour"
  ]
  private let boards = ["CgkItOGapf0GEAIQAQ": "ao.normal", "CgkItOGapf0GEAIQAg": "ao.hardcore", "CgkItOGapf0GEAIQAw": "ao.games", "CgkItOGapf0GEAIQGg": "ao.normal", "CgkItOGapf0GEAIQGw": "ao.hardcore"]

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "atomic_orbital/play_games", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterError(code: "unavailable", message: "Game Center is closing.", details: nil)); return }
      self.handle(call, result: result)
    }
  }

  private var presenter: UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      var controller = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
    while let presented = controller.presentedViewController { controller = presented }
    return controller
  }

  private func status() -> [String: Any] {
    let player = GKLocalPlayer.local
    return player.isAuthenticated ? ["authenticated": true, "playerId": player.gamePlayerID, "displayName": player.displayName] : ["authenticated": false]
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "status" { result(status()); return }
    if call.method == "signIn" {
      var completed = false
      GKLocalPlayer.local.authenticateHandler = { [weak self] controller, _ in
        DispatchQueue.main.async {
          guard let self else { return }
          if let controller {
            guard let presenter = self.presenter else {
              if !completed { completed = true; result(FlutterError(code: "unavailable", message: "Game window is unavailable.", details: nil)) }
              return
            }
            presenter.present(controller, animated: true)
          } else if !completed {
            completed = true
            result(self.status())
          }
        }
      }
      return
    }
    guard GKLocalPlayer.local.isAuthenticated else {
      result(FlutterError(code: "sign_in_required", message: "Sign in to Game Center to continue.", details: nil)); return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    if let owner = args["playerId"] as? String, owner != GKLocalPlayer.local.gamePlayerID {
      result(FlutterError(code: "profile_changed", message: "Switch back to the original game profile to sync.", details: nil)); return
    }
    switch call.method {
    case "loadAchievements":
      GKAchievement.loadAchievements { achievements, error in
        DispatchQueue.main.async {
          if let error { result(FlutterError(code: "game_center_failed", message: error.localizedDescription, details: nil)) }
          else { result((achievements ?? []).filter { $0.isCompleted && $0.identifier.hasPrefix("ao.") }.map { String($0.identifier.dropFirst(3)) }) }
        }
      }
    case "showAchievements", "showLeaderboards":
      guard let presenter else { result(FlutterError(code: "unavailable", message: "Game window is unavailable.", details: nil)); return }
      let controller: GKGameCenterViewController
      if call.method == "showLeaderboards" {
        guard let id = args["leaderboardId"] as? String, let board = boards[id] else {
          result(FlutterError(code: "invalid_leaderboard", message: "Unknown leaderboard.", details: nil)); return
        }
        controller = GKGameCenterViewController(leaderboardID: board, playerScope: .global, timeScope: .allTime)
      } else { controller = GKGameCenterViewController(state: .achievements) }
      controller.gameCenterDelegate = self
      presenter.present(controller, animated: true)
      result(nil)
    case "submitScore":
      guard let id = args["leaderboardId"] as? String, let board = boards[id],
            let score = args["score"] as? NSNumber, CFGetTypeID(score) != CFBooleanGetTypeID(), !["f", "d"].contains(String(cString: score.objCType)), score.int64Value > 0 else {
        result(FlutterError(code: "invalid_score", message: "A positive score and known leaderboard are required.", details: nil)); return
      }
      GKLeaderboard.submitScore(score.intValue, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [board]) { error in
        DispatchQueue.main.async { result(error.map { FlutterError(code: "game_center_failed", message: $0.localizedDescription, details: nil) }) }
      }
    case "unlockAchievement":
      guard let raw = args["achievementId"] as? String else { result(FlutterError(code: "invalid_achievement", message: "Unknown achievement.", details: nil)); return }
      let local = legacyAchievements[raw] ?? (raw.hasPrefix("ao.") ? String(raw.dropFirst(3)) : "")
      guard legacyAchievements.values.contains(local) else {
        result(FlutterError(code: "invalid_achievement", message: "Unknown achievement.", details: nil)); return
      }
      let achievement = GKAchievement(identifier: "ao." + local)
      achievement.percentComplete = 100
      achievement.showsCompletionBanner = false
      GKAchievement.report([achievement]) { error in
        DispatchQueue.main.async { result(error.map { FlutterError(code: "game_center_failed", message: $0.localizedDescription, details: nil) }) }
      }
    default: result(FlutterMethodNotImplemented)
    }
  }

  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true)
  }
}
