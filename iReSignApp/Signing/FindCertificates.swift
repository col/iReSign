//
//  FindCertificates.swift
//  iReSign
//
//  Created by Colin Harris on 11/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

typealias FindCertificatesCallback = ([String]?) -> Void

class FindCertificates: IROperation {
    
    let task: NSTask
    var callback: FindCertificatesCallback?
    
    init(callback: FindCertificatesCallback?) {
        self.callback = callback
        task = NSTask()
        super.init()
        state = .Ready
    }
    
    override func start() {
        
        if cancelled {
            return
        }
        
        state = .Executing
        
        task.launchPath = "/usr/bin/security"
        task.arguments = ["find-identity", "-v", "-p", "codesigning"]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let handle = pipe.fileHandleForReading
        
        task.launch()
        
        let output = NSString(data: handle.readDataToEndOfFile(), encoding: NSASCIIStringEncoding)
        
        while task.running {
            print("output: \(output)")
            NSThread.sleepForTimeInterval(0.5)
        }

                    NSThread.sleepForTimeInterval(5.0)
        
        // Verify the security result
        guard let securityResult = output where securityResult.length > 0 else {
            dispatch_sync(dispatch_get_main_queue(),{
                self.callback?([String]())
            })
            state = .Finished
            return
        }
        
        let rawResult = securityResult.componentsSeparatedByString("\"")
        // The certificates are found on all the odd indexes in the result set.
        let oddNumbers = Array((1..<rawResult.count).filter() { $0 % 2 != 0 })
        let results = oddNumbers.map { rawResult[$0] }
        
        dispatch_sync(dispatch_get_main_queue(),{
            self.callback?(results)
        })
        
        state = .Finished
    }

}