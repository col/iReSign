//
//  IRCertificates.swift
//  iReSign
//
//  Created by Colin Harris on 1/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Cocoa

typealias CompletionHandler = ([String]?) -> Void

class CodeSigningTools: NSObject {
    
    var certTask: NSTask?
    var results: [String]?
    var completionHandler: CompletionHandler?
    
    func getCertificates(completionHandler: CompletionHandler?) {
        self.completionHandler = completionHandler
        
        certTask = NSTask()
        certTask?.launchPath = "/usr/bin/security"
        certTask?.arguments = ["find-identity", "-v", "-p", "codesigning"]
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "checkCerts:", userInfo: nil, repeats: true)
        
        let pipe = NSPipe()
        certTask?.standardOutput = pipe
        certTask?.standardError = pipe
        let handle = pipe.fileHandleForReading
        
        certTask?.launch()
        
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
        if !certTask!.running {
            timer.invalidate()
            certTask = nil
            completionHandler?(results)
        }
    }

}