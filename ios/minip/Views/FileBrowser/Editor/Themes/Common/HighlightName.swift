//
//  HighlightName.swift
//  minip
//
//  Created by ByteDance on 2023/7/10.
//

import Foundation

#if DEBUG
private var previousUnrecognizedHighlightNames: [String] = []
#endif

public enum HighlightName: String {
    case attribute
    case comment
    case conditional
    case constant
    case constructor
    case delimiter
    case embedded
    case escape
    case field
    case function
    case include
    case keyword
    case method
    case none
    case number
    case `operator`
    case parameter
    case property
    case punctuation
    case `repeat`
    case string
    case tag
    case type
    case variable
    case variableBuiltin = "variable.builtin"

    // markdown
    case textTitle = "text.title"
    case textLiteral = "text.literal"

    public init?(_ rawHighlightName: String) {
        var comps = rawHighlightName.split(separator: ".")
        while !comps.isEmpty {
            let candidateRawHighlightName = comps.joined(separator: ".")
            if let highlightName = Self(rawValue: candidateRawHighlightName) {
                self = highlightName
                return
            }
            comps.removeLast()
        }
#if DEBUG
        if !previousUnrecognizedHighlightNames.contains(rawHighlightName) {
            previousUnrecognizedHighlightNames.append(rawHighlightName)

            let msg = "[HighlightName] Unrecognized highlight name: '\(rawHighlightName)'."
                + " Add the highlight name to HighlightName.swift if you want to add support for syntax highlighting it."
                + " This message will only be shown once per highlight name."
            logger.debug("\(msg)")
        }
#endif
        return nil
    }
}
