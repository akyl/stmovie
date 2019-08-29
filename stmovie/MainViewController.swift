//
//  ViewController.swift
//  stmovie
//
//  Created by Prog on 8/20/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import UIKit
import YPImagePicker
import AVFoundation
import Lottie
import AVKit

class MainViewController: UIViewController {
    
    let selectButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Select and Play video", for: .normal)
        return button
    }()
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    private let foregroundView =  UIView()
    private let maskLayer = CALayer()
    private let foregroundLayer = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        view.addSubview(selectButton)
        
        selectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        selectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    @objc
    func selectButtonTapped () {
        var config = YPImagePickerConfiguration()
        config.screens = [.library, .video]
        config.video.compression = AVAssetExportPresetHighestQuality
        config.library.mediaType = .video
        
        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking{[unowned picker] items, _ in
            if let video = items.singleVideo {
                self.playVideo(videoURL: video.url)
            }
            
            picker.dismiss(animated: true, completion: nil)
        }
        
        present(picker, animated: true, completion: nil)
    }
    
 
    fileprivate func playVideo(videoURL: URL){
        player = AVPlayer(url: videoURL)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        
        self.view.layer.addSublayer(playerLayer)
        
        player.play()
        
        setupViews()
        setupLayers()
        setupAnimations()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func setupViews() {
        foregroundView.frame = view.bounds
        foregroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(foregroundView)
    }
    
    func setupLayers() {
        guard let playerItem = player.currentItem else { return }
        
        let synchronizedLyaer = AVSynchronizedLayer(playerItem: playerItem)
        synchronizedLyaer.frame = view.bounds
        foregroundView.layer.addSublayer(synchronizedLyaer)
        
        foregroundLayer.frame = view.bounds
        foregroundLayer.backgroundColor = UIColor.black.cgColor
        
        synchronizedLyaer.addSublayer(foregroundLayer)
        
        maskLayer.frame = view.bounds
        maskLayer.contentsGravity = .resizeAspect
        maskLayer.contents = UIImage(named: "star")
        
        foregroundLayer.mask = maskLayer
    }
    
    func setupAnimations() {
        guard let playerItem = player.currentItem else { return }
        
        let duration = playerItem.asset.duration.seconds
        let beginTime = AVCoreAnimationBeginTimeAtZero
        let isRemovedOnCompletion = false
        
        let backgroundColorAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.backgroundColor))
        backgroundColorAnimation.duration = duration
        backgroundColorAnimation.isRemovedOnCompletion = isRemovedOnCompletion
        backgroundColorAnimation.beginTime = beginTime
        backgroundColorAnimation.fromValue = foregroundLayer.backgroundColor
        backgroundColorAnimation.toValue = UIColor.clear.cgColor
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = duration
        scaleAnimation.isRemovedOnCompletion = isRemovedOnCompletion
        scaleAnimation.beginTime = beginTime
        scaleAnimation.fromValue = 3
        scaleAnimation.toValue = 0
        
        maskLayer.add(scaleAnimation, forKey: nil)
        foregroundLayer.add(backgroundColorAnimation, forKey: nil)
    }

}

