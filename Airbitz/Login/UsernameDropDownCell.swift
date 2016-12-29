//
//  UsernameDropDownCell.swift
//  Airbitz
//
//  Created by Rommel Rico on 11/22/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

import UIKit

let DropDownDeleteNotificationIdentifier = Notification.Name("DropDownDeleteNotificationIdentifier")

class UsernameDropDownCell: DropDownCell {

    @IBAction func deleteButton(_ sender: Any) {
        NotificationCenter.default.post(name: DropDownDeleteNotificationIdentifier, object: self)
    }

}
