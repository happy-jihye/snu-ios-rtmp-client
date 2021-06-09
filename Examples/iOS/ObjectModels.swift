//
//  ObjectModels.swift
//  Example iOS
//
//  Created by Subeen Park on 2021/06/07.
//  Copyright © 2021 Shogo Endo. All rights reserved.
//

import UIKit
import VideoToolbox
import Vision
import CoreMedia




struct DetectedObject: Equatable {

    var label: String
    var x: Int
    var y: Int
    var w: Int
    var h: Int
    
    init(prediction: VNRecognizedObjectObservation, frameW: CGFloat, frameH: CGFloat) {
        label = prediction.labels.first?.identifier ?? "nil"
        
        x = Int((480*prediction.boundingBox.minX))
        y = Int((640*prediction.boundingBox.minY))
        
        w = Int((480*prediction.boundingBox.width))
        h = Int((640*prediction.boundingBox.height))
        
    }
    
    func getDescription() -> String {
        return "\"\(label)\": {\"x\": \(x), \"y\": \(y), \"w\": \(w), \"h\": \(h)}"
    }
    
    static func ==(lhs: DetectedObject, rhs: DetectedObject)->Bool {
        return lhs.label == rhs.label
    }

}

