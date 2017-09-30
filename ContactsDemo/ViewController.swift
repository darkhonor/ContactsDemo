//
//  ViewController.swift
//  ContactsDemo
//
//  Created by Alex Ackerman on 10/13/16.
//  Copyright © 2016 Darkhonor Development. All rights reserved.
//

import UIKit
import ContactsUI

class ViewController: UIViewController, CNContactPickerDelegate, CNContactViewControllerDelegate {

    static let ContactCell = "ContactCell"
    static let GroupNameDefault = "Some Group"

    var contacts: [CNContact] = [CNContact]()

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: .insertContact, name: NSNotification.Name(rawValue: "addNewContact"), object: nil)
        self.loadContacts()
    }

    private func loadContacts() {
        let store: CNContactStore = CNContactStore()
        // Request access to the Contacts on the device
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            self.manageGroups()
            self.contacts = self.loadContactsFromStore()
        case .notDetermined:
            store.requestAccess(for: .contacts, completionHandler: {succeeded, err in guard err == nil && succeeded else {
                return
                }
                self.manageGroups()
                self.contacts = self.loadContactsFromStore()
            })
        default:
            NSLog("ERROR: Application is not authorized to access user Contacts.  This is required for application use.")
        }
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func enumContainers() {
        let store: CNContactStore = CNContactStore()
        print("Contact Store Default Container: \(store.defaultContainerIdentifier())")
        do {
            let containers = try store.containers(matching: nil)
            print("Found \(containers.count) Containers in the Contacts Store")
            print("Name: \(containers.first?.name)")
            print("Type: \(containers.first?.type)")
        } catch let err {
            print("Error Caught: \(err)")
        }
    }

    func manageGroups() {
        print("Grabbing groups in current container")
        let store: CNContactStore = CNContactStore()
        do {
            let allGroups = try store.groups(matching: nil)
            let filteredGroups = allGroups.filter { $0.name == self.getGroupName() }
            print("Groups filtered")

            if filteredGroups.count == 1 {
                print("\(self.getGroupName()) group exists")
            } else {
                let vtGroup = CNMutableGroup()
                vtGroup.name = self.getGroupName()
                let request = CNSaveRequest()
                request.add(vtGroup, toContainerWithIdentifier: nil)
                do {
                    try store.execute(request)
                    print("Group Added")
                } catch let e {
                    print("Error saving Group: \(e)")
                }
            }
        } catch let err {
            print("Error Caught: \(err)")
        }
    }

    private func loadContactsFromStore() -> [CNContact] {
        let store: CNContactStore = CNContactStore()
        guard let vtGroup = self.getContactGroup() else {
            NSLog("ERROR: Unable to load \(self.getGroupName()) Group")
            return []
        }
        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: vtGroup.identifier)
        let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactViewController.descriptorForRequiredKeys()]
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            return contacts
        } catch let error {
            NSLog("ERROR Retrieving Contacts: \(error)")
            return []
        }
    }

    private func getContactGroup() -> CNGroup? {
        let store: CNContactStore = CNContactStore()
        do {
            let allGroups = try store.groups(matching: nil)
            let filteredGroups = allGroups.filter { $0.name == self.getGroupName() }

            guard let vtGroup = filteredGroups.first else {
                NSLog("No \(self.getGroupName()) group")
                return nil
            }
            return vtGroup
        } catch let err {
            NSLog("Error caught grabbing Group: \(err)")
            return nil
        }
    }

    private func getGroupName() -> String {
        let defaults = UserDefaults.standard
        let cnGroupName = defaults.string(forKey: "CNGroupName")
        if cnGroupName != nil && cnGroupName!.isEmpty {
            return cnGroupName!
        } else {
            return ViewController.GroupNameDefault
        }
    }

    @IBAction func addExisting(_ sender: AnyObject) {
        let contactPickerViewController = CNContactPickerViewController()
        contactPickerViewController.delegate = self
        present(contactPickerViewController, animated: true, completion: nil)
    }

    @IBAction func addNew(_ sender: AnyObject) {
        let cnViewController = CNContactViewController(forNewContact: nil)
        cnViewController.contactStore = CNContactStore()
        cnViewController.delegate = self
        self.navigationController?.pushViewController(cnViewController, animated: true)
    }

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if contact != nil {
            updateGroup(contact: contact!)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addNewContact"), object: nil, userInfo: ["contactToAdd": contact!])
            DispatchQueue.main.async (execute: { () -> Void in
                self.tableView.reloadData()
            })
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        updateGroup(contact: contact)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addNewContact"), object: nil, userInfo: ["contactToAdd": contact])
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
    }

    func updateGroup(contact: CNContact) {
        let store: CNContactStore = CNContactStore()
        let request = CNSaveRequest()
        guard let group = getContactGroup() else {
            NSLog("Error: Unable to get \(self.getGroupName()) Group")
            return
        }
        request.addMember(contact, to: group)
        do {
            try store.execute(request)
            print("Successfully added \(contact.familyName) to \(group.name)")
        } catch let err {
            print("Error Updating Group: \(err)")
        }
    }

    internal func insertNewObject(sender: NSNotification) {
        if let contact = sender.userInfo?["contactToAdd"] as? CNContact {
            contacts.insert(contact, at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }

}
