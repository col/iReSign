//
//  ZipTask.swift
//  iReSign
//
//  Created by Colin Harris on 4/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

class ZipTask: IROperation {
    
    let task: NSTask
    let baseDir: String
    let destinationPath: String
    
    init(baseDir: String, destinationPath: String) {
        self.baseDir = baseDir
        self.destinationPath = destinationPath
        task = NSTask()
        super.init()
        state = .Ready
    }
    
    override func start() {
       
        if cancelled {
            return
        }
        
        state = .Executing
        
        task.launchPath = "/usr/bin/zip"
        task.currentDirectoryPath = baseDir
        task.arguments = ["-qry", destinationPath, "."]

        task.launch()

        while task.running {
            NSThread.sleepForTimeInterval(0.5)
        }
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(baseDir)
        } catch let error as NSError {
            failureBlock?(error)
        }
        
        state = .Finished
    }
    
}