//
//  VC+TableViewExtension.swift
//  ContactsDemo
//
//  Created by Alex Ackerman on 10/15/16.
//  Copyright © 2016 Darkhonor Development. All rights reserved.
//

import UIKit
import Contacts

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: -
    // MARK: Table View Data Source Methods
    /// Optional
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// Required
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if let sections = self.frc?.sections {
//            let sectionInfo = sections[section]
//            return sectionInfo.numberOfObjects
//        }
//        return self.frc?.fetchedObjects?.count ?? 0
        return contacts.count
    }
    
    internal func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
//        if let site: DkSite = self.frc?.object(at: indexPath) {
//            cell.textLabel?.text = site.name
//        } else {
//            cell.textLabel?.text = "<Missing Name>"
//        }
        cell.textLabel?.text = CNContactFormatter.string(from: contacts[indexPath.row], style: CNContactFormatterStyle.fullName)
        cell.detailTextLabel?.text = contacts[indexPath.row].jobTitle
    }
    
    /// Required
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.ContactCell, for: indexPath)
        
        // Configure Cell
        cell.accessoryType = .detailDisclosureButton
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }

}
