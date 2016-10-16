//
//  ViewController.swift
//  ContactsDemo
//
//  Created by Alex Ackerman on 10/13/16.
//  Copyright © 2016 Darkhonor Development. All rights reserved.
//

import UIKit
import ContactsUI

class ViewController: UIViewController, CNContactPickerDelegate {

    static let ContactCell = "ContactCell"

//    var store: CNContactStore = CNContactStore()
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

        print("In Load Contacts")
        // Request access to the Contacts on the device
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            self.manageGroups()
            self.contacts = self.loadContactsFromStore()

        //            self.createContact()
        case .notDetermined:
            store.requestAccess(for: .contacts, completionHandler: {succeeded, err in guard err == nil && succeeded else {
                return
                }
                //                self.enumContainers()
                self.manageGroups()
                self.contacts = self.loadContactsFromStore()

                //                self.createContact()
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
        // Dispose of any resources that can be recreated.
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
            print("All Groups")
            let allGroups = try store.groups(matching: nil)
            let filteredGroups = allGroups.filter { $0.name == "Visit Tracker" }
            print("Groups filtered")
//            guard let vtGroupId = filteredGroups.first else {
//                print("No Visit Tracker group")
//                return
//            }
            if filteredGroups.count == 1 {
//                var vtGroupIdArray: [String] = [String]()
//                for fGroup in filteredGroups {
//                    vtGroupIdArray.append(fGroup.identifier)
//                }
//                print("Created Id array: \(vtGroupIdArray.count)")
//    //            let predicate = CNContact.predicateForContactsInGroupWithIdentifier(workGroup.identifier)
//                let predicate = CNGroup.predicateForGroups(withIdentifiers: vtGroupIdArray)
//                let groups: [CNGroup] = try store.groups(matching: predicate)
//                print("Found \(groups.count) groups in the container")
//                for group in groups {
//                    print("Group: \(group.name)")
//                }
//                if groups.count == 1 {
                    print("Visit Tracker group exists")
//                }
            } else {
                let vtGroup = CNMutableGroup()
                vtGroup.name = "Visit Tracker"
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

    func createContact() {
        let store = CNContactStore()
        let predicate = CNContact.predicateForContacts(matchingName: "Cathy Ackerman")
        let toFetch = [CNContactPhoneNumbersKey, CNContactGivenNameKey]
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: toFetch as [CNKeyDescriptor])
            guard contacts.count > 0 else {
                print("No Contacts Found.  Creating Contact")
                let contactData = CNMutableContact()
                contactData.givenName = "승언"
//                contactData.middleName = ""
                contactData.familyName = "이"
                contactData.nickname = "Babe"
                
                // Profile Photo
                if let img = UIImage(named: "contactPhoto"), let imgData = UIImagePNGRepresentation(img) {
                    contactData.imageData = imgData
                }
                
                // Phone Numbers
                let homePhone = CNLabeledValue(label: CNLabelHome, value: CNPhoneNumber(stringValue: "5719338354"))
                let cellPhone = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "7038250141"))
                contactData.phoneNumbers = [homePhone, cellPhone]
                
                // Work Address
                let workAddress = CNMutablePostalAddress()
                workAddress.street = "121 Hillpointe Dr"
                workAddress.city = "Canonsburg"
                workAddress.state = "PA"
                workAddress.postalCode = "15317"
                contactData.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: workAddress)]
                
                // Group???
                let vtGroup = self.getVisitTrackerGroup()
                
                // Save to Database
                let request = CNSaveRequest()
                request.add(contactData, toContainerWithIdentifier: nil)
                if vtGroup != nil {
                    request.addMember(contactData, to: vtGroup!)
                }
                
                do {
                    try store.execute(request)
                    print("Successfully added the contact: \(CNContactFormatter.string(from: contactData, style: CNContactFormatterStyle.fullName))")
                } catch let err {
                    print("Failed to save the contact.  \(err)")
                }
                return
            }

            print("Found \(contacts.count) Matching Contacts")
            
            // Delete the found contacts to reset for the next run
            let req = CNSaveRequest()
            guard let contact = contacts.first else {
                return
            }
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            req.delete(mutableContact)
            do {
                try store.execute(req)
                // In order to print the details for a given contact, you have to retrieve the PropertyKey in the query above
                if contact.isKeyAvailable("givenName") {
                    print("Success.  You deleted \(contact.givenName)")
                } else {
                    print("Success.  Contact deleted")
                }
            } catch let e {
                print("Error: \(e)")
            }
        } catch let err {
            print("Error Caught: \(err)")
            return
        }
    }

    private func loadContactsFromStore() -> [CNContact] {
        let store: CNContactStore = CNContactStore()
        guard let vtGroup = self.getVisitTrackerGroup() else {
            NSLog("ERROR: Unable to load Visit Tracker Group")
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

    private func getVisitTrackerGroup() -> CNGroup? {
        let store: CNContactStore = CNContactStore()
        do {
            let allGroups = try store.groups(matching: nil)
            let filteredGroups = allGroups.filter { $0.name == "Visit Tracker" }

            guard let vtGroup = filteredGroups.first else {
                NSLog("No Visit Tracker group")
                return nil
            }
            return vtGroup
        } catch let err {
            NSLog("Error caught grabbing Group: \(err)")
            return nil
        }
    }

    @IBAction func addExisting(_ sender: AnyObject) {
        print("DEBUG: In Add")
        let contactPickerViewController = CNContactPickerViewController()
        contactPickerViewController.delegate = self
        present(contactPickerViewController, animated: true, completion: nil)
    }

    @IBAction func addNew(_ sender: AnyObject) {
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
//        let selectedContactID = contact.identifier
        updateGroup(contact: contact)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addNewContact"), object: nil, userInfo: ["contactToAdd": contact])
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
    }

    func updateGroup(contact: CNContact) {
        let store: CNContactStore = CNContactStore()
        let request = CNSaveRequest()
        guard let group = getVisitTrackerGroup() else {
            NSLog("Error: Unable to get Visit Tracker Group")
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
        
    }

}
