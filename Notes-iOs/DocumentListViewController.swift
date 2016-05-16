//
//  ViewController.swift
//  Notes-iOs
//
//  Created by Philip James on 4/3/16.
//  Copyright © 2016 WordFugue. All rights reserved.
//

import UIKit

class DocumentListViewController: UICollectionViewController {

    let fileCoordinator = NSFileCoordinator(filePresenter: nil)

    var availableFiles: [NSURL] = []

    var queryDidFinishGatheringObserver : AnyObject?
    var queryDidUpdateObserver: AnyObject?
    
    var metadataQuery: NSMetadataQuery = {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*.note'", NSMetadataItemFSNameKey)
        metadataQuery.sortDescriptors = [
            NSSortDescriptor(key:NSMetadataItemFSContentChangeDateKey, ascending: false)
        ]
        
        return metadataQuery
    }()
    
    class var localDocumentsDirectoryURL: NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    }
    
    class var ubiquitousDocumentsDirectoryURL: NSURL? {
        return NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)?.URLByAppendingPathComponent("Documents")
    }
    
    class var iCloudAvailable : Bool {
        if NSUserDefaults.standardUserDefaults().boolForKey(NotesUseiCloudKey) == false {
            return false
        }
        let returnValue = NSFileManager.defaultManager().ubiquityIdentityToken != nil
        NSLog("iCloud Available: \(returnValue)")
        return returnValue
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "createDocument")
        self.navigationItem.rightBarButtonItem = addButton
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        self.queryDidUpdateObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSMetadataQueryDidUpdateNotification, object: metadataQuery, queue: NSOperationQueue.mainQueue()) {
            (notification) in self.queryUpdated()
        }
        
        self.queryDidFinishGatheringObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSMetadataQueryDidFinishGatheringNotification, object: metadataQuery, queue: NSOperationQueue.mainQueue()) {
            (notification) in self.queryUpdated()
        }
        
        
        let hasPromptedForiCloud = NSUserDefaults.standardUserDefaults().boolForKey(NotesHasPromptedForiCloudKey)
        
        if hasPromptedForiCloud == false {
            let alert = UIAlertController(title: "Use iCloud?", message: "Do you want to store your documents in iCloud or store them locally?", preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "iCloud", style: .Default, handler: {
                (action) in NSUserDefaults.standardUserDefaults().setBool(true, forKey: NotesUseiCloudKey)
                self.metadataQuery.startQuery()
            }))
            
            alert.addAction(UIAlertAction(title: "Local Only", style: .Default, handler: {
                (action) in NSUserDefaults.standardUserDefaults().setBool(false, forKey: NotesUseiCloudKey)
                self.refreshLocalFileList()
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: NotesHasPromptedForiCloudKey)
        } else {
            metadataQuery.startQuery()
            refreshLocalFileList()
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.availableFiles.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Get our cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FileCell", forIndexPath: indexPath) as! FileCollectionViewCell
        
        // Get this object from the list of known files
        let url = availableFiles[indexPath.row]
        
        // Get the display name
        var fileName: AnyObject?
        do {
            try url.getResourceValue(&fileName, forKey: NSURLNameKey)
            if let fileName = fileName as? String {
                cell.fileNameLabel!.text = fileName
            }
        } catch {
            cell.fileNameLabel!.text = "Loading..."
        }
        
        cell.setEditing(self.editing, animated: false)
        cell.deletionHandler = {
            self.deleteDocumentAtURL(url)
        }
        
        let labelTapRecognizer = UITapGestureRecognizer(target: cell, action: "renameTapped")
        cell.fileNameLabel?.gestureRecognizers = [labelTapRecognizer]
        cell.renameHandler = {
            self.renameDocumentAtURL(url)
        }
        
        // If this cell is openable, make it fully visible, and make the cell
        // able to be touched
        if itemIsOpenable(url) {
            cell.alpha = 1.0
            cell.userInteractionEnabled = true
        } else {
            // But if it's not, make it semitransparent, and
            // make the cell not respond to input
            cell.alpha = 0.5
            cell.userInteractionEnabled = false
        }
        
        return cell
    }
    
    func queryUpdated() {
        self.collectionView?.reloadData()
        
        // Ensure that the metadata query's results can be accessed
        guard let items = self.metadataQuery.results as? [NSMetadataItem]
        else {
            return
        }
        
        // Ensure that iCloud is available-if it's unavailable, we shouldn't
        // bother looking for files
        guard DocumentListViewController.iCloudAvailable else {
            return
        }
        
        // Clear the list of files we know about.
        availableFiles = []
        
        // Discover any local files that don't need to be downloaded
        refreshLocalFileList()
        
        for item in items {
            
            // Ensure that we can get the file URL for this item
            guard let url = item.valueForAttribute(NSMetadataItemURLKey) as? NSURL else {
                // We need to have the URL to access it, so move on to the next file
                // by breaking out of this loop
                continue
            }
            
            // Add it to the list of available files
            availableFiles.append(url)
            
            // Check to see if we already have the latest version downloaded
            if itemIsOpenable(url) == true {
                // We only need to download if it isn't already openable
                continue
            }
            
            // Ask the system to try and download it
            do {
                try NSFileManager.defaultManager().startDownloadingUbiquitousItemAtURL(url)
            } catch let error as NSError {
                // Problem! :(
                print("Error downloading item! \(error)")
            }
        }
    }
        
        
    func refreshLocalFileList() {
        do {
            var localFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(DocumentListViewController.localDocumentsDirectoryURL, includingPropertiesForKeys: [NSURLNameKey], options: [.SkipsPackageDescendants,.SkipsSubdirectoryDescendants])
            
            localFiles = localFiles.filter({ (url) in return url.pathExtension == "note"})
            
            if (DocumentListViewController.iCloudAvailable) {
                // Move these files into iCloud
                for file in localFiles {
                    if let documentName = file.lastPathComponent, let ubiquitousDestinationURL = DocumentListViewController.ubiquitousDocumentsDirectoryURL?.URLByAppendingPathComponent(documentName) {
                        do {
                            try NSFileManager.defaultManager().setUbiquitous(true, itemAtURL: file, destinationURL: ubiquitousDestinationURL)
                        } catch let error as NSError {
                                NSLog("Failed to move file \(file) to iCloud: \(error)")
                        }
                    }
                }
            } else {
                // Add these files to the list of files we know about
                availableFiles.appendContentsOf(localFiles)
            }
        } catch let error as NSError {
            NSLog("Failed to list local documents: \(error)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createDocument() {
        // Create a unique name for this new document by adding a random number
        let documentName = "Document \(arc4random()).note"
        
        // Work out where we're going to store it temporarily
        let documentDestinationURL = DocumentListViewController.localDocumentsDirectoryURL.URLByAppendingPathComponent(documentName)
        
        // Create the new document and try to save it locally
        let newDocument = Document(fileURL: documentDestinationURL)
        newDocument.saveToURL(documentDestinationURL, forSaveOperation: .ForCreating) {
            (success) -> Void in if (DocumentListViewController.iCloudAvailable) {
                // If we have the ability to use iCloud...
                // If we successfully created it, attempt to move it to iCloud
                if success == true, let ubiquitousDestinationURL = DocumentListViewController.ubiquitousDocumentsDirectoryURL?.URLByAppendingPathComponent(documentName) {
                    
                    // Perform the move to iCloud in the background
                    NSOperationQueue().addOperationWithBlock {
                        () -> Void in do {
                            try NSFileManager.defaultManager().setUbiquitous(true, itemAtURL: documentDestinationURL, destinationURL: ubiquitousDestinationURL)
                            
                            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                                self.availableFiles.append(ubiquitousDestinationURL)
                                self.collectionView?.reloadData()
                            }
                        } catch let error as NSError {
                            NSLog("Error storing document in iCloud! \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                // We can't save to iCloud so it stays in local storage
                self.availableFiles.append(documentDestinationURL)
                self.collectionView?.reloadData()
            }
        }
    }
    
    // Returns true if the document can be opened right now
    func itemIsOpenable(url:NSURL?) -> Bool {
        // Return false if item is nil
        guard let itemURL = url else {
            return false
        }
        
        // Return true if we don't have access to iCloud (which means its not 
        // possible for it to be in conflict - we'll always have the lastest copy)
        if DocumentListViewController.iCloudAvailable == false {
            return true
        }
        
        // Ask the system for the download status
        var downloadStatus: AnyObject?
        do {
            try itemURL.getResourceValue(&downloadStatus, forKey: NSURLUbiquitousItemDownloadingStatusKey)
        } catch let error as NSError {
            NSLog("Failed to get downloading status for \(itemURL): \(error)")
            // If we can't get that, we can't open it
            return false
        }
        
        // Return true if this file is the most current version
        if downloadStatus as? String == NSURLUbiquitousItemDownloadingStatusCurrent {
            return true
        } else {
            return false
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        for visibleCell in self.collectionView?.visibleCells() as! [FileCollectionViewCell] {
            visibleCell.setEditing(editing, animated: animated)
        }
    }
    
    func deleteDocumentAtURL(url: NSURL) {
        NSLog("Got to top of deleteDocumentAtURL, url: \(url)")
        var error: NSError?
        self.fileCoordinator.coordinateWritingItemAtURL(url, options: .ForDeleting, error: &error, byAccessor: { (urlForModifying) -> Void in
            NSLog("Here I am")
            do {
                NSLog("Got inside deleteDocumentBlock")
                try NSFileManager.defaultManager().removeItemAtURL(urlForModifying)

                // Remove the URL from the list
                self.availableFiles = self.availableFiles.filter {
                    $0 != url
                }

                // Update the collection
                self.collectionView?.reloadData()

            } catch let error as NSError {
                let alert = UIAlertController(title: "Error deleting", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)

                alert.addAction(UIAlertAction(title: "Done", style: .Default, handler: nil))

                self.presentViewController(alert, animated: true, completion: nil)
            }

        })
        //Error:
        if(error != nil){
            print(error)
        }
    }
    func renameDocumentAtURL(url: NSURL) {
        
        // Create an alert box
        let renameBox = UIAlertController(title: "Rename Document", message: nil, preferredStyle: .Alert)
        
        // Add a text field to the alert that contains its current name, sans ".note"
        renameBox.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            let filename = url.lastPathComponent?.stringByReplacingOccurrencesOfString(".note", withString: "")
            textField.text = filename
        })
        
        // Add the cancel button, which does nothing
        renameBox.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // Add the rename button, which actually does the renaming
        renameBox.addAction(UIAlertAction(title: "Rename", style: .Default) { (action) in
            
            // Attempt to construct a destination URL from the name the user provided
            if let newName = renameBox.textFields?.first?.text,
                let destinationURL = url.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newName + ".note") {
                
                // Indicate that we intend to do writing
                self.fileCoordinator.coordinateWritingItemAtURL(url, options: [], writingItemAtURL: destinationURL, options: [], error: nil, byAccessor: { (origin, destination) -> Void in
                    do {
                        // Perform the actual move
                        try NSFileManager.defaultManager().moveItemAtURL(origin, toURL: destination)
                        
                        // Remove the original URL from the file list by filtering it out
                        self.availableFiles = self.availableFiles.filter {
                            $0 != url
                        }
                        
                        // Add the new URL to the file list
                        self.availableFiles.append(destination)
                        
                        // Refresh our collection of files
                        self.collectionView?.reloadData()
                    } catch let error as NSError {
                        NSLog("Failed to move \(origin) to \(destination): \(error)")
                    }
                })
            }
        })
        
        // Finally, present the box
        self.presentViewController(renameBox, animated: true, completion: nil)
    }
}
