//
//  IRTestFieldDrag.swift
//  iReSign
//
//  Created by Colin Harris on 1/10/15.
//  Copyright © 2015 Colin Harris. All rights reserved.
//

import Foundation
import Cocoa

class IRTextFieldDrag : NSTextField {

    override func awakeFromNib() {
        self.registerForDraggedTypes([NSFilenamesPboardType])
    }

    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard()
        
        if pboard.types!.contains(NSURLPboardType) {
            let files = pboard.propertyListForType(NSFilenamesPboardType) as? NSArray
            if files?.count <= 0 {
                return false
            }
            self.stringValue = files!.objectAtIndex(0) as! String
        }
        return true
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        if !self.enabled {
            return .None
        }
        
        let pboard = sender.draggingPasteboard()
        let sourceDragMask = sender.draggingSourceOperationMask()
        
        if pboard.types!.contains(NSColorPboardType) || pboard.types!.contains(NSFilenamesPboardType) {
            if sourceDragMask.contains(.Copy) {
                return NSDragOperation.Copy
            }
        }
        return .None
    }
    
}