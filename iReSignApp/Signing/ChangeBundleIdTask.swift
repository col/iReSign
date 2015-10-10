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
            if let infoPlistPath = try findInfoPlist() {
                let plist = try readInfoPlist(infoPlistPath)
                plist[kKeyBundleIDPlistApp] = bundleId
                try writeInfoPlist(plist, path:infoPlistPath)
            } else {
                print("Could not update bundle id. Failed to find Info.plist")
            }
        } catch {
           print("Failed to update the bundle id: \(error)")
        }
        
        state = .Finished
    }

    private func findInfoPlist() throws -> String? {
        let dirContents = try fileManager.contentsOfDirectoryAtPath(payloadPath)
        
        for file in dirContents {
            if (file as NSString).pathExtension.lowercaseString  == "app" {
                return NSURL(fileURLWithPath: baseDir)
                    .URLByAppendingPathComponent(kPayloadDirName)
                    .URLByAppendingPathComponent(file)
                    .URLByAppendingPathComponent(kInfoPlistFilename).path
            }
        }

        return nil
    }
    
    private func readInfoPlist(path: String) throws -> NSMutableDictionary {
        return try NSPropertyListSerialization.propertyListWithData(
            NSData(contentsOfFile: path)!,
            options: .MutableContainersAndLeaves,
            format: nil
        ) as! NSMutableDictionary
    }
    
    private func writeInfoPlist(plistData: NSMutableDictionary, path: String) throws {
        let xmlData = try NSPropertyListSerialization.dataWithPropertyList(plistData, format: .XMLFormat_v1_0, options: 0)
        xmlData.writeToFile(path, atomically:true)
    }
    
}