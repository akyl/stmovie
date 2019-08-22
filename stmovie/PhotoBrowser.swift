//
//  PhotoBrowser.swift
//  stmovie
//
//  Created by Prog on 8/21/19.
//  Copyright © 2019 azholonov. All rights reserved.
//

import UIKit
import Photos

class PhotoBrowser: UIViewController
{
    let manager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    
    var touchedCell: (cell: UICollectionViewCell, indexPath: NSIndexPath)?
    var collectionViewWidget: UICollectionView!
    var segmentedControl: UISegmentedControl!
    let blurOverlay = UIVisualEffectView(effect: UIBlurEffect())
    let background = UIView(frame: .zero)
    let activityIndicator = ActivityIndicator()
    
    var photoBrowserSelectedSegmentIndex = 0
    
    var assetCollections: PHFetchResult<AnyObject>!
    var segmentedControlItems = [String]()
    var contentOffsets = [CGPoint]()
    
    var selectedAsset: PHAsset?
    var uiCreated = false
    
    var returnImageSize = CGSize(width: 100, height: 100)
    
    weak var delegate: PhotoBrowserDelegate?
    
    required init(returnImageSize: CGSize)
    {
        super.init(nibName: nil, bundle: nil)
        
        self.returnImageSize = returnImageSize
        
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.progressHandler = {
            (value: Double, _: NSError?, _ : UnsafeMutablePointer<ObjCBool>, _ : [NSObject : AnyObject]?) in
            self.activityIndicator.updateProgress(value: value)
            } as! PHAssetImageProgressHandler
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func launch()
    {
        if let viewController = UIApplication.shared.keyWindow!.rootViewController
        {
            modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            
            viewController.present(self, animated: true, completion: nil)
            
            activityIndicator.stopAnimating()
        }
    }
    
    var assets: PHFetchResult<AnyObject>!
    {
        didSet
        {
            guard let oldValue = oldValue else
            {
                return
            }
            
            if oldValue.count - assets.count == 1
            {
                collectionViewWidget.deleteItems(at: [touchedCell!.indexPath as IndexPath])
                
                collectionViewWidget.reloadData()
            }
            else if oldValue.count != assets.count
            {
                UIView.animate(withDuration: PhotoBrowserConstants.animationDuration,
                                           animations:
                    {
                        self.collectionViewWidget.alpha = 0
                },
                                           completion:
                    {
                        (value: Bool) in
                        self.collectionViewWidget.reloadData()
                        self.collectionViewWidget.contentOffset = self.contentOffsets[self.segmentedControl.selectedSegmentIndex]
                        UIView.animate(withDuration: PhotoBrowserConstants.animationDuration, animations: { self.collectionViewWidget.alpha = 1.0 })
                })
            }
            else
            {
                collectionViewWidget.reloadData()
            }
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        PHPhotoLibrary.shared().register(self)
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized
        {
            createUserInterface()
        }
        else
        {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    func requestAuthorizationHandler(status: PHAuthorizationStatus)
    {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized
        {
            PhotoBrowser.executeInMainQueue(function: { self.createUserInterface() })
        }
        else
        {
            PhotoBrowser.executeInMainQueue(function: { self.dismiss(animated: true, completion: nil) })
        }
    }
    
    func createUserInterface()
    {
        assetCollections = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil) as? PHFetchResult<AnyObject>
        
        segmentedControlItems = [String]()
        
        for var i = 0 ; i < assetCollections.count ; i++
        {
            let assetCollection = assetCollections[i] as? PHAssetCollection
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
            
            let assetsInCollection  = PHAsset.fetchAssetsInAssetCollection(assetCollection!, options: fetchOptions)
            
            if assetsInCollection.count > 0 || assetCollection?.localizedTitle == "Favorites"
            {
                if let localizedTitle = assetCollection?.localizedTitle
                {
                    segmentedControlItems.append(localizedTitle)
                    
                    contentOffsets.append(CGPoint(x: 0, y: 0))
                }
            }
        }
        
        segmentedControlItems = segmentedControlItems.sort { $0 < $1 }
        
        segmentedControl = UISegmentedControl(items: segmentedControlItems)
        segmentedControl.selectedSegmentIndex = photoBrowserSelectedSegmentIndex
        segmentedControl.addTarget(self, action: Selector(("segmentedControlChangeHandler")), for: UIControl.Event.valueChanged)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = PhotoBrowserConstants.thumbnailSize
        layout.minimumLineSpacing = 30
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        collectionViewWidget = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        collectionViewWidget.backgroundColor = UIColor.clear
        
        collectionViewWidget.delegate = self
        collectionViewWidget.dataSource = self
        collectionViewWidget.register(ImageItemRenderer.self, forCellWithReuseIdentifier: "Cell")
        collectionViewWidget.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == UIForceTouchCapability.available
        {
            registerForPreviewing(with: self, sourceView: view)
        }
        else
        {
            let longPress = UILongPressGestureRecognizer(target: self, action: Selector(("longPressHandler:")))
            collectionViewWidget.addGestureRecognizer(longPress)
        }
        
        background.layer.borderColor = UIColor.darkGray.cgColor
        background.layer.borderWidth = 1
        background.layer.cornerRadius = 5
        background.layer.masksToBounds = true
        
        view.addSubview(background)
        
        background.addSubview(blurOverlay)
        background.addSubview(collectionViewWidget)
        background.addSubview(segmentedControl)
        
        view.backgroundColor = UIColor(white: 0.15, alpha: 0.85)
        
        activityIndicator.frame = CGRect(origin: .zero, size: view.frame.size)
        view.addSubview(activityIndicator)
        
        segmentedControlChangeHandler()
        
        uiCreated = true
    }
    
    // MARK: User interaction handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        
        if let locationInView = touches.first?.location(in: view),
            !background.frame.contains(locationInView)
        {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func segmentedControlChangeHandler()
    {
        contentOffsets[photoBrowserSelectedSegmentIndex] = collectionViewWidget.contentOffset
        
        photoBrowserSelectedSegmentIndex = segmentedControl.selectedSegmentIndex
        
        let options = PHFetchOptions()
        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        options.predicate =  NSPredicate(format: "mediaType = %i", PHAssetMediaType.image.rawValue)
        
        for var i = 0; i < assetCollections.count; i++
        {
            if segmentedControlItems[photoBrowserSelectedSegmentIndex] == assetCollections[i].localizedTitle
            {
                if let assetCollection = assetCollections[i] as? PHAssetCollection
                {
                    assets = PHAsset.fetchAssetsInAssetCollection(assetCollection, options: options)
                    
                    return
                }
            }
        }
        
        selectedAsset = nil
    }
    
    func longPressHandler(recognizer: UILongPressGestureRecognizer)
    {
        guard let touchedCell = touchedCell,
            let asset = assets[touchedCell.indexPath.row] as? PHAsset,
            recognizer.state == UIGestureRecognizer.State.began else
        {
            return
        }
        
        let contextMenuController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let toggleFavouriteAction = UIAlertAction(title: asset.favorite ? "Remove Favourite" : "Make Favourite", style: UIAlertActionStyle.Default, handler: toggleFavourite)
        
        contextMenuController.addAction(toggleFavouriteAction)
        
        if let popoverPresentationController = contextMenuController.popoverPresentationController
        {
            popoverPresentationController.sourceRect = collectionViewWidget.convert(touchedCell.cell.frame, to: self.view)
            
            popoverPresentationController.sourceView = view
        }
        
        present(contextMenuController, animated: true, completion: nil)
    }
    
    func toggleFavourite(_: UIAlertAction!) -> Void
    {
        if let touchedCell = touchedCell, let targetEntity = assets[touchedCell.indexPath.row] as? PHAsset
        {
            PHPhotoLibrary.shared().performChanges(
                {
                    let changeRequest = PHAssetChangeRequest(forAsset: targetEntity)
                    changeRequest.favorite = !targetEntity.favorite
            },
                completionHandler: nil)
        }
    }
    
    // MARK: Image management
    
    func requestImageForAsset(asset: PHAsset)
    {
        activityIndicator.startAnimating()
        
        selectedAsset = asset
        
        manager.requestImage(for: asset,
                                     targetSize: returnImageSize,
                                     contentMode: PHImageContentMode.aspectFill,
                                     options: requestOptions,
                                     resultHandler: imageRequestResultHandler as! (UIImage?, [AnyHashable : Any]?) -> Void)
    }
    
    func imageRequestResultHandler(image: UIImage?, properties: [NSObject: AnyObject]?)
    {
        if let delegate = delegate, let image = image, let selectedAssetLocalIdentifier = selectedAsset?.localIdentifier
        {
            PhotoBrowser.executeInMainQueue
                {
                    delegate.photoBrowserDidSelectImage(image: image, localIdentifier: selectedAssetLocalIdentifier)
            }
        }
        // TODO : Handle no image case (asset is broken in iOS)
        
        activityIndicator.stopAnimating()
        selectedAsset = nil
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: System Layout
    
    override func viewDidLayoutSubviews()
    {
        if uiCreated
        {
            background.frame = view.frame.insetBy(dx: 50, dy: 50)
            activityIndicator.frame = view.frame.insetBy(dx: 50, dy: 50)
            blurOverlay.frame = CGRect(x: 0, y: 0, width: background.frame.width, height: background.frame.height)
            
            segmentedControl.frame = CGRect(x: 0, y: 0, width: background.frame.width, height: 40).insetBy(dx: 5, dy: 5)
            collectionViewWidget.frame = CGRect(x: 0, y: 40, width: background.frame.width, height: background.frame.height - 40)
        }
    }
    
    deinit
    {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    static func executeInMainQueue(function: @escaping () -> Void)
    {
        DispatchQueue.main.async {
            function()
        }
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension PhotoBrowser: PHPhotoLibraryChangeObserver
{
    func photoLibraryDidChange(_ changeInstance: PHChange)
    {
        guard let assets = assets else
        {
            return
        }
        
        if let changeDetails = changeInstance.changeDetailsForFetchResult(assets), uiCreated
        {
            PhotoBrowser.executeInMainQueue{ self.assets = changeDetails.fetchResultAfterChanges }
        }
    }
}

// MARK: UICollectionViewDataSource
extension PhotoBrowser: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath as IndexPath) as! ImageItemRenderer
        
        let asset = assets[indexPath.row] as! PHAsset
        
        cell.asset = asset;
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return assets.count
    }
}

// MARK: UICollectionViewDelegate
extension PhotoBrowser: UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let asset = assets[indexPath.row] as? PHAsset
        {
            requestImageForAsset(asset)
        }
    }
}

// MARK:
extension PhotoBrowser: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let touchedCell = touchedCell,
            let asset = assets[touchedCell.indexPath.row] as? PHAsset else
        {
            return nil
        }
        
        let previewSize = min(view.frame.width, view.frame.height) * 0.8
        
        let peekController = PeekViewController(frame: CGRect(x: 0, y: 0,
                                                              width: previewSize,
                                                              height: previewSize))
        
        peekController.asset = asset
        
        return peekController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        guard let touchedCell = touchedCell,
            let asset = assets[touchedCell.indexPath.row] as? PHAsset else
        {
            dismiss(animated: true, completion: nil)
            
            return
        }
        
        requestImageForAsset(asset)
    }
}

// MARK: PeekViewController
class PeekViewController: UIViewController
{
    let itemRenderer: ImageItemRenderer
    
