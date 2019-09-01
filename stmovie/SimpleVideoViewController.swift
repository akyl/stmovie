//
//  LottieExampleViewController.swift
//  stmovie
//
//  Created by Prog on 8/29/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import UIKit
import AVFoundation
import Lottie
import AVKit
import Photos

class SimpleVideoViewController: UIViewController {
 
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: URL?
    let animationView = AnimationView()
    
    let animationNames = ["9squares-AIBoardman", "base64Test", "Boat_Loader", "FirstText", "GeometryTransformTest", "HamburgerArrow", "IconTransitions", "keypathTest", "LottieLogo1_masked", "LottieLogo1", "LottieLogo2", "PinJump", "setValueTest", "Switch_States", "Switch", "timeremap", "TwitterHeart", "TwitterHeartButton", "vcTransition1", "vcTransition2", "Watermelon"]
    
    let exportButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Export", for: .normal)
        return button
    }()
    
    let lottiesCollectionView: UICollectionView = {
        let cv =  UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        cv.setCollectionViewLayout(layout, animated: true)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(lottiesCollectionView)
        view.addSubview(exportButton)

        exportButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        exportButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        exportButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        exportButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        
        lottiesCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        lottiesCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        lottiesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16.0).isActive = true
        lottiesCollectionView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        exportButton.addTarget(self, action: #selector(handleExport), for: .touchUpInside)
        
        lottiesCollectionView.delegate = self
        lottiesCollectionView.dataSource = self
        lottiesCollectionView.register(LottieViewCell.self, forCellWithReuseIdentifier: "cellId")
        
        playVideo(videoURL: videoURL!)
    }
    
    @objc func handleExport() {
        guard let videoAsset = player.currentItem?.asset else { return }
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = AVFileType.mp4
        let exportPath = NSTemporaryDirectory().appendingFormat("/video.mov")
        let exportUrl = URL.init(fileURLWithPath: exportPath)
        exportSession?.outputURL = exportUrl
        exportSession?.metadata = videoAsset.metadata
        exportSession?.exportAsynchronously {
            if exportSession?.status == .completed {
                guard let outputUrl = exportSession?.outputURL else { return }
                
                PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputUrl) }) { saved, error in
                        let success = saved && (error == nil)
                        let title = success ? "Success" : "Error"
                        let message = success ? "Video saved" : "Failed to save video"
                        
                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    
                }
            } else if exportSession?.status == .cancelled {
                let alert = UIAlertController(title: "Attention", message: "Cancelled", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Error", message: "Unknown error while exporting", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func playVideo(videoURL: URL){
        player = AVPlayer(url: videoURL)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        
       
        let syncLayer = AVSynchronizedLayer(playerItem: player.currentItem!)
        syncLayer.frame = CGRect(x: 15,y: 15,width: 100,height: 100)
        
        let animation = Animation.named("LottieLogo1", subdirectory: "LottieAnimations")
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFill
        animationView.backgroundBehavior = .pauseAndRestore
        
        let image = UIImage(named: "star")?.cgImage
        syncLayer.contents = image
    
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        animationView.play(fromProgress: 0,
                           toProgress: 1,
                           loopMode: LottieLoopMode.loop,
                           completion: { (finished) in
                            if finished {
                                print("Animation Complete")
                            } else {
                                print("Animation cancelled")
                            }
        })
    }
    
    func addLottieAnimation(_ animationName: String) {
        
        
        
    }
}

extension SimpleVideoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return animationNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! LottieViewCell
        //cell.backgroundColor = .red
        cell.frame = CGRect(x: cell.frame.origin.x, y: cell.frame.origin.y, width: cell.frame.size.width, height: 100)
        let name = animationNames[indexPath.row]
        cell.addAnimation(name)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let animName = animationNames[indexPath.row]
        addLottieAnimation(animName)
    }
}
