//
//  ViewController.swift
//  CoreImageDemo
//
//  Created by Sumit Ghosh on 19/07/18.
//  Copyright © 2018 Sumit Ghosh. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary


class ViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var amountSlider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    var context: CIContext!
    var filter: CIFilter!
    var beginImage: CIImage!
    var orientation: UIImageOrientation = .up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker.delegate = self
        //self.filtertedImage()
        self.newFilterImage()
       // self.logAllFilters()
    }
    
//    func logAllFilters() -> Void {
//        let properties = CIFilter.filterNames(inCategory: kCICategoryBuiltIn)
//        print(properties)
//
//        for filterName: String in properties {
//            let fltr = CIFilter(name: filterName as String)
//            print(fltr?.attributes as Any)
//        }
//    }
    
    
    
    //MARK: To change color of status bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: Adding filter with CIContext
    func newFilterImage() -> Void {
        let fileUrl = Bundle.main.url(forResource: "image", withExtension: "png")
        
        self.beginImage = CIImage.init(contentsOf: fileUrl!)
        
        self.filter = CIFilter.init(name: "CISepiaTone")
        self.filter?.setValue(beginImage, forKey: kCIInputImageKey)
        self.filter?.setValue(0.5, forKey: kCIInputIntensityKey)
        
        self.context = CIContext.init(options: nil)
        let cgImage = self.context.createCGImage((filter?.outputImage)!, from: (filter?.outputImage?.extent)!)
        
        let newImage = UIImage.init(cgImage: cgImage!)
        self.imageView.image = newImage
    }
    
    //MARK: Slider action method
    @IBAction func sliderAction(_ sender: UISlider) {
        
        let sliderValue = sender.value
        let outputImage = self.oldPhoto(img: beginImage, withAmount: sliderValue)
        let cgImage = self.context.createCGImage(outputImage, from: (outputImage.extent))
        let newImage = UIImage.init(cgImage: cgImage!)
        self.imageView.image = newImage
    }
    
    //MARK: Adding filter Without CIContext
    func filtertedImage() -> Void {
        let fileUrl = Bundle.main.url(forResource: "image", withExtension: "png")
        
        let beginImage = CIImage.init(contentsOf: fileUrl!)
        
        let filter = CIFilter.init(name: "CISepiaTone")
        filter?.setValue(beginImage, forKey: kCIInputImageKey)
        filter?.setValue(0.5, forKey: kCIInputIntensityKey)
        
        let newImage = UIImage(cgImage: beginImage as! CGImage, scale: 1, orientation: orientation)
        self.imageView.image = newImage
    }

    @IBAction func savePhoto(sender: AnyObject) {
        let imageToSave = self.filter.outputImage
        
        let softwareContext = CIContext(options: [kCIContextUseSoftwareRenderer: true])
        
        let cgimg = softwareContext.createCGImage(imageToSave!, from: (imageToSave?.extent)!)
        
        let library = ALAssetsLibrary()
        library.writeImage(toSavedPhotosAlbum: cgimg,
                                             metadata:imageToSave!.properties,
                                             completionBlock:{_,_ in
                                                let alert = UIAlertController(title: "Success", message: "Image Saved", preferredStyle: UIAlertControllerStyle.alert)
                                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                                self.present(alert, animated: true, completion: nil)
                                                
        })
    }
    
    
    
    
    @IBAction func CameraButtonAction(_ sender: Any) {
        let status = PHPhotoLibrary.authorizationStatus()
        print("\(status)")
        
        if (status == PHAuthorizationStatus.authorized) {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
            
        else if (status == PHAuthorizationStatus.denied) {
            print("Not approved image")
        }
            
        else if (status == PHAuthorizationStatus.notDetermined) {
            
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    self.imagePicker.allowsEditing = false
                    self.imagePicker.sourceType = .photoLibrary
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
                else {
                    print("Not approved image")
                }
            })
        }
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
        
    }
    
   @objc private func imagePickerController(_ picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [String : Any]!) {
        self.dismiss(animated: true, completion: nil);
        print(info);
        let gotImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.orientation = gotImage.imageOrientation
        beginImage = CIImage(image:gotImage)
        filter.setValue(beginImage, forKey: kCIInputImageKey)
        self.sliderAction(amountSlider)
    }
    
    func oldPhoto(img: CIImage, withAmount intensity: Float) -> CIImage {
        let sepia = CIFilter(name: "CISepiaTone")
        sepia?.setValue(img, forKey: kCIInputImageKey)
        sepia?.setValue(intensity, forKey: "inputIntensity")
        
        let random = CIFilter(name: "CIRandomGenerator")
        
        let lighten = CIFilter(name: "CIColorControls")
        lighten?.setValue(random?.outputImage, forKey: kCIInputImageKey)
        lighten?.setValue(1 - intensity, forKey: "inputBrightness")
        lighten?.setValue(0, forKey: "inputSaturation")
        
        let croppedImage = lighten?.outputImage?.cropped(to: beginImage.extent)
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite?.setValue(sepia?.outputImage, forKey: kCIInputImageKey)
        composite?.setValue(croppedImage, forKey: kCIInputBackgroundImageKey)
        
        let viginette = CIFilter(name: "CIVignette")
        viginette?.setValue(composite?.outputImage, forKey: kCIInputImageKey)
        viginette?.setValue(intensity * 2, forKey: "inputIntensity")
        viginette?.setValue(intensity * 30, forKey: "inputRadius")
        
        return (viginette?.outputImage)!
        

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

