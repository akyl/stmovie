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

class SimpleVideoViewController: UIViewController {
 
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: URL?
    
    let animationNames = ["9squared-AIBoardman", "base64Test", "Boat_Loader", "FirstText", "GeometryTransformTest", "HamburgerArrow", "IconTransitions", "keypathTest", "LottieLogo1_masked", "LottieLogo1", "LottieLogo2", "PinJump"]
    
    /*
    let lottiesView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        return v
    }()
    */
    
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
        lottiesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        lottiesCollectionView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        exportButton.addTarget(self, action: #selector(handleExport), for: .touchUpInside)
        
        lottiesCollectionView.delegate = self
        lottiesCollectionView.dataSource = self
        lottiesCollectionView.register(LottieViewCell.self, forCellWithReuseIdentifier: "cellId")
        
        playVideo(videoURL: videoURL!)
    }
    
    @objc func handleExport() {
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
        //let image = UIImage(named: "star")?.cgImage
        
        //syncLayer.contents = image
        
        playerLayer.addSublayer(syncLayer)
        
        view.layer.addSublayer(playerLayer)
       
        
        player.play()
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
}
