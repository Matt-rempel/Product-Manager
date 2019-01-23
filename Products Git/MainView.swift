//
//  MainView.swift
//  
//
//  Created by Matthew Rempel on 2019-01-18.
//

import UIKit
import Firebase
import FirebaseUI
import NotificationBannerSwift

class MainView: UITableViewController, UISearchBarDelegate, UIViewControllerPreviewingDelegate {

    var ref: DatabaseReference!
    var storage: Storage!
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchTerm = ""
    
    var allShopItems:[shopItem]!
    var shopItems:[shopItem]! = []
    
    var shopItemToSend:shopItem!
    
    var tags = ["All", "Featured", "Additives and Supplements", "Media", "Fish and Coral", "Lighting", "Maintenance", "Medications", "Miscellaneous", "Salt Mix", "Equipment"]
    var scopes = ["A to Z", "Z to A", "High to Low", "Low to High"]
    var selectedTag = "Featured"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
        
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        //Setup Search Controller
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self
        
        //          WHAT EVER YOU DO DO NOT DELETE THE LINE BELOW
        self.searchController.hidesNavigationBarDuringPresentation = false
        //        THE LINE ABOVE THIS ONE IS VERY VERY VERY VERY IMPORTANT TO A UI UIX BUG THAT TOOK LIKE 2 MONTHS TO FIX
        
        self.searchController.searchBar.placeholder = "Title, Description, etc..."
        self.searchController.searchBar.barStyle = .default
        self.searchController.searchBar.selectedScopeButtonIndex = 0
        self.searchController.searchBar.showsScopeBar = false
        self.searchController.searchBar.scopeButtonTitles = scopes
        self.searchController.searchBar.delegate = self
        
        self.definesPresentationContext = true
        self.providesPresentationContextTransitionStyle = false
        self.navigationItem.searchController = searchController
        
        
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.rowHeight = 80.0
        
        if(traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
        
        // Do any additional setup after loading the view.
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: UIControl.Event.valueChanged)
        self.tableView.refreshControl = refreshControl
        
