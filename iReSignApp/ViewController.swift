//
//  ViewController.swift
//  iReSignApp
//
//  Created by Colin Harris on 1/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSComboBoxDataSource {

    @IBOutlet var pathField: IRTextFieldDrag!
    @IBOutlet var provisioningPathField: IRTextFieldDrag!
    @IBOutlet var entitlementField: IRTextFieldDrag!
    @IBOutlet var bundleIDField: IRTextFieldDrag!
    @IBOutlet var browseButton: NSButton!
    @IBOutlet var provisioningBrowseButton: NSButton!
    @IBOutlet var entitlementBrowseButton: NSButton!
    @IBOutlet var resignButton: NSButton!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var flurry: NSProgressIndicator!
    @IBOutlet var changeBundleIDCheckbox: NSButton!
    @IBOutlet var certComboBox: NSComboBox!
    
    var certComboBoxItems: [String]?
    var codeSigningTools: CodeSigningTools?
    var controls: [NSControl] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        controls = [ pathField, entitlementField, browseButton, resignButton,
            provisioningBrowseButton, provisioningPathField,
            changeBundleIDCheckbox, bundleIDField, certComboBox]

        flurry.alphaValue = 0.5
        
        codeSigningTools = CodeSigningTools()
        codeSigningTools?.getCertificates() { results in
            self.updateCertComboBox(results)
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let entitlementPath = defaults.valueForKey("ENTITLEMENT_PATH") as? String {
            entitlementField.stringValue = entitlementPath
        }
        
        if let provisioningPath = defaults.valueForKey("MOBILEPROVISION_PATH") as? String {
            provisioningPathField.stringValue = provisioningPath
        }
        
        let requiredUtilities = [
            "zip": "/usr/bin/zip",
            "unzip": "/usr/bin/unzip",
            "codesign": "/usr/bin/codesign"
        ]
        for (name, path) in requiredUtilities {
            if !NSFileManager.defaultManager().fileExistsAtPath(path) {
                showAlertOfKind(.CriticalAlertStyle, withTitle: "Error", andMessage: "This app cannot run without the \(name) utility present at \(path)")
                exit(0);
            }
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func updateCertComboBox(certificates: [String]?) {
        guard let certificates = certificates where certificates.count > 0 else {
            showAlertOfKind(.CriticalAlertStyle, withTitle: "Error", andMessage: "Getting Certificate ID's failed")
            enableControls()
            statusLabel.stringValue = "Ready"
            return;
        }
        
        self.certComboBoxItems = certificates
        self.certComboBox.reloadData()
        
        statusLabel.stringValue = "Signing Certificate IDs extracted"
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let certIndex = defaults.valueForKey("CERT_INDEX") as? NSNumber {
            let selectedIndex = certIndex.integerValue
            if selectedIndex != -1 {
                let selectedItem = certificates[selectedIndex]
                certComboBox.objectValue = selectedItem
                certComboBox.selectItemAtIndex(selectedIndex)
            }
        }
        
        enableControls()
    }
    
    @IBAction func resign(sender: AnyObject) {
        print("resign")
    }
    
    @IBAction func browse(sender: AnyObject) {
        print("browse")
        openBrowseWindow(["ipa", "IPA", "xcarchive"]) { filePath in
            if let path = filePath {
                self.pathField.stringValue = path
            }
        }
    }
    
    @IBAction func provisioningBrowse(sender: AnyObject) {
        print("provisioningBrowse")
        openBrowseWindow(["mobileprovision", "MOBILEPROVISION"]) { filePath in
            if let path = filePath {
                self.provisioningPathField.stringValue = path
            }
        }
    }
    
    @IBAction func entitlementBrowse(sender: AnyObject) {
        print("entitlementBrowse")
        openBrowseWindow(["plist", "PLIST"]) { filePath in
            if let path = filePath {
                self.entitlementField.stringValue = path
            }
        }
    }
    
    @IBAction func changeBundleIDPressed(sender: NSButton) {
        print("changeBundleIDPressed")
        if sender != changeBundleIDCheckbox {
            return;
        }
        
        bundleIDField.enabled = changeBundleIDCheckbox.state == NSOnState;
    }
    
    private func openBrowseWindow(allowedFileTypes: [String], callback: (String?) -> Void) {
        let openDialog = NSOpenPanel()
        
        openDialog.canChooseFiles = true
        openDialog.canChooseDirectories = false
        openDialog.allowsMultipleSelection = false
        openDialog.allowsOtherFileTypes = false
        openDialog.allowedFileTypes = allowedFileTypes
        
        if openDialog.runModal() == NSModalResponseOK {
            let fileName = openDialog.URLs[0].path
            callback(fileName)
        }
    }

    private func enableControls() {
        for control in controls {
            control.enabled = true
        }
        
        flurry.stopAnimation(self)
        flurry.alphaValue = 0.5
    }
    
    private func disableControls() {
        for control in controls {
            control.enabled = false
        }
        
        flurry.startAnimation(self)
        flurry.alphaValue = 1.0
    }
    
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return certComboBoxItems?.count ?? 0
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return certComboBoxItems?[index] ?? ""
    }
    
    func showAlertOfKind(style: NSAlertStyle, withTitle title: String, andMessage message: String) {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.runModal()
    }

}

