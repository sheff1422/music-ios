//
//  Settings.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/15/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import Foundation
import UIKit

class SettingsVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sectionNames = [NSLocalizedString("search", comment: "Search"), NSLocalizedString("count", comment: "Count"), NSLocalizedString("performerOnly", comment: "performerOnly"), NSLocalizedString("popularMusic", comment: "Popular Music"), "Version"]
    var sectionData = [[NSLocalizedString("sort", comment: "Sort")],[NSLocalizedString("countText", comment: "Count text")], [NSLocalizedString("performerOnlyText", comment: "performerOnly")],[NSLocalizedString("popularMusicText", comment: "Popular music text")],["music-ios v1.0.1 "]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "settingsList"){
            
        }
    }
    
    @IBAction func switchChanged(_ sender: AnyObject) {

        let sw = sender as! UISwitch
        let view = sw.superview
        let cell = view?.superview as! SettingsCellWithSwitch
        
        let indexPath = self.tableView.indexPath(for: cell)
        if indexPath!.section == 2{
            UserDefaults.standard.set(sw.isOn, forKey: "performer_only")
        }
        if indexPath!.section == 3{
            UserDefaults.standard.set(sw.isOn, forKey: "popular_songs")
        }
    }
    
}

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionNames.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionData[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        
        if(section == 0 || section == 1)
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SettingsCell
            let s = self.sectionData[indexPath.section][indexPath.row] as String
            cell.title.text = "\(s)"
            return cell
        }
        else if(section == 2 || section == 3){
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellWithSwitch", for: indexPath) as! SettingsCellWithSwitch
            let s = self.sectionData[indexPath.section][indexPath.row] as String
            cell.title.text = s
            if section == 2 {
                let switchBtn = UserDefaults.standard.bool(forKey: "performer_only")
                cell.switchBtn.isOn = switchBtn
            }
            if section == 3 {
                let switchBtn = UserDefaults.standard.bool(forKey: "popular_songs")
                cell.switchBtn.isOn = switchBtn
            }
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellUnSegue", for: indexPath) as! SettingsCellUnSegue
            let s = self.sectionData[indexPath.section][indexPath.row] as String
            cell.title.text = s
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !self.sectionNames[section].isEmpty {
            return self.sectionNames[section] as String
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let settingsSort = self.storyboard?.instantiateViewController(withIdentifier: "SettingsList") as! SettingsSort
        switch indexPath.section {
        case 0 :
            settingsSort.settingType = indexPath.section
            self.navigationController?.pushViewController(settingsSort, animated: true)
        case 1:
            settingsSort.settingType = indexPath.section
            self.navigationController?.pushViewController(settingsSort, animated: true)
            
        default: break
        }
    }

}

class SettingsCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}

class SettingsCellWithSwitch: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var switchBtn: UISwitch!
}

class SettingsCellUnSegue: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}