        ref = Main.shared.ref
        storage = Main.shared.storage
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            pullFirebase()
        }else{
            print("Internet Connection not Available!")
            let banner = NotificationBanner(title: "No Internet", subtitle: "Check that you have access to the internet.", style: .danger)
            banner.show()
        }
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return shopItems.count
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MainViewTableViewCell
        let cellItem = shopItems[indexPath.row]
        // Configure the cell...
     
        cell.product = cellItem
        cell.MainViewInstance = self
        
        cell.itemTitleLabel.text = cellItem.title
        
        var priceStr = "$\(Double(cellItem.price/100).rounded(toPlaces: 2))"
        if priceStr.hasSuffix(".0") { // true
            priceStr = priceStr + "0"
        }
        cell.itemPriceLabel.text = priceStr
        
        let image = UIImage(named: "star")?.withRenderingMode(.alwaysTemplate)
        cell.starButton.setImage(image, for: .normal)
        if cellItem.star {
            cell.starButton.tintColor = Main.tintColor
        } else {
            cell.starButton.tintColor = .gray
        }
        
        // Create a reference with an initial file path and name
        let pathReference = storage.reference(withPath: cellItem.image)
        let imageView: UIImageView = cell.itemImageView
        let placeholderImage = UIImage(named: "placeholder.jpg")
        imageView.sd_setImage(with: pathReference, placeholderImage: placeholderImage)
        
        
        return cell
     }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shopItemToSend = shopItems[indexPath.row]
        performSegue(withIdentifier: "view", sender: nil)
    }


    // MARK: - 3D Touch Stuff

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) as? MainViewTableViewCell else { return nil }
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "Preview") as? Preview else { return nil }
        
        shopItemToSend = shopItems[indexPath.row]
        
        detailVC.productImage = cell.itemImageView.image
        detailVC.product = shopItemToSend
        detailVC.MainViewInstance = self
        
        detailVC.preferredContentSize = CGSize(width: 0.0, height: 625)
        
        previewingContext.sourceRect = cell.frame
        
        return detailVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "DetailView") as? DetailView
        detailVC?.product = shopItemToSend
        detailVC?.isAddingNew = false
        
        show(detailVC!, sender: self)
    }
    
    // MARK: - UI helper methods
    
    @objc func refresh() {
        pullFirebase()
    }
    
    public func pullFirebase() {
        let banner = NotificationBanner(title: "Updating", subtitle: "Checking for new products!", style: .success)
        banner.show()
        
        ref.child("shop_items").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if value != nil{
                self.shopItems.removeAll()
                for i in value?.allKeys ?? [""]  {
                    let currentFirebaseItem:[String : Any] = value![i] as! [String : Any]
                    
                    let itemTitle = currentFirebaseItem["title"] as? String ?? ""
                    let itemDesc = currentFirebaseItem["description"] as? String  ?? ""
                    let itemPrice = currentFirebaseItem["price"] as? Float ?? 0.0
                    let itemImage = currentFirebaseItem["image"] as? String ?? ""
                    let itemID = currentFirebaseItem["id"] as? Int ?? 0
                    let itemTags = currentFirebaseItem["tags"] as? [String] ?? []
                    let itemQuantity = currentFirebaseItem["quantity"] as? Int ?? 1
                    let itemStar = currentFirebaseItem["star"] as? Bool ?? false
                    
                    let newItem = shopItem()
                    newItem.title = itemTitle
                    newItem.description = itemDesc
                    newItem.price = itemPrice
                    newItem.image = itemImage
                    newItem.productID = itemID
                    newItem.tags = itemTags
                    newItem.quantity = itemQuantity
                    newItem.star = itemStar
                    newItem.firebaseRoot = i as? String ?? ""
                    
                    self.shopItems.append(newItem)
                }
                
                self.allShopItems = self.shopItems
                self.sortShopItemsBy(type: "A to Z")
                self.filterContentForSearchText(self.searchTerm, scope: self.selectedTag)

                // Fake Delay lol
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // change to desired number of seconds
                    // Your code with delay
                    banner.dismiss()
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func didPressSortButton(_ sender: Any) {
        let alert = UIAlertController(title: "Categories", message: "Select a Category", preferredStyle: .actionSheet)
        
        for i in tags {
            alert.addAction(UIAlertAction(title: i, style: .default, handler: { action in self.filterContentForSearchText(self.searchTerm, scope: i)}))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = sender as? UIBarButtonItem
        }
        
        self.present(alert, animated: true)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "view" {
            let vc = segue.destination as! DetailView
            vc.product = shopItemToSend
            vc.isAddingNew = false
        } else if segue.identifier == "add" {
            let vc = segue.destination as! DetailView
            vc.product = shopItem()
            vc.product.star = false
            vc.isAddingNew = true
        }
    }
    
    // MARK: - UI helper methods
    func sortShopItemsBy(type: String) {
        
        switch type {
        case "A to Z":
            self.shopItems = self.shopItems.sorted(by: { $0.title.lowercased() < $1.title.lowercased() })
        case "Z to A":
            self.shopItems = self.shopItems.sorted(by: { $0.title.lowercased() > $1.title.lowercased() })
        case "Low to High":
            self.shopItems = self.shopItems.sorted(by: { $0.price < $1.price })
        case "High to Low":
            self.shopItems = self.shopItems.sorted(by: { $0.price > $1.price })
        default:
            print("sort type not found!!: \(type)")
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: - SearchBar
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print(selectedScope)
        self.sortShopItemsBy(type: scopes[selectedScope])
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.text = searchTerm
        
        //Show Cancel
        searchBar.setShowsCancelButton(true, animated: true)
        //        searchBar.tintColor = .de
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        //Filter function
        //        self.filterFunction(searchText: searchText)
        searchTerm = searchBar.text ?? ""
        
        self.filterContentForSearchText(searchText)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        print("search button clicked")
        //Hide Cancel
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        
        searchBar.text = searchTerm
        
        guard let term = searchBar.text , term.isEmpty == false else {
            
            //Notification "White spaces are not permitted"
            return
        }
        
        searchTerm = term
        
        //Filter function
        self.filterContentForSearchText(term)
        
    }
    
    //Filter function
    //        self.filterFunction(searchText: term)
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("Text ended editing")
        searchBar.text = searchTerm
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        print("did press cancel button")
        searchTerm = ""
        
        //Hide Cancel
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = String()
        searchBar.resignFirstResponder()
        
        //Filter function
        self.filterContentForSearchText(searchBar.text ?? "")
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "") {
        print(selectedTag)
        selectedTag = (scope == "" ? selectedTag : scope)
        title = selectedTag
        shopItems = allShopItems
        if searchText == "" {
            if selectedTag == "Featured" {
                var checkFaves:[shopItem] = shopItems
                
                checkFaves = shopItems.filter({(item : shopItem) -> Bool in
                    return item.star == true
                })
                
                shopItems = checkFaves
            }  else if selectedTag == "All" {
                // Reset Filter
                shopItems = allShopItems
            } else {
                var checkTags:[shopItem] = shopItems
                
                print(selectedTag)
                
                checkTags = shopItems.filter({(item : shopItem) -> Bool in
                    return item.tags.contains(selectedTag)
                })
                
                shopItems = checkTags
            }
        } else {
            
            var checkTags:[shopItem] = shopItems
            print(selectedTag)
            
            
            
            if selectedTag != "All" {
                if selectedTag == "Featured" {
                    checkTags = shopItems.filter({(item : shopItem) -> Bool in
//                        print(item.star)
                        return item.star == true
                    })
                    shopItems = checkTags
                } else {
                    checkTags = shopItems.filter({(item : shopItem) -> Bool in
//                        print(item.tags)
                        return item.tags.contains(selectedTag)
                    })
                }
            }
            
            let checkTitle = checkTags.filter({( item : shopItem) -> Bool in
                return item.title.lowercased().contains(searchText.lowercased())
            })
            let checkDescription = checkTags.filter({( item : shopItem) -> Bool in
                return item.description.lowercased().contains(searchText.lowercased())
            })
            
            
            shopItems = checkTitle
            shopItems += checkDescription
            
            if shopItems == nil {
                shopItems = []
            }
            
            shopItems.removeDuplicates()
            
        }
        sortShopItemsBy(type: "A to Z")
        
        tableView.reloadData()
    }
}

extension MainView: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        // TODO
        print("updateSearchResults()")
    }
}
