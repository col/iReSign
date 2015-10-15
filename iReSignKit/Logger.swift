//
//  Logger.swift
//  iReSign
//
//  Created by Colin Harris on 15/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

public enum LogLevel: Int {
    case Debug = 1
    case Info = 2
    case Warn = 3
    case Error = 4
}

public class Logger {
    
    static let sharedInstance = Logger()
    
    var logLevel: LogLevel = .Info
    
    public class func setLogLevel(level: LogLevel) {
        sharedInstance.logLevel = level
    }
    
    public class func debug(message: String) {
        sharedInstance.log(.Debug, message: message)
    }
    
    public class func info(message: String) {
        sharedInstance.log(.Info, message: message)
    }
    
    public class func warn(message: String) {
        sharedInstance.log(.Warn, message: message)
    }
    
    public class func error(message: String) {
        sharedInstance.log(.Error, message: message)
    }
    
    public func log(level: LogLevel, message: String) {
        if level.rawValue >= logLevel.rawValue {
            print(message)
        }
    }
    
}