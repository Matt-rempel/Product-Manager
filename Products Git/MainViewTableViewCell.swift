//
//  MainViewTableViewCell.swift
//  
//
//  Created by Matthew Rempel on 2019-01-18.
//

import UIKit

class MainViewTableViewCell: UITableViewCell {

    @IBOutlet var itemTitleLabel: UILabel!
    @IBOutlet var itemPriceLabel: UILabel!
    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var starButton: UIButton!
    
    var product:shopItem!
    var MainViewInstance: MainView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func didPressStarButton(_ sender: Any) {
        Main.shared.toggleFaveProduct(product: product, MainViewInstance: MainViewInstance)
    }
    
}
