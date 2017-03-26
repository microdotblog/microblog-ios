//
//  FAImageCropperVC.swift
//  FAImageCropper
//
//  Created by Fahid Attique on 11/02/2017.
//  Copyright © 2017 Fahid Attique. All rights reserved.
//

import UIKit
import Photos

class FAImageCropperVC: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var scrollContainerView: UIView!
    @IBOutlet weak var scrollView: FAScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnZoom: UIButton!
    @IBOutlet weak var btnCrop: UIButton!
    @IBAction func zoom(_ sender: Any) {
        scrollView.zoom()
    }
    @IBAction func crop(_ sender: Any) {
        croppedImage = captureVisibleRect()
        performSegue(withIdentifier: "FADetailViewSegue", sender: nil)
    }
    
    
    
    // MARK: Public Properties
    
    var photos:[PHAsset]!

    
    
    // MARK: Private Properties
    
    private let imageLoader = FAImageLoader()
    private var croppedImage: UIImage? = nil

    
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.\
        viewConfigurations()
        checkForPhotosPermission()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "FADetailViewSegue" {
            
            let detailVC = segue.destination as? FADetailVC
            detailVC?.croppedImage = croppedImage
        }
    }
    
    // MARK: Private Functions
    
    private func checkForPhotosPermission(){
        
        // Get the current authorization state.
        let status = PHPhotoLibrary.authorizationStatus()
        
        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
            loadPhotos()
        }
        else if (status == PHAuthorizationStatus.denied) {
            // Access has been denied.
        }
        else if (status == PHAuthorizationStatus.notDetermined) {
            
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    
                    DispatchQueue.main.async {
                        self.loadPhotos()
                    }
                }
                else {
                    // Access has been denied.
                }
            })
        }
            
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
    }
    
    private func viewConfigurations() {
        btnCrop.layer.cornerRadius = btnCrop.frame.size.width/2
        btnZoom.layer.cornerRadius = btnZoom.frame.size.width/2
    }
    
    private func loadPhotos(){

        imageLoader.loadPhotos { (assets) in
            self.configureImageCropper(assets: assets)
        }
    }
    
    private func configureImageCropper(assets:[PHAsset]){

        if assets.count != 0{
            photos = assets
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.reloadData()
            selectDefaultImage()
        }
    }

    private func selectDefaultImage(){
        collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .top)
        FAImageLoader.imageFrom(asset: photos[0]) { (image) in
            DispatchQueue.main.async {
                self.displayImageInScrollView(image: image)
            }
        }
    }
    
    private func captureVisibleRect() -> UIImage{
        
        let scrollContainerAsImage:UIImage = snapShotOfScrollContainer()
        let visibleFrame:CGRect = visibleRectOf(imageView: scrollView.imageView)

        let imageView:UIImageView = UIImageView(image: scrollContainerAsImage)
        imageView.frame.origin = visibleFrame.origin
        
        let containerView:UIView = UIView(frame: view.frame)
        containerView.addSubview(imageView)
        
        UIGraphicsBeginImageContextWithOptions(visibleFrame.size, false, 0.0)
        containerView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let visibleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return visibleImage!

    }
    
    private func visibleRectOf(imageView:UIImageView) -> CGRect{

        var visibleImageFrame:CGRect = CGRect(origin: .zero, size: scrollContainerView.frame.size)

        let imageViewFrame:CGRect = imageView.frame

        if imageViewFrame.origin.x > 0 {
            visibleImageFrame.origin.x = -imageViewFrame.origin.x
        }
        
        if imageViewFrame.origin.y > 0 {
            visibleImageFrame.origin.y = -imageViewFrame.origin.y
        }
        
        if imageViewFrame.size.width < scrollContainerView.frame.size.width {
            visibleImageFrame.size.width = imageViewFrame.size.width
        }

        if imageViewFrame.size.height < scrollContainerView.frame.size.height {
            visibleImageFrame.size.height = imageViewFrame.size.height
        }
        
        return visibleImageFrame
    }

    
    private func snapShotOfScrollContainer() -> UIImage{
        
        UIGraphicsBeginImageContextWithOptions(scrollView.frame.size, false, 0.0)
        scrollContainerView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    
    private func isSquareImage() -> Bool{
        let image = scrollView.imageToDisplay
        if image?.size.width == image?.size.height { return true }
        else { return false }
    }

    
    // MARK: Public Functions

    func displayImageInScrollView(image:UIImage){
        self.scrollView.imageToDisplay = image
        if isSquareImage() { btnZoom.isHidden = true }
        else { btnZoom.isHidden = false }
    }
}





extension FAImageCropperVC:UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:FAImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FAImageCell", for: indexPath) as! FAImageCell
        cell.populateDataWith(asset: photos[indexPath.item])
        return cell
    }
}


extension FAImageCropperVC:UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell:FAImageCell = collectionView.cellForItem(at: indexPath) as! FAImageCell
        cell.isSelected = true
        displayImageInScrollView(image: cell.imageView.image!)
    }
}


extension FAImageCropperVC:UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width:CGFloat = ((UIScreen.main.bounds.size.width-10)/3)-7

//        let width:CGFloat = (collectionView.bounds.size.width-25)/3
        return CGSize(width: width, height: width)
    }
}
