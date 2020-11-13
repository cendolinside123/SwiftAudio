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
    
    private var _pendingAsset: AVAsset? = nil
    
    fileprivate var _state: AVPlayerWrapperState = AVPlayerWrapperState.idle {
        didSet {
            if oldValue != _state {
                self.delegate?.AVWrapper(didChangeState: _state)
            }
        }
    }
    private var timeObserver: Any?
    
    override init() {
        player = AVPlayer()
        
        print("Implementasi setup player baru")
        
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
    
    func load(from url: URL, playWhenReady: Bool, options: [String : Any]? = nil) {
        
        reset(soft: true)
        
        _playWhenReady = playWhenReady

        if currentItem?.status == .failed {
            //recreateAVPlayer()
            print("player retry to load")
            self.load(from: url, playWhenReady: playWhenReady, options: options)
        }
        
        self._pendingAsset = AVURLAsset(url: url, options: options)
        self._state = .loading
        
        if let getURL = self._pendingAsset {
            let url = AVPlayerItem(asset: getURL)
            
            if let oldItem = currentItem {
                removeNotification(item: oldItem)
            }
            
            self.player = AVPlayer(playerItem: url)
            
            registerObserver(item: url)
            
        } else {
            print("player asset is empty")
        }
        
        
    }
    
    func load(from url: URL, playWhenReady: Bool, initialTime: TimeInterval? = nil, options: [String : Any]?) {
        _initialTime = initialTime
        self.pause()
        self.load(from: url, playWhenReady: playWhenReady, options: options)
    }
    
    private func reset(soft: Bool) {
        self._pendingAsset?.cancelLoading()
        self._pendingAsset = nil
        
        if !soft {
            player?.replaceCurrentItem(with: nil)
        }
    }
    
    private func registerObserver(item: AVPlayerItem?) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.itemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: item)
        item?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        item?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        item?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        item?.addObserver(self, forKeyPath: "duration", options: .new, context: nil)
        item?.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.new], context: nil)
        item?.addObserver(self, forKeyPath: "timeControlStatus", options: .new, context: nil)
    }
    
    private func removeNotification(item: AVPlayerItem) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        item.removeObserver(self, forKeyPath: "duration")
        item.removeObserver(self, forKeyPath: "loadedTimeRanges")
        item.removeObserver(self, forKeyPath: "timeControlStatus")
        timeObserver = nil
    }
    
    private func setTimeObserver(interval: CMTime) {
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            self?.delegate?.AVWrapper(secondsElapsed: time.seconds)
        })
    }
    
}

extension AVPlayerWrapper_New {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let key = keyPath , let item = object as?AVPlayerItem {
            switch key {
            case "status":
                let status: AVPlayer.Status
                if let statusNumber = change?[.newKey] as? NSNumber {
                    status = AVPlayer.Status(rawValue: statusNumber.intValue)!
                }
                else {
                    status = .unknown
                }
                
                switch status {
                case .readyToPlay:
                    self._state = .ready
                    if _playWhenReady && (_initialTime ?? 0) == 0 {
                        self.play()
                    }
                    else if let initialTime = _initialTime {
                        self.seek(to: initialTime)
                    }
                    break
                    
                case .failed:
                    print("player error: \(player?.error)")
                    
                    self.delegate?.AVWrapper(failedWithError: player?.error)
                    break
                    
                case .unknown:
                    break
                @unknown default:
                    break
                }
                
            case "playbackBufferEmpty":
                break
            case "playbackLikelyToKeepUp":
                if item.isPlaybackLikelyToKeepUp == true {
                    _state = .playing
                } else {
                    _state = .loading
                }
            case "duration":
                let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                let duration = Double(item.duration.seconds)
                
                self.delegate?.AVWrapper(didUpdateDuration: duration)
                self.setTimeObserver(interval: interval)
                
            case "loadedTimeRanges":
                if let bufferPosition = currentItem?.loadedTimeRanges.last?.timeRangeValue.end.seconds {
                    self.dataBufferDelegate?.AVWrappperBuffering(buffer: bufferPosition)
                }
            case "timeControlStatus":
                let status: AVPlayer.TimeControlStatus
                
                if let statusNumber = change?[.newKey] as? NSNumber {
                    status = AVPlayer.TimeControlStatus(rawValue: statusNumber.intValue)!
                    switch status {
                    case .paused:
                        if currentItem == nil {
                            _state = .idle
                        }
                        else {
                            self._state = .paused
                        }
                    case .waitingToPlayAtSpecifiedRate:
                        self._state = .buffering
                    case .playing:
                        self._state = .playing
                    @unknown default:
                        break
                    }
                }
                
            default:
                break
            }
        }
    }
}

extension AVPlayerWrapper_New: AVPlayerItemNotificationObserverDelegate {
    @objc func itemDidPlayToEndTime() {
        pause()
        player?.seek(to: .zero, completionHandler: { [weak self]_ in
            self?.delegate?.AVWrapperItemDidPlayToEndTime()
        })
    }
    
    
}



