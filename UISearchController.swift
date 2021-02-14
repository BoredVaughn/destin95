import UIKit

 class CannabisViewController: UIViewController, CannabisFilterButtonDelegate {
    
    // MARK: - Outlets
    lazy var tableView: UITableView = {
        // MARK: DataSource/Delegate
        $0.dataSource = self
        $0.delegate = self
        $0.register(FilterStrainsButtonTableViewCell.self, forCellReuseIdentifier: "FilterStrainsButtonTableViewCell")
        $0.register(AllStrainsTextTableViewCell.self, forCellReuseIdentifier: "AllStrainsTextTableViewCell")
        $0.register(CannabisListTableViewCell.self, forCellReuseIdentifier: "CannabisListTableViewCell")
        return $0
    }(UITableView(frame: .zero, style: .plain))
    
    // MARK: - Properties
    var cannabisList = [Cannabis]()
    var selectedStrain: Cannabis?
    var selectedCheckinStrain: Strains?
    var cannabisDetailViewController: CannabisDetailsViewController? = nil
    var checkinViewController: CheckinViewController? = nil
    let walkedThrough = UserDefaults.standard.bool(forKey: "walkthrough")
    
    var sativaIsActive = false
    var hybridIsActive = false
    var indicaIsActive = false
    var normalIsActive = true
    
    // Search
    private lazy var searchController: UISearchController = {
        $0.searchResultsUpdater = self
        $0.delegate = self
        $0.searchBar.delegate = self
        $0.obscuresBackgroundDuringPresentation = false
        $0.hidesNavigationBarDuringPresentation = false
        $0.searchBar.backgroundColor = UIColor(rgb: 0x00ffcc)
        $0.searchBar.tintColor = .systemBlue
        return $0
    }(UISearchController(searchResultsController: nil))
    
    var isSearchBarEmpty: Bool { return searchController.searchBar.text?.isEmpty ?? true }
    var filteredStrains = [Cannabis]()
    var isFiltering: Bool { return searchController.isActive && !isSearchBarEmpty }
    
    
    // API
    var cannabisAPI: Cannabis?
    let rest = APIClient()
    var currentPage = 1
    var isLoading = false
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePage()

        
        // MARK: Self sizing table view cell
        tableView.estimatedRowHeight = CGFloat(88.0)
        tableView.rowHeight = UITableView.automaticDimension
        
        
        // Removes default lines from table views
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        
        
        // Dismiss keyboard
        // hideKeyboardWhenTappedAround()
        keyboardIsPerfect()
    
        // MARK: Navigation: Puffd logo in center
        let puffdLogoHeader = UIImageView(image: UIImage(named: "puffdLogoHeader"))
        self.navigationItem.titleView = puffdLogoHeader
        
        
        // MARK: - API
        getCannabisList()
        
        
        // MARK: WalkThrough
        // If walkThrough has not been dismissed or completed
        if !walkedThrough {
            // Set WalkThroughViewController
            let walkThroughVC = WalkThroughViewController()
            // Present
            present(walkThroughVC, animated: true)
            
        }
        
        
        // MARK: Search bar controller
        searchController.searchResultsUpdater = self
        // searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for a strain!"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
         
    }
    

    // Configure TableView
    func configurePage() {
        // Configure Search
        // Configure Tableview
        view.addSubview(tableView)
        tableView.anchor(top: view.topAnchor, left: view.leftAnchor,
                         bottom: view.bottomAnchor, right: view.rightAnchor)
    }
 
}



