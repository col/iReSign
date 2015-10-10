//
//  ChangeProvisioningProfileTask.swift
//  iReSign
//
//  Created by Colin Harris on 4/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

class ChangeProvisioningProfileTask: IROperation {
    
    var appPath: String
    var provisioningPath: String
    
    var embeddedProfile: String {
        return NSURL(fileURLWithPath: appPath).URLByAppendingPathComponent("embedded.mobileprovision").path!
    }
    
    var fileManager: NSFileManager {
        return NSFileManager.defaultManager()
    }
    
    init(appPath: String, provisioningPath: String) {
        self.appPath = appPath
        self.provisioningPath = provisioningPath
        super.init()
        state = .Ready
    }
    
    override func start() {
        if cancelled {
            return
        }
        
        state = .Executing

        do {
            if fileManager.fileExistsAtPath(embeddedProfile) {
                try fileManager.removeItemAtPath(embeddedProfile)
            }
            try fileManager.copyItemAtPath(provisioningPath, toPath: embeddedProfile)
        } catch {
            print("Failed to change embedded provisioning profile: \(error)")
        }
        
        // TODO: verify provisioning profile matches the apps bundle id

        state = .Finished
    }
}