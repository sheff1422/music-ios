//
//  SettingsList.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/15/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit

class SettingsSort: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sortirovka = [NSLocalizedString("byDateAdded", comment: "By date added"), NSLocalizedString("byDuration", comment: "By duration"), NSLocalizedString("byPopularity", comment: "By popularity")]
    var tracks = NSLocalizedString("tracks", comment: "Tracks") as String
    var counts = [String]()
    var settingType: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        counts = ["30 \(tracks)", "50 \(tracks)", "100 \(tracks)", "200 \(tracks)", "300 \(tracks)"]
        self.preferredContentSize = CGSize(width: 320,height: 150)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier:"Cell")
    }
}

extension SettingsSort: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = 0
        switch settingType {
        case 0:
            return sortirovka.count
        case 1:
            return counts.count
            
        default:break
        }
        return result
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for:indexPath) 
        if(settingType == 0){
            
            let sort = UserDefaults.standard.integer(forKey: "sort")
            cell.textLabel?.text = sortirovka[indexPath.row]
            cell.accessoryType = (sort == row ?
                .checkmark :
                .none)
            return cell
        }else{
            let count = UserDefaults.standard.integer(forKey: "count")
            cell.textLabel?.text = counts[indexPath.row]
            cell.accessoryType = (count == row ?
                .checkmark :
                .none)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        switch section {
        case 0:
            if settingType == 0 {
                UserDefaults.standard.set(row, forKey:"sort")
                tableView.reloadData()
            }
            if settingType == 1 {
                UserDefaults.standard.set(row, forKey:"count")
                tableView.reloadData()
            }
        default:break
        }
    }
}
