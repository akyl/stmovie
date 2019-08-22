//
//  ViewController.swift
//  stmovie
//
//  Created by Prog on 8/20/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    let selectButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Select and Play video", for: .normal)
        return button
    }()
    
    let recordButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Record and Save video", for: .normal)
        return button
    }()
    
    let mergeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Merge video", for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        view.addSubview(recordButton)
        view.addSubview(selectButton)
        view.addSubview(mergeButton)
        
        recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        selectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        selectButton.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -20).isActive = true
        
        mergeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mergeButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20).isActive = true
        
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        mergeButton.addTarget(self, action: #selector(mergeButtonTapped), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    @objc
    func selectButtonTapped () {
        navigationController?.pushViewController(PlayVideoViewController(), animated: true)
    }
    
    @objc
    func recordButtonTapped () {
        navigationController?.pushViewController(RecordVideoViewController(), animated: true)
    }
    
    @objc
    func mergeButtonTapped () {
        navigationController?.pushViewController(MergeVideoViewController(), animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

