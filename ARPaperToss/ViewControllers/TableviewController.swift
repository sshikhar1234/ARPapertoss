//
//  TableviewController.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-10.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation
import UIKit
class TableviewController : UITableViewController{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "checklistitem", for: indexPath)
        return cell
    }
}
