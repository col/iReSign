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
    
    var payloadPath: String {
        return workingPathURL!.URLByAppendingPathComponent(kPayloadDirName).path!
    }
    
    var appName: String? {
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(payloadPath) as [NSString]
            return files.filter { $0.pathExtension.lowercaseString == "app" }.first as? String
        }
        catch {
            return nil
        }
    }
    
    var appPath: String? {
        if let appName = appName {
            return NSURL(fileURLWithPath: payloadPath).URLByAppendingPathComponent(appName).path!
        }
        return nil
    }
    
    var frameworksPath: String? {
        return NSURL(fileURLWithPath: appPath!).URLByAppendingPathComponent(kFrameworksDirName).path!
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
        operationQueue.addOperation(unzipTask)
        
        if let bundleId = bundleId {
            let changeBundleIdTask = ChangeBundleIdTask(baseDir: workingPath, bundleId: bundleId)
            changeBundleIdTask.failureBlock = self.callback
            changeBundleIdTask.completionBlock = { print("ChangeBundleIdTask complete") }
            operationQueue.addOperation(changeBundleIdTask)
        }
        
        unzipTask.completionBlock = {
            print("UnzipTask complete.")
            if let appPath = self.appPath {
                let signAppTask = CodeSignTask(path: appPath, certificate: self.certificate, entitlementsPath: self.entitlementsPath)
                signAppTask.completionBlock = { print("CodeSign '\(appPath)' complete") }
                self.operationQueue.addOperation(signAppTask)
                
                let verifyAppSigningTask = VerifyCodeSignTask(path: appPath)
                verifyAppSigningTask.completionBlock = { print("Verify '\(appPath)' complete") }
                self.operationQueue.addOperation(verifyAppSigningTask)
                
                let frameworkPaths = self.findFrameworkPaths()!
                for frameworkPath in frameworkPaths {
                    let signFrameworkTask = CodeSignTask(path: frameworkPath, certificate: self.certificate, entitlementsPath: self.entitlementsPath)
                    signFrameworkTask.completionBlock = { print("CodeSign '\(frameworkPath)' complete") }
                    self.operationQueue.addOperation(signFrameworkTask)
                    
                    let verifyTask = VerifyCodeSignTask(path: frameworkPath)
                    verifyTask.completionBlock = { print("Verify '\(frameworkPath)' complete") }
                    self.operationQueue.addOperation(verifyTask)
                }
                
                let zipTask = ZipTask(baseDir: self.workingPath, destinationPath: self.destinationPath)
                zipTask.completionBlock = {
                    print("Zip complete")
                    self.callback?(nil)
                }
                self.operationQueue.addOperation(zipTask)
            }
        }
        
        unzipTask.state = .Ready
    }
    
    func findFrameworkPaths() -> [String]? {
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(frameworksPath!)
            return files.filter {
                let type = ($0 as NSString).pathExtension.lowercaseString
                return type == "framework" || type == "dylib"
            }.map {
                NSURL(fileURLWithPath: self.frameworksPath!).URLByAppendingPathComponent($0).path!
            }
        } catch {
            print("Error finding frameworks: \(error)")
            return nil
        }
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