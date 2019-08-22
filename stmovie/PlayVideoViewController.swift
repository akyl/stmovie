//
//  PlayViewController.swift
//  stmovie
//
//  Created by Prog on 8/23/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

class PlayVideoViewController: UIViewController {

    let playButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Play video", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        view.addSubview(playButton)
        
        playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        playButton.addTarget(self, action: #selector(handledPlay), for: .touchUpInside)
    }
    
    @objc
    func handledPlay() {
        VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
}

extension PlayVideoViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == (kUTTypeVideo as String), let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            return
        }
        
        dismiss(animated: true) {
            let player = AVPlayer(url: url)
            let vcPlayer = AVPlayerViewController()
            vcPlayer.player = player
            self.present(vcPlayer, animated: true, completion: nil)
        }
    }
}

extension PlayVideoViewController: UINavigationControllerDelegate {
}
