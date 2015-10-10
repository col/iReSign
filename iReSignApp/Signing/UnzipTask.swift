//
//  UnzipTask.swift
//  iReSign
//
//  Created by Colin Harris on 1/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

class UnzipTask: IROperation {
    
    let sourcePath: String
    let destinationPath: String
    let task: NSTask
    
    init(sourcePath: String, destinationPath: String) {
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        
        self.task = NSTask()
        task.launchPath = "/usr/bin/unzip"
        task.arguments = ["-q", sourcePath, "-d", destinationPath]
        
        super.init()
    }
    
    override func start() {
        if cancelled {
            return
        }
        
        state = .Executing
        task.launch()
        
        while task.running {
            NSThread.sleepForTimeInterval(1.0)
        }
     
        state = .Finished
//        completionBlock?()
    }
    
}