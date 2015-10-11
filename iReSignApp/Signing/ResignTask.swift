//
//  ResignTask.swift
//  iReSign
//
//  Created by Colin Harris on 2/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

typealias ResignCallback = (NSError?) -> Void

let kKeyInfoPlistApplicationProperties = "ApplicationProperties"
let kKeyInfoPlistApplicationPath       = "ApplicationPath"
let kFrameworksDirName                 = "Frameworks"
let kPayloadDirName                    = "Payload"
let kProductsDirName                   = "Products"
let kInfoPlistFilename                 = "Info.plist"

class ResignTask: NSObject {
    
    let sourcePath: String
    let certificate: String
    let provisioningPath: String?
    let entitlementsPath: String?
    let bundleId: String?
    var callback: ResignCallback?
    let operationQueue: NSOperationQueue
    
    let fileManager = NSFileManager.defaultManager()
    
    var workingPathURL: NSURL?
    var workingPath: String {
        return workingPathURL!.path!
    }
    
    var pathExtension: String {
        return (sourcePath as NSString).pathExtension.lowercaseString
    }

    var destinationPath: String {
        return NSURL(fileURLWithPath: sourcePath)
            .URLByDeletingLastPathComponent!
            .URLByAppendingPathComponent("resigned.ipa").path!
    }
    
    init(sourcePath: String, certificate: String, provisioningPath: String?, entitlementsPath: String?, bundleId: String?) {
        self.sourcePath = sourcePath
        self.certificate = certificate
        self.provisioningPath = provisioningPath
        self.entitlementsPath = entitlementsPath
        self.bundleId = bundleId
        self.workingPathURL = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true).URLByAppendingPathComponent("com.colharris.iresign")
        
        operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    func resign(callback: ResignCallback) {
        self.callback = { error in
            self.operationQueue.cancelAllOperations()
            self.operationQueue.suspended = true
            dispatch_async(dispatch_get_main_queue(), {
                callback(error)
            })
        }
        
        if !createWorkingDirectory() {
            return
        }
        
        let unzipTask = UnzipTask(sourcePath: sourcePath, destinationPath: workingPath)
        unzipTask.failureBlock = self.callback
        unzipTask.completionBlock = { print("UnzipTask complete.") }
        operationQueue.addOperation(unzipTask)
        
        if let bundleId = bundleId {
            let changeBundleIdTask = ChangeBundleIdTask(baseDir: workingPath, bundleId: bundleId)
            changeBundleIdTask.failureBlock = self.callback
            changeBundleIdTask.completionBlock = { print("ChangeBundleIdTask complete") }
            operationQueue.addOperation(changeBundleIdTask)
        }
        
        let resignApplicationTask = ResignApplicationTask(baseDir: workingPath, certificate: certificate, entitlementsPath: entitlementsPath)
        resignApplicationTask.failureBlock = self.callback
        resignApplicationTask.completionBlock = { print("ResignApplicationTask complete") }
        operationQueue.addOperation(resignApplicationTask)
        
        let zipTask = ZipTask(baseDir: self.workingPath, destinationPath: self.destinationPath)
        zipTask.completionBlock = {
            print("Zip complete")
            self.callback?(nil)
        }
        self.operationQueue.addOperation(zipTask)
        
        unzipTask.state = .Ready
    }
    
    func createWorkingDirectory() -> Bool {
        do {
            if fileManager.fileExistsAtPath(workingPath) {
                try fileManager.removeItemAtPath(workingPath)
            }
            try fileManager.createDirectoryAtPath(workingPath, withIntermediateDirectories: true, attributes: nil)
            print("Created working directory at: \(workingPath)")
            return true
        } catch let error as NSError {
            print("Error creating working directory: \(error)")
            let error = NSError(domain: "iReSign", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create working directory.",
                NSLocalizedFailureReasonErrorKey: error.localizedDescription])
            callback?(error)
            return false
        }
    }
    
}