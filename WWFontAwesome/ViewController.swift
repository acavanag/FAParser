//
//  ViewController.swift
//  WWFontAwesome
//
//  Created by Andrew Cavanagh on 5/15/15.
//  Copyright (c) 2015 WeddingWIre. All rights reserved.
//

import UIKit
import Foundation
import CoreFoundation

class FA {
    var name: String?
    var id: String?
    var unicode: String?
    var created: String?
    
    func description() -> String {
        return "\(name!) \(id!) \(unicode!) \(created!)"
    }
}

class ViewController: UIViewController {

    var tokens = [CFString]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let path = NSBundle.mainBundle().pathForResource("fa", ofType: "yml")!
        let s = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        
        var error: NSError?
        parse(s, error: &error)
    }

    final func parse(string: String, inout error: NSError?) -> () {
        let stringRef = string as! CFMutableStringRef
        let localeRef = CFLocaleCopyCurrent()
        
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, Boolean(0))
        
        let t = CFStringTokenizerCreate(kCFAllocatorDefault, stringRef, CFRangeMake(0, CFStringGetLength(stringRef)), 0, localeRef)
        var tokenType = UInt(CFStringTokenizerTokenType.None.rawValue)
        
        while CFStringTokenizerTokenType.None.rawValue != CFStringTokenizerAdvanceToNextToken(t).rawValue {
            let tokenRange = CFStringTokenizerGetCurrentTokenRange(t)
            let tokenValue = CFStringCreateWithSubstring(kCFAllocatorDefault, stringRef, tokenRange)
            tokens.append(tokenValue)
        }
        
        var structure = ["name", "id", "unicode", "created", "aliases", "url", "filter", "categories"]
        var interested = ["name", "id", "unicode", "created"]
        
        var currentSectionToken: String = ""
        var currentFA: FA?
        var allFA = [FA]()
        var currentTokenStream = [String]()
        
        for (index, token) in enumerate(tokens) {
            
            if contains(structure, token as String) {
                currentSectionToken = token as String
            }
            
            if !contains(interested, currentSectionToken) {
                continue
            }
            
            if token == "name" {
                currentTokenStream = [String]()
                if let currentFA = currentFA {
                    allFA.append(currentFA)
                }
                currentFA = FA()
            } else if token == "id" {
                currentFA?.name = join("", currentTokenStream)
                currentTokenStream = [String]()
            } else if token == "unicode" {
                currentFA?.id = join("-", currentTokenStream)
                currentTokenStream = [String]()
            } else if token == "created" {
                currentFA?.created = tokens[index + 1] as String
                currentFA?.unicode = join("", currentTokenStream)
                currentTokenStream = [String]()
            } else {
                if currentSectionToken == "created" {
                    continue
                }
                var tempToken = token as String
                if currentSectionToken == "name" {
                    tempToken = tempToken.stringByTrimmingCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
                    tempToken = tempToken.capitalizedString
                }
                currentTokenStream.append(tempToken)
            }
        }

        buildObjCEnumWithTokens(allFA)
        buildArray(allFA)
    }
    
    func buildObjCEnumWithTokens(tokens: [FA]) {
        var string = String()
        string += "typedef NS_ENUM(NSInteger, FAIcon) {\n\n"
        for token in tokens {
            string += "    /**\n"
            string += "     @abstract \(token.name!)\n"
            string += "     @discussion id: \(token.id!), unicode: \(token.unicode!), created: \(token.created!)\n"
            string += "     */\n"
            string += "    FA\(token.name!),\n\n"
        }
        string += "};"
        
        println(string)
    }
    
    func buildArray(tokens: [FA]) {
        
        var string = String()
        
        string += "    static NSArray *unicodeStrings;\n\n"
        string += "    static dispatch_once_t onceToken;\n"
        string += "    dispatch_once(&onceToken, ^{\n"
        string += "        unicodeStrings = @[\n"
        string += "                           "
        
        var index = 0
        var maxPerLine = 10
        
        for token in tokens {
            index++
            if index > maxPerLine {
                index = 0
                string += "\n"
                string += "                           "
            }
            string += "@\"\\u\(token.unicode!)\","
        }
        
        string += "\n                           ];\n"
        string += "    });"
        string += "\n    return unicodeStrings;\n"
        
        println(string)
    }
}

