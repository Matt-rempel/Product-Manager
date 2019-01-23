//
//  DetailView.swift
//  Products
//
//  Created by Matthew Rempel on 2019-01-18.
//  Copyright © 2019 Matthew Rempel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class DetailView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {

    @IBOutlet var nameLabel: UITextField!
    @IBOutlet var priceLabel: UITextField!
    @IBOutlet var quantityLabel: UITextField!
    @IBOutlet var tagsLabel: UILabel!
    @IBOutlet var editTagsButton: UIButton!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var imageImageView: UIImageView!
    @IBOutlet var starButton: UIBarButtonItem!
    @IBOutlet var deleteItemButton: UIBarButtonItem!
    
    var isAddingNew:Bool!
    public var product:shopItem!
    var storage:Storage!
    var ref: DatabaseReference!
    var imagePicker: UIImagePickerController!
    var didChangeImage = false
    
    enum ImageSource {
        case photoLibrary
        case camera
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(doneTapped))
        
        ref = Main.shared.ref
        storage = Main.shared.storage
        
        descriptionTextView.delegate = self
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)

        Main.shared.setStarButtonImage(state: product.star, barButton: starButton)
        
        if !isAddingNew {
            nameLabel.text = product.title
            priceLabel.text = Main.shared.getPrettyPrice(inputPrice: product!.price)
            quantityLabel.text = "\(product.quantity!)"
            descriptionTextView.text = product.description
            
            loadTags()
            
            storage = Main.shared.storage
            // Create a reference with an initial file path and name
            let pathReference = storage.reference(withPath: product.image)
            let imageView: UIImageView = imageImageView
            let placeholderImage = UIImage(named: "placeholder.jpg")
            imageView.sd_setImage(with: pathReference, placeholderImage: placeholderImage)
            
        } else {
            deleteItemButton.isEnabled = false
            descriptionTextView.text = "Description..."
            descriptionTextView.textColor = UIColor.lightGray
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadTags()
    }
    
    // MARK: - UI helper methods
    @objc func doneTapped() {
        let alert = UIAlertController(title: nil, message: "Uploading Data...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
        if didChangeImage {
            uploadPhoto()
        } else {
            if product.image != nil {
                sendToFirebase(downloadURL: product.image)
            } else {
                sendToFirebase(downloadURL: "")
            }
            
        }
        
    }
    
    public func loadTags() {
        var tags = ""
        if product.tags != nil && product.tags.count > 0 {
            for i in 0...product.tags.count-1 {
                if i == product.tags.count-1 {
                    tags += "\(product.tags[i])"
                } else {
                    tags += "\(product.tags[i]), "
                }
            }
            tagsLabel.text = "Tags: \(tags)"
        } else {
            tagsLabel.text = "Tags: None"
        }
    }
    
    func uploadPhoto() {
        print("uploading image start")
        var selectedImage = self.imageImageView.image
        var selectedImage2 = self.imageImageView.image
        
        var imgData: NSData = NSData(data: (selectedImage?.jpegData(compressionQuality: 1))!)
        var imageSize: Int = imgData.length
        print("ORIGINAL in KB: %f ", Double(imageSize) / 1024.0)

        let compressData = selectedImage!.jpegData(compressionQuality: 0.1)
        selectedImage = UIImage(data: compressData!)
        selectedImage = selectedImage?.fixOrientation()
        
        imgData = NSData(data: (selectedImage?.jpegData(compressionQuality: 1))!)
        imageSize = imgData.length
        print("METHOD: #1 KB: %f ", Double(imageSize) / 1024.0)
        
        
        selectedImage2 = selectedImage2!.compressImage()
        
        imgData = NSData(data: (selectedImage2?.jpegData(compressionQuality: 1))!)
        imageSize = imgData.length
        print("METHOD: #2 KB: %f ", Double(imageSize) / 1024.0)
        
        
        
        let timestamp = "\(NSDate().timeIntervalSince1970)"
        let timestampStr = timestamp.replacingOccurrences(of: ".", with: "_")
        var imageName = ""
        if product.title == nil {
            imageName = "\(timestampStr).JPG"
        } else {
            imageName = "\(product.title!)_\(timestampStr).JPG"
        }
        
        imageName = imageName.replacingOccurrences(of: " ", with: "_")
        imageName = imageName.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        let fileManager = FileManager.default
        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
        print(imagePath)
        
        // Using compression method 2
        let data = selectedImage2!.pngData()
        imageImageView.image = selectedImage2
        fileManager.createFile(atPath: imagePath as String, contents: data, attributes: nil)


        let storageRef = storage.reference()

        // File located on disk
        let localFile = URL(string: "file://\(imagePath)")!
        print("\(#line): \(localFile)")

        // Create a reference to the file you want to upload
        let riversRef = storageRef.child("images/\(imageName)")
        print("\(#line): \(riversRef)")
        
        let data2 = NSData(contentsOf: localFile)
        imageImageView.image = UIImage(data: data2! as Data)
        let selectedImage3 = UIImage(data: data2! as Data)

        UIImageWriteToSavedPhotosAlbum(selectedImage3!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = riversRef.putFile(from: localFile, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                print("\(#line): \(String(describing: error))")
                return
            }
            
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            print("\(#line): Size \(size)")
            
            print("Done uploading image now calling sendToFirebase()")
            self.sendToFirebase(downloadURL: "images/\(imageName)")
        }
        
        print(uploadTask)
    }
    
    func sendToFirebase(downloadURL: String) {
        let newTitle = product.title ?? ""
        let newDesc = product.description ?? ""
        let newPrice = product.price ?? 9.99
        let newID = product.productID ?? Int(NSDate().timeIntervalSince1970)
        let newQuantity = product.quantity ?? 1
        let newTags = product.tags ?? []
        let newStar = product.star ?? false
        let newImage = "\(downloadURL)"
        
        
        // Send item to firebase
        if product.firebaseRoot == nil {
            ref.child("shop_items").childByAutoId().setValue(
                [ "description" : newDesc,
                  "id" : newID,
                  "image" : newImage,
                  "price" : newPrice,
                  "tags" : newTags,
                  "title" : newTitle,
                  "quantity": newQuantity,
                  "star": newStar]) {
                    (error:Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("Data could not be saved: \(error).")
                    } else {
                        print("Data saved successfully!")
                    }
            }
        } else {
            ref.child("shop_items").child(product.firebaseRoot).setValue(
                [ "description" : newDesc,
                  "id" : newID,
                  "image" : newImage,
                  "price" : newPrice,
                  "tags" : newTags,
                  "title" : newTitle,
                  "quantity": newQuantity,
                  "star": newStar]) {
                    (error:Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("Data could not be saved: \(error).")
                    } else {
                        print("Data saved successfully!")
                    }
            }
        }
        
        dismiss(animated: false, completion: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    
    @IBAction func didChangeNameLabel(_ sender: Any) {
        product.title = nameLabel.text
        print("Changed name input text")
    }
    
    @IBAction func didBeginEditingPriceLabel(_ sender: Any) {
        priceLabel.text = priceLabel.text?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ".", with: "")
    }
    
    @IBAction func didChangePriceLabel(_ sender: Any) {
        
        let floatval = Float(priceLabel.text as! String) ?? nil
        if floatval == nil {
            print("invalid input \(String(describing: priceLabel.text)) is not a float")
        } else {
            product.price = floatval
        }
        
        print("floatval: \(String(describing: floatval))")
    }
    
    @IBAction func priceLabelDidFinishEditing(_ sender: Any) {
        if priceLabel.text != nil && priceLabel.text != "" {
            priceLabel.text = Main.shared.getPrettyPrice(inputPrice: product.price)
        }
    }
    
    @IBAction func didChangeQuantityLabel(_ sender: Any) {
        product.quantity = Int(quantityLabel.text ?? "1")
        print("Quantity is now: \(String(describing: product.quantity))")
    }
    
    
    @IBAction func pressedEditButton(_ sender: Any) {
        // Logic is in Storyboard
    }
    
    @IBAction func pressedStarButton(_ sender: Any) {
        product.star.toggle()
        Main.shared.setStarButtonImage(state: product.star, barButton: starButton)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let alert = UIAlertController(title: "Title", message: "Please Select an Option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default , handler:{ (UIAlertAction) in
            self.selectImageFrom(.photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default , handler:{ (UIAlertAction) in
            self.selectImageFrom(.camera)
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func selectImageFrom(_ source: ImageSource){
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        switch source {
        case .camera:
            imagePicker.sourceType = .camera
        case .photoLibrary:
            imagePicker.sourceType = .photoLibrary
        }
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - Saving Image here
    @IBAction func save(_ sender: AnyObject) {
        
    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            showAlertWith(title: "Save error", message: error.localizedDescription)
        } else {
            print("Saved photo to camera")
//            showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
        }
    }
    
    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        imagePicker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.originalImage] as? UIImage else {
            print("Image not found!")
            return
        }
        didChangeImage = true
        imageImageView.image = selectedImage
    }
    
    
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descriptionTextView.textColor == UIColor.lightGray {
            descriptionTextView.text = nil
            descriptionTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descriptionTextView.text.isEmpty {
            descriptionTextView.text = "Description..."
            descriptionTextView.textColor = UIColor.lightGray
        } else {
            product.description = descriptionTextView.text
        }
    }
    
    
    @IBAction func deleteItem(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure you want to delete the product?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No Go Back!", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes Delete this product.", style: .destructive, handler: { action in
            Main.shared.deleteProductWithOutReload(product: self.product)
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(alert, animated: true)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tags" {
            let vc = segue.destination as? TagSelectionView
            vc?.product = product
            vc?.DetailViewInstance = self
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
 

    
    
}
