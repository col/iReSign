//
//  ResignApplicationTask.swift
//  iReSign
//
//  Created by Colin Harris on 3/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

class ResignApplicationTask: IROperation {
    
    let baseDir: String
    let certificate: String
    let entitlementsPath: String?
    let operationQueue: NSOperationQueue
    
    var fileManager: NSFileManager {
        return NSFileManager.defaultManager()
    }
    
    var payloadPath: String {
        return NSURL(fileURLWithPath: baseDir).URLByAppendingPathComponent(kPayloadDirName).path!
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
    
    init(baseDir: String, certificate: String, entitlementsPath: String?) {
        self.baseDir = baseDir
        self.certificate = certificate
        self.entitlementsPath = entitlementsPath
        self.operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 4
        super.init()
        state = .Ready
    }
    
    override func start() {
        if cancelled {
            return
        }
        
        state = .Executing
        
        if let appPath = self.appPath {
            
            let signAppTask = CodeSignTask(path: appPath, certificate: self.certificate, entitlementsPath: self.entitlementsPath)
            signAppTask.failureBlock = failureBlock
            signAppTask.completionBlock = { print("CodeSign '\(appPath)' complete") }
            self.operationQueue.addOperation(signAppTask)
            
            let verifyAppSigningTask = VerifyCodeSignTask(path: appPath)
            verifyAppSigningTask.failureBlock = failureBlock
            verifyAppSigningTask.completionBlock = { print("Verify '\(appPath)' complete") }
            verifyAppSigningTask.addDependency(signAppTask)
            self.operationQueue.addOperation(verifyAppSigningTask)
            
            let frameworkPaths = self.findFrameworkPaths()!
            var frameworkTasks = [IROperation]()
            
            for frameworkPath in frameworkPaths {
                
                let signFrameworkTask = CodeSignTask(path: frameworkPath, certificate: self.certificate, entitlementsPath: self.entitlementsPath)
                signFrameworkTask.failureBlock = failureBlock
                signFrameworkTask.completionBlock = { print("CodeSign '\(frameworkPath)' complete") }
                signFrameworkTask.addDependency(signAppTask)
                self.operationQueue.addOperation(signFrameworkTask)
                
                let verifyTask = VerifyCodeSignTask(path: frameworkPath)
                verifyTask.failureBlock = failureBlock
                verifyTask.completionBlock = { print("Verify '\(frameworkPath)' complete") }
                verifyTask.addDependency(signFrameworkTask)
                self.operationQueue.addOperation(verifyTask)
                
                frameworkTasks.append(verifyTask)
            }
            
            let finalTask = NSBlockOperation() { }
            finalTask.completionBlock = {
                self.state = .Finished
            }
            for frameworkTask in frameworkTasks {
                finalTask.addDependency(frameworkTask)
            }
            self.operationQueue.addOperation(finalTask)
            
        } else {
            let error = NSError(domain: "ResignApplicationTask", code: 1, userInfo: [NSLocalizedDescriptionKey: "Application not found!"])
            failureBlock?(error)
        }

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
    
}