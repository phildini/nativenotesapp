//
//  FileCollectionViewCell.swift
//  Notes
//
//  Created by Philip James on 5/11/16.
//  Copyright © 2016 WordFugue. All rights reserved.
//

import UIKit

class FileCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var fileNameLabel : UILabel?
    @IBOutlet weak var imageView : UIImageView?
    @IBOutlet weak var deleteButton: UIButton!
    
    
    var renameHandler : (Void -> Void)?
    var deletionHandler : (Void -> Void)?
    
    @IBAction func deleteTapped() {
        deletionHandler?()
    }

    @IBAction func renameTapped() {
        renameHandler?()
    }
    
    func setEditing(editing: Bool, animated:Bool) {
        let alpha: CGFloat = editing ? 1.0 : 0.0
        if animated {
            UIView.animateWithDuration(0.25) { () -> Void in
                self.deleteButton?.alpha = alpha
            }
        } else {
            self.deleteButton?.alpha = alpha
        }
    }
}
