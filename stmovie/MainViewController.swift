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

class MainViewController: UIViewController {
    
    let selectButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Choose video", for: .normal)
        return button
    }()
    
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
                let vc = SimpleVideoViewController()
                vc.videoURL = video.url
                picker.dismiss(animated: true, completion: nil)
                self.present(vc, animated: true, completion: nil)
            } else {
                picker.dismiss(animated: true, completion: nil)
            }
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

