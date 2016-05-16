//
//  DocumentCommon.swift
//  Notes
//
//  Created by Philip James on 5/8/16.
//  Copyright © 2016 WordFugue. All rights reserved.
//

import Foundation

// We can be throwing a lot of errors in this class, and they'll all be in the
// same error domain and using from the same enum, so here's a little
// convenience func to save typing and space

let ErrorDomain = "NotesErrorDomain"

func err(code: ErrorCode, _ userInfo:[NSObject:AnyObject]? = nil) -> NSError {
    // Generate an error object, using ErrorDomain and whatever value we were 
    // passed
    return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
}

// Names of files/directories in the package
enum NoteDocumentFileNames: String {
    case TextFile = "Text.rtf"
    case AttachmentsDirectory = "Attachments"
    case QuickLookDirectory = "Quicklook"
    case QuickLookTextFile = "Preview.rtf"
    case QuickLookThumbnail = "Thumbnail.png"
}

let NotesUseiCloudKey = "use_icloud"
let NotesHasPromptedForiCloudKey = "has_prompted_for_icloud"

/// Things that can go wrong:
enum ErrorCode: Int {
    /// We couldn't find the doucment at all.
    case CannotAccessDocument

    /// We couldn't access any file wrappers inside this document
    case CannotLoadFileWrappers

    /// We couldn't load the Text.rtf file
    case CannotLoadText

    /// We could't access the Attachments folder
    case CannotAccessAttachments

    /// We couldn't save the Text.rtf file
    case CannotSaveText

    /// We couldn't save an attachment
    case CannotSaveAttachment
}
