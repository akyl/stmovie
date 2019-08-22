//
//  MergeVideoViewController.swift
//  stmovie
//
//  Created by Prog on 8/23/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import Photos

class MergeVideoViewController: UIViewController {
    
    var firstAsset: AVAsset?
    var secondAsset: AVAsset?
    var audioAsset: AVAsset?
    var loadingAssetOne = false

    let loadAsset1Button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Load Asset 1", for: .normal)
        return button
    }()
    
    let loadAsset2Button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Load Asset 2", for: .normal)
        return button
    }()
    
    let loadAudioButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Load Audio", for: .normal)
        return button
    }()
    
    let mergeAndSaveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Merge and Save", for: .normal)
        return button
    }()
    
    let activityMonitor: UIActivityIndicatorView = {
        let am = UIActivityIndicatorView()
        am.translatesAutoresizingMaskIntoConstraints = false
        return am
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        view.addSubview(loadAudioButton)
        view.addSubview(loadAsset2Button)
        view.addSubview(loadAsset1Button)
        view.addSubview(mergeAndSaveButton)
        
        view.addSubview(activityMonitor)
        
        loadAudioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadAudioButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        loadAsset2Button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadAsset2Button.bottomAnchor.constraint(equalTo: loadAudioButton.topAnchor, constant: -20).isActive = true
        
        loadAsset1Button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadAsset1Button.bottomAnchor.constraint(equalTo: loadAsset2Button.topAnchor, constant: -20).isActive = true
        
        activityMonitor.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityMonitor.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        mergeAndSaveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mergeAndSaveButton.topAnchor.constraint(equalTo: loadAudioButton.bottomAnchor, constant: 20).isActive = true
        
        loadAsset1Button.addTarget(self, action: #selector(handleLoadAssetOne), for: .touchUpInside)
        loadAsset2Button.addTarget(self, action: #selector(handleLoadAssetTwo), for: .touchUpInside)

        loadAudioButton.addTarget(self, action: #selector(handleLoadAudio), for: .touchUpInside)

        mergeAndSaveButton.addTarget(self, action: #selector(handleMerge), for: .touchUpInside)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    func savedPhotosAvailable() -> Bool {
        guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return true }
        
        let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        return false
    }
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        
        // Cleanup assets
        activityMonitor.stopAnimating()
        firstAsset = nil
        secondAsset = nil
        audioAsset = nil
        
        guard session.status == AVAssetExportSession.Status.completed,
            let outputURL = session.outputURL else { return }
        
        let saveVideoToPhotos = {
            PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL) }) { saved, error in
                let success = saved && (error == nil)
                let title = success ? "Success" : "Error"
                let message = success ? "Video saved" : "Failed to save video"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        // Ensure permission to access Photo Library
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
    
    
    @objc
    func handleLoadAssetOne() {
        if savedPhotosAvailable() {
            loadingAssetOne = true
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @objc
    func handleLoadAssetTwo() {
        if savedPhotosAvailable(){
            loadingAssetOne = false
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @objc
    func handleLoadAudio() {
        let mediaPickerController = MPMediaPickerController(mediaTypes: .any)
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "Select Audio"
        present(mediaPickerController, animated: true, completion: nil)
    }
    
    @objc
    func handleMerge() {
        guard let firstAsset = firstAsset, let secondAsset = secondAsset else {
            return
        }
        
        activityMonitor.startAnimating()
        let mixComposition = AVMutableComposition()
        
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration),
                                           of: firstAsset.tracks(withMediaType: .video)[0],
                                           at: CMTime.zero)
        } catch {
            print("Failed to load first track")
            return
        }
        
        guard let secondTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                               preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try secondTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: secondAsset.duration),
                                            of: secondAsset.tracks(withMediaType: .video)[0],
                                            at: firstAsset.duration)
        } catch {
            print("Failed to load second track")
            return
        }
        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(firstAsset.duration, secondAsset.duration))
        
        // 2.2
        let firstInstruction = VideoHelper.videoCompositionInstruction(firstTrack, asset: firstAsset)
        firstInstruction.setOpacity(0.0, at: firstAsset.duration)
        let secondInstruction = VideoHelper.videoCompositionInstruction(secondTrack, asset: secondAsset)
        
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        // 3 - Audio track
        if let loadedAudioAsset = audioAsset {
            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(firstAsset.duration, secondAsset.duration)),
                                                of: loadedAudioAsset.tracks(withMediaType: .audio)[0] ,
                                                at: CMTime.zero)
            } catch {
                print("Failed to load Audio track")
            }
        }
        
        // 4 - Get path
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition
        
        // 6 - Perform the Export
        exporter.exportAsynchronously() {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
        
    }
}

extension MergeVideoViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true, completion: nil)
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            else { return }
        
        let avAsset = AVAsset(url: url)
        var message = ""
        if loadingAssetOne {
            message = "Video one loaded"
            firstAsset = avAsset
        } else {
            message = "Video two loaded"
            secondAsset = avAsset
        }
        let alert = UIAlertController(title: "Asset Loaded", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

extension MergeVideoViewController: UINavigationControllerDelegate {
    
}

extension MergeVideoViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        dismiss(animated: true) {
            let selectedSongs = mediaItemCollection.items
            guard let song = selectedSongs.first else { return }
            
            let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
            self.audioAsset = (url == nil) ? nil : AVAsset(url: url!)
            let title = (url == nil) ? "Asset Not Available" : "Asset Loaded"
            let message = (url == nil) ? "Audio Not Loaded" : "Audio Loaded"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler:nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true, completion: nil)
    }
}

