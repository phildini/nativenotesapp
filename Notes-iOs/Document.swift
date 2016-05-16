//
//  Document.swift
//  Notes
//
//  Created by Philip James on 5/8/16.
//  Copyright © 2016 WordFugue. All rights reserved.
//

import UIKit

class Document: UIDocument {

    var text = NSAttributedString(string: "") {
        didSet {
            self.updateChangeCount(UIDocumentChangeKind.Done)
        }
    }
    
    var documentFileWrapper = NSFileWrapper(directoryWithFileWrappers: [:])
    
    override func contentsForType(typeName: String) throws -> AnyObject {
        let textRTFData = try self.text.dataFromRange(
            NSRange(0..<self.text.length),
            documentAttributes: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType]
        )
        
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }
        
        self.documentFileWrapper.addRegularFileWithContents(textRTFData, preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
        
        return self.documentFileWrapper
    }
    
    override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
        
        // Ensure that we've been given a file wrapper
        guard let fileWrapper = contents as? NSFileWrapper else {
            throw err(.CannotLoadFileWrappers)
        }
        
        // Ensure that this file wrapper contains the text file and that we can
        // read it
        guard let textFileWrapper = fileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue],
            let textFileData = textFileWrapper.regularFileContents else {
            throw err(.CannotLoadText)
        }
        
        // Read in the RTF
        self.text = try NSAttributedString(data: textFileData, options: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType], documentAttributes: nil)
        
        // Keep a reference to the file wrapper
        self.documentFileWrapper = fileWrapper
    }
}