// MARK: - TableView
extension CannabisViewController: UITableViewDelegate, UITableViewDataSource {
    // HeightForRowAt
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 100
        case 1:
            return 45
        default:
            return 150
        }
    }
    
    // numberOfSections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    
    // numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        default:
            if isFiltering && filteredStrains.count == 0 {
                return 0
            }
            if isFiltering && filteredStrains.count >= 1 {
                return filteredStrains.count
            }
            return cannabisList.count
        }
    }
    

    // cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterStrainsButtonTableViewCell") as! FilterStrainsButtonTableViewCell
            // Delegates
            cell.sativaButtonDelegate = self
            cell.hybridButtonDelegate = self
            cell.indicaButtonDelegate = self
            cell.normalButtonDelegate = self
            
            cell.selectionStyle = .none
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AllStrainsTextTableViewCell") as! AllStrainsTextTableViewCell
            cell.selectionStyle = .none
            return cell
        default:
            // cellForRowAt
            let cell = tableView.dequeueReusableCell(withIdentifier: "CannabisListTableViewCell") as! CannabisListTableViewCell
            
            if isFiltering && filteredStrains.count == 0 {
                cell.strainsImage.image = UIImage(named: "CannabisSativaProduct")
                cell.heritageLabel.text = "Bummer, we know!"
                cell.strainsLabel.text = "Uh oh"
                cell.strainsDescription.text = "That strain does not seem to exist yet, please let us know by emailing info@puffd.io"

            }
            
            if isFiltering && filteredStrains.count >= 1 {
                let cannabis = filteredStrains[indexPath.row]
                
                cell.selectionStyle = .none
                
                cell.strainsLabel.text = cannabis.strains
                cell.thcPercentageLabel.text = cannabis.thcPercentage
                cell.strainsDescription.attributedText = cannabis.description.htmlToAttributedString
                
                switch cannabis.heritage {
                case "Sativa":
                    cell.strainsImage.image = UIImage(named: "CannabisSativaProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0xF7B500)
                    cell.heritageLabel.text = "Sativa"
                case "Hybrid":
                    cell.strainsImage.image = UIImage(named: "CannabisHybridProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0x6DD400)
                    cell.heritageLabel.text = "Hybrid"
                case "Indica":
                    cell.strainsImage.image = UIImage(named: "CannabisIndicaProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0x32C5FF)
                    cell.heritageLabel.text = "Indica"
                default:
                    cell.strainsImage.image = UIImage(named: "CannabisSativaProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0xF7B500)
                    cell.heritageLabel.text = "Sativa"
                }
                
            } else {
                let cannabis = cannabisList[indexPath.row]
                
                cell.selectionStyle = .none
                
                cell.strainsLabel.text = cannabis.strains
                cell.thcPercentageLabel.text = cannabis.thcPercentage
                cell.strainsDescription.attributedText = cannabis.description.htmlToAttributedString
                
                switch cannabis.heritage {
                case "Sativa":
                    cell.strainsImage.image = UIImage(named: "CannabisSativaProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0xF7B500)
                    cell.heritageLabel.text = "Sativa"
                case "Hybrid":
                    cell.strainsImage.image = UIImage(named: "CannabisHybridProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0x6DD400)
                    cell.heritageLabel.text = "Hybrid"
                case "Indica":
                    cell.strainsImage.image = UIImage(named: "CannabisIndicaProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0x32C5FF)
                    cell.heritageLabel.text = "Indica"
                default:
                    cell.strainsImage.image = UIImage(named: "CannabisSativaProduct")
                    // cell.sideBannerView.backgroundColor = UIColor(rgb: 0xF7B500)
                    cell.heritageLabel.text = "Sativa"
                }
                
            }
            return cell
        }
    }
}


// MARK: - Segue
extension CannabisViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFiltering {
            self.selectedStrain = filteredStrains[indexPath.row]
            let cannabisDetailsViewController = CannabisDetailsViewController()
            cannabisDetailsViewController.selectedStrain = filteredStrains[indexPath.row]
              
            navigationController?.pushViewController(cannabisDetailsViewController, animated: true)
            
        } else {
            self.selectedStrain = cannabisList[indexPath.row]
            let cannabisDetailsViewController = CannabisDetailsViewController()
            cannabisDetailsViewController.selectedStrain = cannabisList[indexPath.row]
            
            navigationController?.pushViewController(cannabisDetailsViewController, animated: true)
        }
    }
}


// MARK: - SearchController
extension CannabisViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {}
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {}
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {}
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {}
        func updateSearchResults(for searchController: UISearchController) {}
        let searchBar = searchController.searchBar
//        let userSearch = searchBar.text!.trimmingCharacters(in: .whitespaces)
        guard let userSearch = searchBar.text?.replacingOccurrences(of: " ", with: "") else { return }
        
        search(searchText: userSearch)
    }
    
    
    func search(searchText: String) {
        // URL
        guard let url = URL(string: APIClient.shared.cannabisURL) else { return }
        
        rest.urlQueryParameters.add(value: searchText, forKey: "search")
        
        rest.makeRequest(toURL: url, withHttpMethod: .get) { (results) in
            // Response
            print("\n\n### Response HTTP Headers ###\n")
            if let response = results.response {
                for (key, value) in response.headers.allValues() {
                    print(key, value)
                }
            }
            
            // Error
            if let error = results.error {
                print(String(describing: error))
                
            }
            
            print("\n\n### End Response HTTP Headers ###\n")
            
            // Data
            if let data = results.data {
                let decoder = JSONDecoder()
                
                guard let item = try? decoder.decode(CannabisResults.self, from: data) else { return }
                
                self.filteredStrains = item.results
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
}


// MARK: - Pagination
extension CannabisViewController {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if (indexPath.row == cannabisList.count - 1) {

            if sativaIsActive == true {
                self.currentPage += 1
                getStrainByFiltered(strainURL: APIClient.shared.cannabisSativaURL)
                
            } else if hybridIsActive == true {
                self.currentPage += 1
                getStrainByFiltered(strainURL: APIClient.shared.cannabisHybridURL)
                
            } else if indicaIsActive == true {
                self.currentPage += 1
                getStrainByFiltered(strainURL: APIClient.shared.cannabisIndicaURL)
                
            } else if normalIsActive == true {
                self.currentPage += 1
                getCannabisList()
            }
            
        }
    }
}

 
 
 

 

// MARK: - APIFunctions
extension CannabisViewController {
    func getCannabisList() {
        // URL
        guard let url = URL(string: APIClient.shared.cannabisURL) else { return }
        
        // HTTP parameters
        rest.urlQueryParameters.add(value: String(currentPage), forKey: "page")
        
        rest.makeRequest(toURL: url, withHttpMethod: .get) { (results) in
            // Response
            print("\n### Response Headers ###\n")
            if let response = results.response {
                for (key, value) in response.headers.allValues() {
                    print(key, value)
                }
                
            }
            
            if let error = results.error {
                print(error.localizedDescription)
            }
            
            // Print URL to confirm location during development
            print(APIClient.shared.cannabisURL)
            // Print HTTP status code
            print("HTTP status code:", results.response?.httpStatusCode ?? 0)
            // Response header
            print("\n### End Response Headers ###\n")
            
            // Data
            if let data = results.data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                guard let item = try? decoder.decode(CannabisResults.self, from: data) else { return }
                 print(item.results)
                
                self.cannabisList.append(contentsOf: item.results)
                
                DispatchQueue.main.async {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: "CannabisListTableViewCell") as! CannabisListTableViewCell
                    cell.strainsLabel.text = self.cannabisAPI?.strains
                    cell.thcPercentageLabel.text = self.cannabisAPI?.thcPercentage
                    cell.strainsDescription.text = self.cannabisAPI?.description
                    self.tableView.reloadData()
                }
            }

        }
    }
    
    func getStrainByFiltered(strainURL: String) {
         // URL
         guard let url = URL(string: strainURL) else { return }
         
         // HTTP parameters
         rest.urlQueryParameters.add(value: String(currentPage), forKey: "page")
         
         rest.makeRequest(toURL: url, withHttpMethod: .get) { (results) in
             // Response
             print("\n### Response Headers ###\n")
             if let response = results.response {
                 for (key, value) in response.headers.allValues() {
                     print(key, value)
                 }
             }
             
             // Print URL to confirm location during development
             print(url)
             // Print HTTP status code
             print("HTTP status code:", results.response?.httpStatusCode ?? 0)
             // Response header
             print("\n### End Response Headers ###\n")
             
             // Data
             if let data = results.data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                 
                guard let item = try? decoder.decode(CannabisResults.self, from: data) else { return }
                
                // Set normalIsActive to false
                self.normalIsActive = false
                
                /// TODO: Turn if statement into a function using bool param
                
                // If statement to control filter buttons
                if strainURL == APIClient.shared.cannabisSativaURL {
                    // Sativa
                    // SativaIsActive
                    self.sativaIsActive = true
                    // Current Page if Statement
                    if self.currentPage == 1 {
                        // Set returned results to cannabisList
                        self.cannabisList = item.results
                    } else {
                        // Else append
                        self.cannabisList.append(contentsOf: item.results)
                    }
                    
                } else if strainURL == APIClient.shared.cannabisHybridURL {
                    // Hybrid
                    // HybridIsActive
                    self.hybridIsActive = true
                    // Current Page if Statement
                    if self.currentPage == 1 {
                        // Set returned results to cannabisList
                        self.cannabisList = item.results
                    } else {
                        self.cannabisList.append(contentsOf: item.results)
                    }
            
                } else if strainURL == APIClient.shared.cannabisIndicaURL {
                    // Indica
                    // IndicaIsActive
                    self.indicaIsActive = true
                    // Current Page if Statement
                    if self.currentPage == 1 {
                        // Set returned results to cannabisList
                        self.cannabisList = item.results
                    } else {
                        // Else append
                        self.cannabisList.append(contentsOf: item.results)
                    }
            
                } else if strainURL == APIClient.shared.cannabisURL {
                    // Normal
                    // NormalIsActive
                    self.normalIsActive = true
                    // Current Page if Statement
                    if self.currentPage == 1 {
                        // Set returned results to cannabisList
                        self.cannabisList = item.results
                        } else {
                        // Else append
                        self.cannabisList.append(contentsOf: item.results)
                    }
                 
                    DispatchQueue.main.async {
                        let cell = self.tableView.dequeueReusableCell(withIdentifier: "CannabisListTableViewCell") as! CannabisListTableViewCell
                        cell.strainsLabel.text = self.cannabisAPI?.strains
                        cell.strainsDescription.text = self.cannabisAPI?.description
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}
