//
//  VC+TableViewExtension.swift
//  ContactsDemo
//
//  Created by Alex Ackerman on 10/15/16.
//  Copyright © 2016 Darkhonor Development. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

extension ViewController: UITableViewDataSource {

    // MARK: -
    // MARK: Table View Data Source Methods
    /// Optional
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// Required
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    internal func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        cell.textLabel?.text = CNContactFormatter.string(from: contacts[indexPath.row], style: CNContactFormatterStyle.fullName)
        cell.detailTextLabel?.text = contacts[indexPath.row].jobTitle
    }
    
    /// Required
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.ContactCell, for: indexPath)

        // Configure Cell
        configureCell(cell: cell, indexPath: indexPath)

        return cell
    }

}

//MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = CNContactViewController(for: contacts[indexPath.row])
        controller.contactStore = CNContactStore()
        controller.allowsEditing = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
}
