//
//  OptionsParser.swift
//  iReSign
//
//  Created by Colin Harris on 14/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation

class Parameter {
    var longName: String
    var description: String
    var required: Bool
    var value: String?

    init(longName: String, description: String, required: Bool) {
        self.longName = longName
        self.description = description
        self.required = required
    }
}

class Option: Parameter {
    var shortName: String
    
    init(shortName: String, longName: String, description: String, required: Bool) {
        self.shortName = shortName
        super.init(longName: longName, description: description, required: required)
    }
}

class Argument: Parameter {
    var index: Int

    init(longName: String, description: String, required: Bool, index: Int) {
        self.index = index
        super.init(longName: longName, description: description, required: required)
    }
}

class Flag: Option {
    var active: Bool
    
    init(shortName: String, longName: String, description: String) {
        active = false
        super.init(shortName: shortName, longName: longName, description: description, required: false)
    }
}

class Parameters {

    var parameters = [String: Parameter]()
    
    var all: [Parameter] {
        get {
            return Array(parameters.values)
        }
    }

    var arguments: [Argument] {
        get {
            return all.filter { $0 is Argument } as! [Argument]
        }
    }
    
    var options: [Option] {
        get {
            return all.filter { $0 is Option } as! [Option]
        }
    }

    var flags: [Flag] {
        get {
            return all.filter { $0 is Flag } as! [Flag]
        }
    }
    
    func addArgument(longName: String, description: String, required: Bool, index: Int) {
        let arg = Argument(longName: longName, description: description, required: required, index: index)
        parameters[longName] = arg
    }
    
    func argumentAtIndex(index: Int) -> Argument? {
        return arguments.filter { $0.index == index }.first
    }
    
    func addOption(shortName: String, longName: String, description: String, required: Bool) {
        let option = Option(shortName: shortName, longName: longName, description: description, required: required)
        parameters[longName] = option
    }
    
    func optionWithShortName(shortName: String) -> Option? {
        return options.filter() { $0.shortName == shortName }.first
    }
    
    func optionWithLongName(longName: String) -> Option? {
        return options.filter() { $0.longName == longName }.first
    }
    
    func addFlag(shortName: String, longName: String, description: String) {
        let option = Flag(shortName: shortName, longName: longName, description: description)
        parameters[longName] = option
    }
    
    func flagWithShortName(shortName: String) -> Flag? {
        return flags.filter() { $0.shortName == shortName }.first
    }
    
    func flagWithLongName(longName: String) -> Flag? {
        return flags.filter() { $0.longName == longName }.first
    }
    
    subscript(longName: String) -> Parameter? {
        get
        {
            return parameters[longName]
        }
        set(newOption)
        {
            parameters[longName] = newOption
        }
    }
    
    func parseArgs(args: [String]) {
        var argCount = 0
        var currentOption: Option?
        for arg in args.suffixFrom(1) {
            if arg.hasPrefix("--") {
                let (longName, value) = parseLongNameAndValue(arg)
                if let option = optionWithLongName(longName) {
                    option.value = value
                }
                else if let flag = flagWithLongName(longName) {
                    flag.active = true
                }
            }
            else if arg.hasPrefix("-") {
                let shortName = arg.substringFromIndex(arg.startIndex.advancedBy(1))
                if let option = optionWithShortName(shortName) {
                    currentOption = option
                }
                else if let flag = flagWithShortName(shortName) {
                    flag.active = true
                }
                
            } else {
                if currentOption != nil {
                    currentOption!.value = arg
                    currentOption = nil
                }
                else if let argument = argumentAtIndex(argCount) {
                    argument.value = arg
                    argCount++
                }
            }
        }
    }
    
    func printOptions() {
        let descStartIndex = 20 // TODO: calculate this based on the length of the maximum shortName + longName + extra characters
        for option in options {
            let optionNames: String = "-\(option.shortName) --\(option.longName)"
            let optionNamesWithPadding = optionNames.stringByPaddingToLength(descStartIndex, withString: " ", startingAtIndex: 0)
            print("\(optionNamesWithPadding) \(option.description)")
        }
    }
    
    func isValid() -> Bool {
        let missingRequiredParams = parameters.values.filter { $0.required && $0.value == nil }
        return missingRequiredParams.count == 0
    }
    
    func isFlagSet(name: String) -> Bool {
        if let flag = flagWithShortName(name) ?? flagWithLongName(name) {
            return flag.active
        }
        return false
    }
    
    func printValues() {
        for param in parameters.values {
            print("\(param.longName) = \(param.value)")
        }
    }
    
    private func parseLongNameAndValue(arg: String) -> (String, String?) {
        let startIndex = arg.startIndex.advancedBy(2)
        let longNameAndValue = arg.substringFromIndex(startIndex)
        let values = longNameAndValue.componentsSeparatedByString("=")
        return values.count == 2 ? (values[0], values[1]) : (values[0], nil)
    }
    
}