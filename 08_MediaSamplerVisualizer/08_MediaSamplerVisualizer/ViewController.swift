//
//  ViewController.swift
//  08_MediaSamplerVisualizer
//
//  Created by sy on 2020/3/24.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var waveformView: MSAudioWaveformView!
    @IBOutlet weak var waveStyleSegment: UISegmentedControl!
    
    lazy var mediaLoadingQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "mediaLoadingQueue"
        q.qualityOfService = .userInitiated
        q.maxConcurrentOperationCount = 4
        return q
    }()
    
    var audioLoadCanceller: Cancelable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.waveStyleSegment.setTitle("Aerage", forSegmentAt: 0)
        self.waveStyleSegment.setTitle("Max", forSegmentAt: 1)
        self.waveStyleSegment.setTitle("Min", forSegmentAt: 2)
        self.waveformView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        self.waveformView.cornerRadius = 16
        self.waveformView.waveScale = 0.25
        
        if let url = Bundle.main.url(forResource: "Albert Vishi & Skylar Grey - Love The Way You Lie (Remix)", withExtension: "mp3") {
            let audio = AVAsset(url: url)
            print("start load track.")
            audio.loadValuesAsynchronously(forKeys: [#keyPath(AVAsset.tracks)]) { [weak self] in
                let trackstatus = audio.statusOfValue(forKey: #keyPath(AVAsset.tracks), error: nil)
                
                if trackstatus != .loaded {
                    print("load track filed!")
                    return
                }
                
                print("load track success.")
                if let strongSelf = self {
                    print("load track samples.")
                    DispatchQueue.main.async {
                        strongSelf.audioLoadCanceller = strongSelf.waveformView.load(audio,
                                                     queue: strongSelf.mediaLoadingQueue) { [weak self] (status, error) in
                                                        guard let _ = self else {
                                                            return
                                                        }
                                                        
                                                        if status == .completed {
                                                            print("load track samples succes.")
                                                        } else {
                                                            print("load  track samples status: \(status), error: \(error)")
                                                        }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        if let canceller = self.audioLoadCanceller {
            canceller.cancel()
        }
    }
    
    @IBAction func styleSegmentChange(_ sender: UISegmentedControl) {
        self.waveformView.wavestyle = MSAudioWaveformView.WaveStyle(rawValue: sender.selectedSegmentIndex)!
    }
}

