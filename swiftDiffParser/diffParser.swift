//
//  diffParser.swift
//  swiftDiffParser
//
//  Created by Matthew Ellis on 31/01/2016.
//  Copyright © 2016 matthew ellis. All rights reserved.
//

import Foundation

struct diffFile {
    var fileName: String?
    let diffChnages: [diffChnage]
}

struct diffChnage {
    let chnageInfo: diffChnageInfo
    let chnageLines: [diffChnageLine]
}

struct diffChnageInfo {
    let previusStartLine: Int
    let currentStartLine: Int
}

struct diffChnageLine {
    let lineText: String
    let lineNumber: Int
    let chnageType: diffLineChnageType
}

enum diffLineChnageType {
    case unchnaged
    case added
    case removed
}

func parseDiffFileWithFilePath(filePath: String) -> diffFile? {
    do {
        let fileText = try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
        
        return parseDiffFile(fileText)
    } catch let error as NSError {
        print(error.localizedDescription)
    }
    
    return nil;
}

func parseDiffFile(fileContent: String) -> diffFile? {
    let fileLines: [String] = fileContent.componentsSeparatedByString("\n")
    
    if fileLines.count > 0 {
        return parseDiffFileLines(fileLines)
    } else {
        return nil;
    }
}

func parseDiffFileLines(diffFileLines: [String]) -> diffFile? {
    let separatedFileLines = linesSeparatedByPrefix(diffFileLines)
    var diffChnages: [diffChnage] = []
    
    for fileLines in separatedFileLines {
        if fileLines.first?.characters.count > 0 {
            diffChnages.append(parseDiffChnage(fileLines))
        }
    }
    
    if diffChnages.count > 0 {
        return diffFile(fileName: "", diffChnages: diffChnages)
    } else {
        return nil
    }
}

private func linesSeparatedByPrefix(lines: [String]) -> [[String]] {
    var separatedLines: [[String]] = []
    var lineBuffer: [String] = []
    
    for line in lines {
        if !(line.hasPrefix(">") || line.hasPrefix("<") || line.hasPrefix("-")) && lineBuffer.count > 0 {
            separatedLines.append(lineBuffer)
            lineBuffer.removeAll()
        }
        
        lineBuffer.append(line)
    }
    separatedLines.append(lineBuffer)
    
    return separatedLines
}

private func parseDiffChnage(fileChnageLines: [String]) -> diffChnage {
    
    let chnageInfo: diffChnageInfo = parseDiffChnageInfo(fileChnageLines.first!)
    var changeLines: [diffChnageLine] = []
    var previousIndex: Int = 0;
    var currentIndex: Int = 0;
    
    for changeLine in fileChnageLines {
        let index: String.Index = changeLine.startIndex.advancedBy(1)
        let lineText: String = changeLine.substringFromIndex(index)
        
        if changeLine.hasPrefix("<") { // Line Deleted
            let lineNumber: Int = previousIndex + chnageInfo.previusStartLine
            changeLines.append(diffChnageLine(lineText: lineText, lineNumber: lineNumber, chnageType: diffLineChnageType.removed))
            previousIndex++
        } else if changeLine.hasPrefix(">") { // Line Added
            let lineNumber: Int = currentIndex + chnageInfo.currentStartLine
            changeLines.append(diffChnageLine(lineText: lineText, lineNumber: lineNumber, chnageType: diffLineChnageType.added))
            currentIndex++
        } else {
            previousIndex = 0
            currentIndex = 0
        }
    }
    
    return diffChnage(chnageInfo: chnageInfo, chnageLines: changeLines)
}

private func parseDiffChnageInfo(infoLine: String) -> diffChnageInfo {
    let infoSeporatorSet: NSCharacterSet = NSCharacterSet(charactersInString: "cd")
    var previusLine: Int = 0
    var currentLine: Int = 0
    
    if let infoComponents: [String]? = infoLine.componentsSeparatedByCharactersInSet(infoSeporatorSet) {
        if infoComponents?.count == 2 {
            if let previousLines: [String] = infoComponents![0].componentsSeparatedByString(",") {
                let previusLineString: String? = previousLines.first
                if previusLineString?.characters.count > 0 {
                    previusLine = Int(previusLineString!)!
                }
            }
            
            if let currentLines: [String] = infoComponents![1].componentsSeparatedByString(",") {
                let currentLineString: String? = currentLines.first
                if currentLineString?.characters.count > 0 {
                    currentLine = Int(currentLineString!)!
                }
            }
        }
    }
    
    return diffChnageInfo(previusStartLine: previusLine, currentStartLine: currentLine)
}