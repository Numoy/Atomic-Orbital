import AVFAudio
import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testAppleAudioPreparesAssetsValidatesRequestsAndDisposes() throws {
    let audio = AppleAudio()
    defer { audio.dispose() }
    XCTAssertThrowsError(try audio.play("unknown")) { error in
      XCTAssertEqual(error.localizedDescription, "Unknown sound: unknown")
    }
    XCTAssertThrowsError(try audio.play("hit")) { error in
      XCTAssertEqual(error.localizedDescription, "Sound effects are not loaded")
    }
    XCTAssertThrowsError(try audio.playBackgroundMusic()) { error in
      XCTAssertEqual(error.localizedDescription, "Background music is not loaded")
    }
    try audio.load()
    try audio.load()
    XCTAssertEqual(AVAudioSession.sharedInstance().category, .ambient)
    audio.pauseBackgroundMusic(rewind: false)
    audio.pauseBackgroundMusic()
    audio.dispose()
    audio.dispose()
    XCTAssertThrowsError(try audio.play("collect")) { error in
      XCTAssertEqual(error.localizedDescription, "Sound effects are not loaded")
    }
    XCTAssertThrowsError(try audio.playBackgroundMusic()) { error in
      XCTAssertEqual(error.localizedDescription, "Background music is not loaded")
    }
  }

  func testAppleAudioPlaysOverlappingEffectsAndMusicWithoutSessionConflict() throws {
    let audio = AppleAudio()
    defer { audio.dispose() }
    try audio.load()
    try audio.playBackgroundMusic()
    for name in ["hit", "collect", "shoot"] { try audio.play(name) }
    audio.pauseBackgroundMusic(rewind: false)
    for _ in 0..<11 { try audio.play("shoot") }
    try audio.playBackgroundMusic()
    audio.pauseBackgroundMusic()
    try audio.play("hit")
    XCTAssertThrowsError(try audio.play("unknown")) { error in
      XCTAssertEqual(error.localizedDescription, "Unknown sound: unknown")
    }
  }
}
