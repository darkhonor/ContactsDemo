//
//  SettingsViewController.swift
//  ContactsDemo
//
//  Created by Alex Ackerman on 10/17/16.
//  Copyright © 2016 Darkhonor Development. All rights reserved.
//

import Foundation
import UIKit

class SettngsViewController: UIViewController {
    
    @IBOutlet weak var cnGroupField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard
        let cnGroupName = defaults.string(forKey: "CNGroupName")
        if cnGroupName != nil && cnGroupName!.isEmpty {
            cnGroupField.text = cnGroupName!
        } else {
            cnGroupField.text = ViewController.GroupNameDefault
        }
    }

    @IBAction func saveSettings(_ sender: UIButton) {
        let defaults = UserDefaults.standard
        defaults.set(cnGroupField.text, forKey: "CNGroupName")
        NSLog("INFO: Saving Group: %@", defaults.string(forKey: "CNGroupName") ?? "NOT SET")
        defaults.synchronize()
    }

}
