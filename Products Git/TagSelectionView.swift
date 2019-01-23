//
//  TagSelectionView.swift
//  Products
//
//  Created by Matthew Rempel on 2019-01-20.
//  Copyright © 2019 Matthew Rempel. All rights reserved.
//

import UIKit

class TagSelectionView: UITableViewController {

    var tags = ["", "Additives and Supplements", "Media", "Fish and Coral", "Lighting", "Maintenance", "Medications", "Miscellaneous", "Salt Mix", "Equipment"]
    var product:shopItem!
    var DetailViewInstance:DetailView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let navBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        navBar.barTintColor = .white
        self.view.addSubview(navBar);

        let navItem = UINavigationItem(title: "Tags");
        let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: nil, action: #selector(SaveTags));
        navItem.rightBarButtonItem = doneItem;
        
        navBar.setItems([navItem], animated: false);
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tags.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
        let cellTag = tags[indexPath.row]
        cell.textLabel?.text = cellTag
        cell.accessoryType = (product.tags.contains(cellTag) ? .checkmark : .none)
        
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTag = tags[indexPath.row]
        print("Selected: \(selectedTag)")
        if product.tags.contains(selectedTag) {
            product.tags = product.tags.filter { $0 != selectedTag }
        } else {
            product.tags.append(selectedTag)
        }
        
        DetailViewInstance.product.tags = product.tags
        DetailViewInstance.loadTags()
        tableView.reloadData()
        
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? DetailView
        vc?.product = product
        vc?.loadTags()
        
    }

    @objc func SaveTags() {
        self.dismiss(animated: true, completion: nil)
    }
}
