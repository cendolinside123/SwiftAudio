//
//  AVPlayerWrapper_New.swift
//  Nimble
//
//  Created by Mac on 12/11/20.
//

import Foundation
import AVFoundation


class AVPlayerWrapper_New:NSObject,AVPlayerWrapperProtocol {
    var state: AVPlayerWrapperState {
        return _state
    }
    
    var currentItem: AVPlayerItem?{
        return player?.currentItem
    }
    
    var currentTime: TimeInterval {
        guard let seconds = player?.currentTime().seconds else {
            return 0
        }
        if seconds.isNaN {
            return 0
        } else {
            return seconds
        }
    }
    
    var duration: TimeInterval{
        if let seconds = currentItem?.asset.duration.seconds, !seconds.isNaN {
            return seconds
        }
        else if let seconds = currentItem?.duration.seconds, !seconds.isNaN {
            return seconds
        }
        else if let seconds = currentItem?.loadedTimeRanges.first?.timeRangeValue.duration.seconds,
            !seconds.isNaN {
            return seconds
        }
        return 0.0
    }
    
    var bufferedPosition: TimeInterval{
        return currentItem?.loadedTimeRanges.last?.timeRangeValue.end.seconds ?? 0
    }
    
    var reasonForWaitingToPlay: AVPlayer.WaitingReason? {
        return player?.reasonForWaitingToPlay
    }
    
    var rate: Float{
        get { return player?.rate ?? 1 }
        set { player?.rate = newValue }
    }
    
    var delegate: AVPlayerWrapperDelegate?
    
    var dataBufferDelegate: AVPlayerWrapperBufferingDelegate?
    
    var bufferDuration: TimeInterval = 0
    
    var timeEventFrequency: TimeEventFrequency = .everySecond {
        didSet {
            //playerTimeObserver.periodicObserverTimeInterval = timeEventFrequency.getTime()
        }
    }
    
    var volume: Float{
        get { return player?.volume ?? 0 }
        set { player?.volume = newValue }
    }
    
    var isMuted: Bool {
        get { return player?.isMuted ?? false}
        set { player?.isMuted = newValue }
    }
    
    var automaticallyWaitsToMinimizeStalling: Bool {
        get { return player?.automaticallyWaitsToMinimizeStalling ?? false }
        set { player?.automaticallyWaitsToMinimizeStalling = newValue }
    }
    
    var player: AVPlayer?
    
    fileprivate var _playWhenReady: Bool = true
    fileprivate var _initialTime: TimeInterval?
    
    fileprivate var _state: AVPlayerWrapperState = AVPlayerWrapperState.idle {
        didSet {
            if oldValue != _state {
                self.delegate?.AVWrapper(didChangeState: _state)
            }
        }
    }
    
    override init() {
        player = AVPlayer()
        
        super.init()
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func togglePlaying() {
        switch player?.timeControlStatus {
        case .playing, .waitingToPlayAtSpecifiedRate:
            pause()
        case .paused:
            play()
        case .none:
            print("SwiftAudio Unknown AVPlayer.timeControlStatus")
            break
        @unknown default:
            print("SwiftAudio Unknown AVPlayer.timeControlStatus")
            break
            //fatalError("Unknown AVPlayer.timeControlStatus")
        }
    }
    
    func stop() {
        pause()
        player?.seek(to: .zero)
    }
    
    func seek(to seconds: TimeInterval) {
        let seekTime = CMTime(seconds: seconds, preferredTimescale: 1)
        
        player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .positiveInfinity, completionHandler: { [weak self] result in
            
            if let _ = self?._initialTime {
                self?._initialTime = nil
                if let isPlayWhenReady = self?._playWhenReady, isPlayWhenReady == true{
                    self?.play()
                }
            }
            self?.delegate?.AVWrapper(seekTo: Int(seconds), didFinish: result)
            
        })
        
    }
    
    func load(from url: URL, playWhenReady: Bool, options: [String : Any]?) {
        
    }
    
    func load(from url: URL, playWhenReady: Bool, initialTime: TimeInterval?, options: [String : Any]?) {
        
    }
    
}

extension AVPlayerWrapper_New {
    
}



