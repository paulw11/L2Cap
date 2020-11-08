//
//  File.swift
//  
//
//  Created by Paul Wilkinson on 9/11/20.
//
// Taken from https://gist.github.com/bpolania/704901156020944d3e20fef515e73d61
// Copyright (c) 2018 Boris Polania

import Foundation

extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension Data {
    
    var uint16: UInt16 {
        get {
            let i16array = self.withUnsafeBytes { $0.load(as: UInt16.self) }
            return i16array
        }
    }
}
