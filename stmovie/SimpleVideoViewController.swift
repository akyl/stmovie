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
    
    let activityMonitor: UIActivityIndicatorView = {
        let am = UIActivityIndicatorView()
        am.translatesAutoresizingMaskIntoConstraints = false
        return am
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(lottiesCollectionView)
        view.addSubview(exportButton)
        view.addSubview(activityMonitor)

        exportButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        exportButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        exportButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        exportButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        
        lottiesCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        lottiesCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        lottiesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16.0).isActive = true
        lottiesCollectionView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        activityMonitor.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityMonitor.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        exportButton.addTarget(self, action: #selector(handleExport), for: .touchUpInside)
        
        lottiesCollectionView.delegate = self
        lottiesCollectionView.dataSource = self
        lottiesCollectionView.register(LottieViewCell.self, forCellWithReuseIdentifier: "cellId")
        
        playVideo(videoURL: videoURL!)
    }
    
    @objc func handleExport() {
        
        self.activityMonitor.startAnimating()
        
        guard let videoAsset = player.currentItem?.asset else { return }
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        
        guard let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        
        exporter.exportAsynchronously() {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
    }
    
    func savedPhotosAvailable() -> Bool {
        guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return true }
        
        let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        return false
    }
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        
        guard session.status == AVAssetExportSession.Status.completed,
            let outputURL = session.outputURL else { return }
        
        let saveVideoToPhotos = {
            
            self.activityMonitor.stopAnimating()
            
            PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL) }) { saved, error in
                let success = saved && (error == nil)
                let title = success ? "Success" : "Error"
                let message = success ? "Video saved" : "Failed to save video"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: {
                    (alert: UIAlertAction!) in
                     self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    saveVideoToPhotos()
                }
            })
        } else {
            saveVideoToPhotos()
        }
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
       
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.loopMode = .loop
        animationView.frame = CGRect(x:0, y: playerLayer.frame.maxY-216, width: view.frame.width / 10, height: 100)
        let animationLayer = animationView.layer
        
        animationLayer.frame = CGRect(x:0, y: playerLayer.frame.maxY-216, width: view.frame.width / 10, height: 100)
        
        playerLayer.addSublayer(animationLayer)
        
        view.layer.addSublayer(playerLayer)
        
        view.addSubview(animationView)
        
        player.play()
        
        animationView.play()
    }
    
    func addLottieAnimation(_ animationName: String) {
        animationView.animation = Animation.named(animationName, subdirectory: "LottieAnimations")
        animationView.play()
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

