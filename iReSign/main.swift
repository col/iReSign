//
//  main.swift
//  iReSign
//
//  Created by Colin Harris on 1/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Darwin

var parameters = Parameters()
parameters.addArgument("ipa_path",                  description: "Path to source .ipa",     required: true, index: 0)
parameters.addFlag("h",   longName: "help",         description: "Show the help")
parameters.addFlag("v",   longName: "verbose",      description: "Output debug info")
parameters.addOption("c", longName: "certificate",  description: "Name of the certificate", required: true)
parameters.addOption("p", longName: "profile",      description: "Provisioning Profile",    required: false)
parameters.addOption("e", longName: "entitlements", description: "Entitlements File",       required: false)
parameters.addOption("b", longName: "bundle_id",    description: "Bundle Id",               required: false)

func printUsage() {
    print("Usage:")
    print("iReSign [options] ipa_path")
    print("")
    print("Options:")
    parameters.printOptions()
}

let args = Process.arguments
parameters.parseArgs(args)

if parameters.isFlagSet("verbose") {
    print("Provided Values:")
    parameters.printValues()
    print("")
}

if !parameters.isValid() || parameters.isFlagSet("help") {
    printUsage()
    exit(1)
}

let resignTask = ResignTask(
    sourcePath: parameters["ipa_path"]!.value!,
    certificate: parameters["certificate"]!.value!,
    provisioningPath: parameters["profile"]!.value,
    entitlementsPath: parameters["entitlements"]!.value,
    bundleId: parameters["bundle_id"]!.value
)
if parameters.isFlagSet("verbose") {
    Logger.setLogLevel(.Debug)
}
resignTask.completionBlock = {
    print("Success!")
}
resignTask.failureBlock = { error in
    print("Error: \(error?.localizedDescription)")
}

resignTask.start()
resignTask.waitUntilFinished()