//
//  VerifyCodeSignTask.swift
//  iReSign
//
//  Created by Colin Harris on 4/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

class VerifyCodeSignTask: IROperation {
    
    let task: NSTask
    let path: String
    
    init(path: String) {
        self.path = path
        task = NSTask()
        super.init()
        state = .Ready
    }
    
    override func start() {
        if cancelled {
            return
        }
        
        state = .Executing
        
        task.launchPath = "/usr/bin/codesign"
        task.arguments = ["-v", path]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let handle = pipe.fileHandleForReading
        
//        print("\(task.launchPath) \(task.arguments!)")
        task.launch()
        
        let _ = NSString(data: handle.readDataToEndOfFile(), encoding: NSASCIIStringEncoding)
        
        while(task.running) {
            NSThread.sleepForTimeInterval(1.0)
        }
        
//        print("Codesigning result: \(result!)")
        
        state = .Finished
    }
    
}