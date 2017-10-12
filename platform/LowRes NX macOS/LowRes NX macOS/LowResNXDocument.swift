//
//  Document.swift
//  LowRes NX macOS
//
//  Created by Timo Kloss on 23/4/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import Cocoa

class ProgramError: NSError {
    
    init(error: CoreError, lineNumber: Int, line: String) {
        let errorString = String(cString:err_getString(error.code))
        let errorText = "Error in line \(lineNumber): \(errorString)\n\(line)"
        super.init(domain: "LowResNX", code: Int(error.code.rawValue), userInfo: [
            NSLocalizedFailureReasonErrorKey: "There was a program error.",
            NSLocalizedRecoverySuggestionErrorKey: errorText
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class LowResNXDocument: NSDocument {
    var sourceCode = ""
    var coreWrapper = CoreWrapper()
        
    override class var autosavesInPlace: Bool {
        return false
    }
    
    override func data(ofType typeName: String) throws -> Data {
        return sourceCode.data(using: .utf8)!
    }

    override func read(from data: Data, ofType typeName: String) throws {
        sourceCode = String(data: data, encoding: .ascii)!
        let cString = sourceCode.cString(using: .ascii)
        let error = itp_compileProgram(&coreWrapper.core, cString)
        if error.code != ErrorNone {
            throw getProgramError(error: error)
        }
    }
    
    func getProgramError(error: CoreError) -> ProgramError {
        let index = sourceCode.index(sourceCode.startIndex, offsetBy: String.IndexDistance(error.sourcePosition))
        let lineRange = sourceCode.lineRange(for: index ..< index)
        let lineString = sourceCode[lineRange]
        let lineNumber = sourceCode.countLines(index: index)
        return ProgramError(error: error, lineNumber: lineNumber, line: String(lineString))
    }
    
    override func makeWindowControllers() {
        let windowController = LowResNXWindowController(windowNibName: NSNib.Name(rawValue: "LowResNXWindowController"))
        addWindowController(windowController)
    }
    
    func nxDiskURL() -> URL {
        return fileURL!.deletingLastPathComponent().appendingPathComponent("disk.nx")
    }
}

extension String {
    func countLines(index: String.Index) -> Int {
        var count = 1
        var searchRange = startIndex ..< endIndex
        while let foundRange = rangeOfCharacter(from: CharacterSet.newlines, options: .literal, range: searchRange), index >= foundRange.upperBound {
            searchRange = characters.index(after: foundRange.lowerBound) ..< endIndex
            count += 1
        }
        return count;
    }
    
}