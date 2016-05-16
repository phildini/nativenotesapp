//
//  AttachmentCell.swift
//  Notes
//
//  Created by Philip James on 3/17/16.
//  Copyright © 2016 WordFugue. All rights reserved.
//

import Cocoa

class AttachmentCell: NSCollectionViewItem {

    weak var delegate: AttachmentCellDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if (theEvent.clickCount == 2) {
            delegate?.openSelectedAttachment(self)
        }
    }
}
