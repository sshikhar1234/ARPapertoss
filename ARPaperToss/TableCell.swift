//
//  TableCell.swift
//  Swift-TableView-Example
//
//  Created by Bilal ARSLAN on 11/10/14.
//  Copyright (c) 2014 Bilal ARSLAN. All rights reserved.
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
