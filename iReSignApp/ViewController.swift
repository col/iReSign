//
//  ViewController.swift
//  iReSignApp
//
//  Created by Colin Harris on 1/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSComboBoxDataSource {
    
    let EntitlementPathPrefKey = "ENTITLEMENT_PATH"
    let ProvisioningPathPrefKey = "PROVISIONING_PATH"
    let CertificateNamePrefKey = "CERTIFICATE_NAME"
    let BundleIDPrefKey = "BUNDLE_ID"
    let ChangeBundleIDPrefKey = "CHANGE_BUNDLE_ID"
    
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
    var controls: [NSControl] = []
    
    let defaults = NSUserDefaults.standardUserDefaults()
    let fileManager = NSFileManager.defaultManager()
    
    let operationQueue = NSOperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        controls = [
            pathField, browseButton,
            entitlementField, entitlementBrowseButton,
            provisioningPathField, provisioningBrowseButton,
            bundleIDField, changeBundleIDCheckbox,
            certComboBox, resignButton
        ]

        flurry.alphaValue = 0.5
        
        let findCertsTask = FindCertificates() { results in
            self.updateCertComboBox(results)
        }
        operationQueue.addOperation(findCertsTask)
        
        loadDefaultValues()
        checkForDependencies()
        enableControls()
    }
    
    private func checkForDependencies() {
        let requiredUtilities = [
            "zip": "/usr/bin/zip",
            "unzip": "/usr/bin/unzip",
            "codesign": "/usr/bin/codesign"
        ]
        for (name, path) in requiredUtilities {
            if !fileManager.fileExistsAtPath(path) {
                showAlertOfKind(.CriticalAlertStyle, withTitle: "Error", andMessage: "This app cannot run without the \(name) utility present at \(path)")
                exit(0);
            }
        }
    }

    private func updateCertComboBox(certificates: [String]?) {
        guard let certificates = certificates where certificates.count > 0 else {
            showAlertOfKind(.CriticalAlertStyle, withTitle: "Error", andMessage: "Getting Certificate ID's failed")
            enableControls()
            statusLabel.stringValue = "Ready"
            return;
        }
        
        self.certComboBoxItems = certificates
        self.certComboBox.reloadData()
        
        statusLabel.stringValue = "Signing Certificate IDs extracted"
        
        if let certificateName = defaults.valueForKey(CertificateNamePrefKey) as? String {
            if let index = certComboBoxItems!.indexOf(certificateName) {
                certComboBox.objectValue = certificateName
                certComboBox.selectItemAtIndex(index)
            }
        }
        
        enableControls()
    }
    
    // MARK: Interface Actions
    
    @IBAction func resign(sender: AnyObject) {
        print("resign")
        
        disableControls()
        showProgress()
        savePreferences()
        
        if !checkRequiredFields() {
            enableControls()
            hideProgress()
            statusLabel.stringValue = "Please try again"
            return
        }
        
        let bundleId: String? = bundleIDField.stringValue == "" ? nil : bundleIDField.stringValue
        let provisioningPath: String? = provisioningPathField.stringValue == "" ? nil : provisioningPathField.stringValue
        let entitlementsPath: String? = entitlementField.stringValue == "" ? nil : entitlementField.stringValue
        
        let resignTask = ResignTask(
            sourcePath: pathField.stringValue,
            certificate: certComboBox.objectValue as! String,
            provisioningPath: provisioningPath,
            entitlementsPath: entitlementsPath,
            bundleId: bundleId
        )
        
        resignTask.resign() { error in
            self.hideProgress()
            self.statusLabel.hidden = false
            if let error = error {
                self.statusLabel.stringValue = error.localizedDescription
            } else {
                self.statusLabel.stringValue = "Resign Successfull!"
            }
        }
  
    }
    
    @IBAction func browse(sender: AnyObject) {
        openBrowseWindow(["ipa", "IPA", "xcarchive"]) { filePath in
            if let path = filePath {
                self.pathField.stringValue = path
            }
        }
    }
    
    @IBAction func provisioningBrowse(sender: AnyObject) {
        openBrowseWindow(["mobileprovision", "MOBILEPROVISION"]) { filePath in
            if let path = filePath {
                self.provisioningPathField.stringValue = path
            }
        }
    }
    
    @IBAction func entitlementBrowse(sender: AnyObject) {
        openBrowseWindow(["plist", "PLIST"]) { filePath in
            if let path = filePath {
                self.entitlementField.stringValue = path
            }
        }
    }
    
    @IBAction func changeBundleIDPressed(sender: NSButton) {
        if sender != changeBundleIDCheckbox {
            return;
        }
        
        bundleIDField.enabled = changeBundleIDCheckbox.state == NSOnState;
    }
    
    // MARK: Certificate Combo Box Data Source Methods
    
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return certComboBoxItems?.count ?? 0
    }
    
    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return certComboBoxItems?[index] ?? ""
    }
    
    // MARK: Private Methods
    
    private func loadDefaultValues() {
        if let entitlementPath = defaults.valueForKey(EntitlementPathPrefKey) as? String {
            print("Default Entitlements Path: \(entitlementPath)")
            entitlementField.stringValue = entitlementPath
        }
        if let provisioningPath = defaults.valueForKey(ProvisioningPathPrefKey) as? String {
            print("Default Provisioning Path: \(provisioningPath)")
            provisioningPathField.stringValue = provisioningPath
        }
        if let bundleId = defaults.valueForKey(BundleIDPrefKey) as? String {
            print("Default Bundle ID: \(bundleId)")
            bundleIDField.stringValue = bundleId
        }
        if let changeBundleId = defaults.valueForKey(ChangeBundleIDPrefKey) as? NSNumber {
            print("Default Change Bundle ID: \(changeBundleId)")
            changeBundleIDCheckbox.state = changeBundleId.boolValue ? NSOnState : NSOffState
        }
    }
    
    private func savePreferences() {
        if let certificate = certComboBox.objectValue as? String {
            defaults.setValue(certificate, forKey: CertificateNamePrefKey)
        }
        defaults.setValue(entitlementField.stringValue, forKey: EntitlementPathPrefKey)
        defaults.setValue(provisioningPathField.stringValue, forKey: ProvisioningPathPrefKey)
        defaults.setValue(bundleIDField.stringValue, forKey: BundleIDPrefKey)
        defaults.setValue(NSNumber(bool: changeBundleIDCheckbox.state == NSOnState), forKey: BundleIDPrefKey)
        defaults.synchronize()
    }
    
    private func checkRequiredFields() -> Bool {
        let certificate = certComboBox.objectValue as? String
        if certificate == nil {
            showAlertOfKind(.CriticalAlertStyle, withTitle: "Error", andMessage: "You must choose an signing certificate from dropdown.")
            return false
        }
        
        let pathExtension = (pathField.stringValue as NSString).pathExtension.lowercaseString
        if pathExtension != "ipa" && pathExtension != "xcarchive" {
            showAlertOfKind(.CriticalAlertStyle, withTitle: "Error", andMessage: "You must choose an *.ipa or *.xcarchive file")
            return false
        }
        
        return true
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
    }
    
    private func disableControls() {
        for control in controls {
            control.enabled = false
        }
    }
    
    private func hideProgress() {
        flurry.stopAnimation(self)
        flurry.alphaValue = 0.5
    }
    
    private func showProgress() {
        flurry.startAnimation(self)
        flurry.alphaValue = 1.0
    }
    
    private func showAlertOfKind(style: NSAlertStyle, withTitle title: String, andMessage message: String) {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.runModal()
    }

}

