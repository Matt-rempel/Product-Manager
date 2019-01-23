//
//  Main.swift
//  Products
//
//  Created by Matthew Rempel on 2019-01-18.
//  Copyright © 2019 Matthew Rempel. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage

class Main {
    
    public static let shared = Main()
    
    public var ref = Database.database().reference()
    public var storage = Storage.storage(url:"gs://booking-service-ace0a.appspot.com/")
    static public var tintColor:UIColor! = UIView().tintColor!
    
    func getPrettyPrice(inputPrice:Float)->String {
        
        var priceStr = "\(Double(inputPrice/100).rounded(toPlaces: 2))"
        if priceStr.hasSuffix(".0") {
            priceStr = priceStr + "0"
        }
        return "$\(priceStr)"
    }
    
    func setStarButtonImage(state: Bool, barButton: UIBarButtonItem) {

        let image = UIImage(named: "image_name")?.withRenderingMode(.alwaysTemplate)
        barButton.setBackgroundImage(image, for: .normal, barMetrics: .default)
        if state {
            barButton.tintColor = Main.tintColor
        } else {
            barButton.tintColor = .gray
        }
    }
    
    func toggleFaveProduct(product: shopItem, MainViewInstance: MainView) {
        product.star.toggle()
        
        ref.child("shop_items").child(product.firebaseRoot).setValue(
            [ "description" : product.description,
              "id" : product.productID,
              "image" : product.image,
              "price" : product.price,
              "tags" : product.tags,
              "title" : product.title,
              "quantity": product.quantity,
              "star": product.star]) {
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                    MainViewInstance.pullFirebase()
                }
        }
    }
    
    func deleteProduct(product: shopItem, MainViewInstance: MainView) {
        print(product.firebaseRoot)
        print("Deleting product with FB root ^^^")
        
        // Create a reference with an initial file path and name
        let pathReference = storage.reference(withPath: product.image)
        
        //Removes image from storage
        pathReference.delete { error in
            if let error = error {
                print(error)
            } else {
                // File deleted successfully
            }
            self.ref.child("shop_items").child(product.firebaseRoot).setValue(
            [ nil]) {
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                    MainViewInstance.pullFirebase()
                }
            }
        }
    }
    
    func deleteProductWithOutReload(product: shopItem) {
        // Create a reference with an initial file path and name
        let pathReference = storage.reference(withPath: product.image)
        
        //Removes image from storage
        pathReference.delete { error in
            if let error = error {
                print(error)
            } else {
                // File deleted successfully
            }
            self.ref.child("shop_items").child(product.firebaseRoot).setValue(
            [ nil]) {
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                }
            }
        }
    }
    
}

extension Array where Element:shopItem {
    mutating func removeDuplicates() {
        var result:[shopItem]! = []
        for value in self {
            let currentValId = value.productID
            var isInTheArrayAlready = false
            for i in result {
                isInTheArrayAlready = (i.productID == currentValId)
                if isInTheArrayAlready{
                    break
                }
            }
            if !isInTheArrayAlready {
                result.append(value)
            }
        }
        
        self = result as! Array<Element>
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension UIImage {
    func resizeWithPercent(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    func resizeWithWidth(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    func compressImage() -> UIImage? {
        // Reducing file size to a 10th
        var actualHeight: CGFloat = self.size.height
        var actualWidth: CGFloat = self.size.width
        let maxHeight: CGFloat = 1136.0
        let maxWidth: CGFloat = 640.0
        var imgRatio: CGFloat = actualWidth/actualHeight
        let maxRatio: CGFloat = maxWidth/maxHeight
        var compressionQuality: CGFloat = 0.5
        
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        self.draw(in: rect)
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        guard let imageData = img.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

extension UIImage {
    func fixOrientation() -> UIImage {
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        if let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        } else {
            return self
        }
    }
}
