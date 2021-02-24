//
//  AudioController.swift
//  SwiftAudio_Example
//
//  Created by Jørgen Henrichsen on 25/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import SwiftAudio


class AudioController {
    
    static let shared = AudioController()
    let player: AudioPlayer
    let audioSessionController = AudioSessionController.shared
    
    let sources: [AudioItem] = [
        DefaultAudioItem(audioUrl: "https://www.eclassical.com/custom/eclassical/files/BIS1447-002-flac_24.flac", artist: "Unknow Artist", title: "Unknow Title", albumTitle: "Unknow Album Title", sourceType: .stream, artwork: #imageLiteral(resourceName: "22AMI"))
    ]
    
    init() {
        let controller = RemoteCommandController()
        player = AudioPlayer()
        player.remoteCommands = [
            .stop,
            .play,
            .pause,
            .togglePlayPause,
            .next,
            .previous,
            .changePlaybackPosition
        ]
        
        do {
            try audioSessionController.set(category: .playback)
        } catch let error {
            print("session error: \(error)")
        }
        
//        try? audioSessionController.set(category: .playback)
        //try? player.add(items: sources, playWhenReady: false)
    }
    
}
