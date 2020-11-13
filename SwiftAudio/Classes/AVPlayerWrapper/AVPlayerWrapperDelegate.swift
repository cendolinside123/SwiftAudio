//
//  AVPlayerWrapperDelegate.swift
//  SwiftAudio
//
//  Created by Jørgen Henrichsen on 26/10/2018.
//

import Foundation

public enum PlaybackEndedReason: String {
    case playedUntilEnd
    case playerStopped
    case skippedToNext
    case skippedToPrevious
    case jumpedToIndex
}

protocol AVPlayerWrapperDelegate: class {
    
    func AVWrapper(didChangeState state: AVPlayerWrapperState)
    func AVWrapper(secondsElapsed seconds: Double)
    func AVWrapper(failedWithError error: Error?)
    func AVWrapper(seekTo seconds: Int, didFinish: Bool)
    func AVWrapper(didUpdateDuration duration: Double)
    func AVWrapperItemDidPlayToEndTime()
    func AVWrapperDidRecreateAVPlayer()
    
}

protocol AVPlayerWrapperBufferingDelegate: class {
    func AVWrappperBuffering(buffer:Double)
}
