//
//  GetCertsTask.swift
//  iReSign
//
//  Created by Colin Harris on 2/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

typealias GetCertsCallback = ([String]?) -> Void

class GetCertsTask: NSObject {
    
    let task: NSTask
    var callback: GetCertsCallback?
    var results: [String]?
    
    override init() {
        task = NSTask()
        task.launchPath = "/usr/bin/security"
        task.arguments = ["find-identity", "-v", "-p", "codesigning"]
//        super.init()
    }
    
    func getCerts(callback: GetCertsCallback?) {
        self.callback = callback
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "checkCerts:", userInfo: nil, repeats: true)
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let handle = pipe.fileHandleForReading
        
        task.launch()
        
        NSThread.detachNewThreadSelector("watchGetCerts:", toTarget: self, withObject: handle)
    }
    
    func watchGetCerts(streamHandle: NSFileHandle) {
        autoreleasepool {
            let data = NSString(data: streamHandle.readDataToEndOfFile(), encoding: NSASCIIStringEncoding)
            
            // Verify the security result
            guard let securityResult = data where securityResult.length > 0 else {
                // Nothing in the result, return
                return;
            }
            
            let rawResult = securityResult.componentsSeparatedByString("\"")
            // The certificates are found on all the odd indexes in the result set.
            let oddNumbers = Array((1..<rawResult.count).filter() { $0 % 2 != 0 })
            results = oddNumbers.map { rawResult[$0] }
        }
    }
    
    func checkCerts(timer: NSTimer) {
        if !task.running {
            timer.invalidate()
            callback?(results)
        }
    }
    
}