//
//  CodeSignTask.swift
//  iReSign
//
//  Created by Colin Harris on 3/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

class CodeSignTask: IROperation {
    
    let task: NSTask
    let path: String
    let certificate: String
    let entitlementsPath: String?
    
    init(path: String, certificate: String, entitlementsPath: String?) {
        self.path = path
        self.certificate = certificate
        self.entitlementsPath = entitlementsPath
        task = NSTask()
        super.init()
        state = .Ready
    }
    
    override func start() {
        if cancelled {
            return
        }
        
        state = .Executing

        // TODO: Remove CFBundleResourceSpecification from Info.plist
        
        var arguments = ["-fs", certificate, "--no-strict"]
        if let path = entitlementsPath {
            arguments.append("--entitlements=\(path)")
        }
        arguments.append(path)
        
        task.launchPath = "/usr/bin/codesign"
        task.arguments = arguments
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let handle = pipe.fileHandleForReading
        
        task.launch()

        let _ = NSString(data: handle.readDataToEndOfFile(), encoding: NSASCIIStringEncoding)
        
        while(task.running) {
            NSThread.sleepForTimeInterval(1.0)
        }
        
        state = .Finished
    }
    
}