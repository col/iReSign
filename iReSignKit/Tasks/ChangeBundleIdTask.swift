//
//  ChangeBundleIdTask.swift
//  iReSign
//
//  Created by Colin Harris on 3/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

let kKeyBundleIDPlistApp = "CFBundleIdentifier"
let kKeyBundleIDPlistiTunesArtwork = "softwareVersionBundleId"

class ChangeBundleIdTask: IROperation {
    
    let baseDir: String
    let bundleId: String

    var fileManager: NSFileManager {
        return NSFileManager.defaultManager()
    }

    var payloadPath: String {
        return NSURL(fileURLWithPath: baseDir).URLByAppendingPathComponent(kPayloadDirName).path!
    }
    
    init(baseDir: String, bundleId: String) {
        self.baseDir = baseDir
        self.bundleId = bundleId
        super.init()
        state = .Ready
    }
    
    override func start() {
        if cancelled {
            return
        }
        
        state = .Executing
        
        do {
            let infoPlistPath = try findInfoPlist()
            let plist = try readInfoPlist(infoPlistPath)
            plist[kKeyBundleIDPlistApp] = bundleId
            try writeInfoPlist(plist, path:infoPlistPath)
        } catch let error as NSError {
            failureBlock?(error)
        }
        
        state = .Finished
    }

    private func findInfoPlist() throws -> String {
        let dirContents = try fileManager.contentsOfDirectoryAtPath(payloadPath)
        
        for file in dirContents {
            if (file as NSString).pathExtension.lowercaseString  == "app" {
                return NSURL(fileURLWithPath: baseDir)
                    .URLByAppendingPathComponent(kPayloadDirName)
                    .URLByAppendingPathComponent(file)
                    .URLByAppendingPathComponent(kInfoPlistFilename).path!
            }
        }

        throw NSError(domain: "", code: 2, userInfo: [NSLocalizedDescriptionKey: "Info.plist not found"])
    }
    
    private func readInfoPlist(path: String) throws -> NSMutableDictionary {
        if let data = NSData(contentsOfFile: path) {
            return try NSPropertyListSerialization.propertyListWithData(
                data,
                options: .MutableContainersAndLeaves,
                format: nil
            ) as! NSMutableDictionary
        } else {
            throw NSError(
                domain: "ChangeBundleIdTask",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Info.plist not found"]
            )
        }
    }
    
    private func writeInfoPlist(plistData: NSMutableDictionary, path: String) throws {
        let xmlData = try NSPropertyListSerialization.dataWithPropertyList(plistData, format: .XMLFormat_v1_0, options: 0)
        xmlData.writeToFile(path, atomically:true)
    }
    
}