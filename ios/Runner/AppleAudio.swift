import AVFAudio
import Flutter

/// Owns the shared iOS session, looping music and prepared PCM game cues.
final class AppleAudio: NSObject, AVAudioPlayerDelegate {
  private final class Voice {
    let player: AVAudioPlayer
    var order: UInt64 = 0
    init(_ player: AVAudioPlayer) { self.player = player }
  }

  private let names = ["hit", "collect", "shoot"]
  private let maximumStreams = 10
  private var voices: [String: [Voice]] = [:]
  private var order: UInt64 = 0
  private var music: AVAudioPlayer?

  func load() throws {
    if !voices.isEmpty && music != nil { return }
    try AVAudioSession.sharedInstance().setCategory(.ambient)
    var prepared: [String: [Voice]] = [:]
    for name in names {
      let url = try asset("\(name).wav")
      prepared[name] = try (0..<maximumStreams).map { _ in
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        guard player.prepareToPlay() else {
          throw failure("Cannot prepare sound: \(name)")
        }
        return Voice(player)
      }
    }
    let track = try AVAudioPlayer(contentsOf: asset("bg_music.m4a"))
    track.numberOfLoops = -1
    guard track.prepareToPlay() else { throw failure("Cannot prepare background music") }
    voices = prepared
    music = track
  }

  func play(_ name: String) throws {
    guard names.contains(name) else { throw failure("Unknown sound: \(name)") }
    guard let choices = voices[name] else { throw failure("Sound effects are not loaded") }
    let playing = voices.values.flatMap { $0 }.filter { $0.player.isPlaying }
    if playing.count >= maximumStreams {
      playing.min(by: { $0.order < $1.order })?.player.pause()
    }
    guard let voice = choices.first(where: { !$0.player.isPlaying }) else {
      throw failure("No free sound voice")
    }
    voice.player.currentTime = 0
    order &+= 1
    voice.order = order
    try AVAudioSession.sharedInstance().setActive(true)
    guard voice.player.play() else { throw failure("Cannot play sound: \(name)") }
  }

  func playBackgroundMusic() throws {
    guard let music else { throw failure("Background music is not loaded") }
    try AVAudioSession.sharedInstance().setActive(true)
    guard music.play() else { throw failure("Cannot play background music") }
  }

  func pauseBackgroundMusic(rewind: Bool = true) {
    music?.pause()
    if rewind { music?.currentTime = 0 }
    // Keep the session active: the final hit cue can still be playing.
  }

  func dispose() {
    for voice in voices.values.flatMap({ $0 }) { voice.player.stop() }
    voices.removeAll()
    music?.stop()
    music = nil
    order = 0
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      NSLog("Atomic Orbital could not deactivate its audio session: %@", error.localizedDescription)
    }
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    guard voices.values.contains(where: { $0.contains(where: { $0.player === player }) }) else {
      return
    }
    // Finishing a cue releases AVAudioPlayer's prepared playback resources.
    player.currentTime = 0
    if !player.prepareToPlay() { NSLog("Atomic Orbital could not prepare a finished sound voice") }
  }

  private func asset(_ file: String) throws -> URL {
    let key = FlutterDartProject.lookupKey(forAsset: "assets/audio/ios/\(file)")
    guard let url = Bundle.main.url(forResource: key, withExtension: nil) else {
      throw failure("Missing bundled sound: \(file)")
    }
    return url
  }

  private func failure(_ message: String) -> NSError {
    NSError(domain: "AtomicOrbitalAudio", code: 1,
            userInfo: [NSLocalizedDescriptionKey: message])
  }
}
