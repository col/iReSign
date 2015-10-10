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
    
    var fileManager: NSFileManager {
        return NSFileManager.defaultManager()
    }
    
    var payloadPath: String {
        return NSURL(fileURLWithPath: baseDir).URLByAppendingPathComponent(kPayloadDirName).path!
    }
    
    var appPath: String? {
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(payloadPath) as [NSString]
            return files.filter { $0.pathExtension.lowercaseString == "app" }.first as? String
        }
        catch {
            return nil
        }
    }
    
    var frameworksPath: String? {
        return NSURL(fileURLWithPath: appPath!).URLByAppendingPathComponent(kFrameworksDirName).path!
    }
    
    init(baseDir: String) {
        self.baseDir = baseDir
        super.init()
        state = .Ready
    }
    
    override func start() {
        if cancelled {
            return
        }
        
        state = .Executing
        
        if let appPath = appPath {
            signApplication()
        }
        
        state = .Finished
    }
    
    func signApplication() {
        
    }
    
}