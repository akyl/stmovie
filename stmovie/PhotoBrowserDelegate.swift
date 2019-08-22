//
//  PhotoBrowserDelegate.swift
//  stmovie
//
//  Created by Prog on 8/21/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import Foundation
import UIKit

protocol PhotoBrowserDelegate: NSObjectProtocol
{
    func photoBrowserDidSelectImage(image: UIImage, localIdentifier: String)
}
