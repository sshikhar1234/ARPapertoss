//
//  AppDelegate.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-09.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation
import UIKit

class TableCell: UITableViewCell {

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var score: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
    }

    // MARK: Cell Configuration

//    func configurateTheCell(_ recipe: Recipe) {
//        nameLabel.text = recipe.name
//        prepTimeLabel.text = "Prep Time: " + recipe.prepTime
//        thumbnailImageView.image = UIImage(named: recipe.thumbnails)
//    }

}