    required init(frame: CGRect)
    {
        itemRenderer = ImageItemRenderer(frame: frame)
        
        super.init(nibName: nil, bundle: nil)
        
        preferredContentSize = frame.size
        
        view.addSubview(itemRenderer)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toggleFavourite()
    {
        if let targetEntity = asset
        {
            PHPhotoLibrary.shared().performChanges(
                {
                    let changeRequest = PHAssetChangeRequest(for: targetEntity)
                    changeRequest.isFavorite = !targetEntity.isFavorite
            },
                completionHandler: nil)
        }
    }
    
    var previewActions: [UIPreviewActionItem]
    {
        return [UIPreviewAction(title: asset!.isFavorite ? "Remove Favourite" : "Make Favourite",
                                style: UIPreviewAction.Style.default,
                                handler:
            {
                (previewAction, viewController) in (viewController as? PeekViewController)?.toggleFavourite()
        })]
    }
    
    var asset: PHAsset?
    {
        didSet
        {
            if let asset = asset
            {
                itemRenderer.asset = asset;
            }
        }
    }
}

// MARK: ActivityIndicator overlay
class ActivityIndicator: UIView
{
    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
    let label = UILabel()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        addSubview(activityIndicator)
        addSubview(label)
        
        backgroundColor = UIColor(white: 0.15, alpha: 0.85)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        
        label.text = "Loading..."
        
        stopAnimating()
    }
    
    override func layoutSubviews()
    {
        activityIndicator.frame = CGRect(origin: .zero, size: frame.size)
        
        label.frame = CGRect(x: 0,
                             y: label.intrinsicContentSize.height,
                             width: frame.width,
                             height: label.intrinsicContentSize.height)
    }
    
    func updateProgress(value: Double)
    {
        PhotoBrowser.executeInMainQueue
            {
                self.label.text = "Loading \(Int(value * 100))%"
        }
    }
    
    func startAnimating()
    {
        activityIndicator.startAnimating()
        
        Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(UIAlertView.show), userInfo: nil, repeats: false)
    }
    
    func show()
    {
        PhotoBrowser.executeInMainQueue
            {
                self.label.text = "Loading..."
                self.isHidden = false
        }
    }
    
    func stopAnimating()
    {
        isHidden = true
        activityIndicator.stopAnimating()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

struct PhotoBrowserConstants
{
    static let thumbnailSize = CGSize(width: 100, height: 100)
    static let animationDuration = 0.175
}
