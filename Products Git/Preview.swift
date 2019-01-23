//
//  Preview.swift
//  FirebaseAuth
//
//  Created by Matthew Rempel on 2019-01-22.
//

import UIKit

class Preview: UIViewController {

    @IBOutlet var productImageView: UIImageView!
    @IBOutlet var productTitle: UILabel!
    @IBOutlet var productPrice: UILabel!
    @IBOutlet var productQuantityLabel: UILabel!
    @IBOutlet var productIDLabel: UILabel!
    
    var productImage:UIImage!
    var product:shopItem!
    var MainViewInstance: MainView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productTitle.text = product.title
        productPrice.text = Main.shared.getPrettyPrice(inputPrice: product.price)
        productImageView.image = productImage
        productQuantityLabel.text = "Quantity: \(product.quantity!)"
        productIDLabel.text = "ID: \(product.productID!)"

    }
    
    // MARK: - 3D Touch Stuff

    override var previewActionItems: [UIPreviewActionItem] {
        var starAction:UIPreviewAction!
        
        starAction = UIPreviewAction(title: starButtonTitle(), style: .default) {
            [weak self] (action, controller) in
            self?.handle(action: action, and: controller)
        }
        
        let deleteAction = UIPreviewAction(title: "Delete", style: .destructive) {
            [weak self] (action, controller) in
            self?.handle(action: action, and: controller)
        }
        return [starAction, deleteAction]
    }
    
    private func handle(action: UIPreviewAction, and controller: UIViewController) {
        print(action.title)
        print(controller)
        if action.title == "Star" || action.title == "Unstar" {
            Main.shared.toggleFaveProduct(product: product, MainViewInstance: MainViewInstance)
        } else if action.title == "Delete" {
            Main.shared.deleteProduct(product: product, MainViewInstance: MainViewInstance)
        }
        
    }
    
    
    // MARK: - UI helper methods
    
    func starButtonTitle() -> String {
        guard let shopItem = product
            else { preconditionFailure("Expected a color item") }
        
        return shopItem.star ? "Unstar" : "Star"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
