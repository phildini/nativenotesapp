//
//  AddAttachmentViewController.swift
//  Notes
//
//  Created by Philip James on 3/17/16.
//  Copyright © 2016 WordFugue. All rights reserved.
//

import Cocoa

protocol AddAttachmentDelegate {
    func addFile()
}

class AddAttachmentViewController: NSViewController {

    // MARK: Properties
    var delegate: AddAttachmentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK: Actions
    @IBAction func addFile(sender: AnyObject) {
        self.delegate?.addFile()
    }
    
}
