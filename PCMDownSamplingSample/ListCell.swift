//
//  ListCell.swift
//  vTXT
//
//  Created by Tadashi on 2017/02/23.
//  Copyright © 2017 T@d. All rights reserved.
//

import UIKit

class ListCell: UITableViewCell {

	@IBOutlet var button: UIButton!
	@IBOutlet var label: UILabel!
	@IBOutlet var icon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
