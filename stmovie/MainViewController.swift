//
//  ViewController.swift
//  stmovie
//
//  Created by Prog on 8/20/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, PhotoBrowserDelegate {
    
    let chooseButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Choose video", for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        view.addSubview(chooseButton)
        
        chooseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        chooseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        chooseButton.addTarget(self, action: #selector(chooseButtonTapped), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    @objc
    func chooseButtonTapped () {
        
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

