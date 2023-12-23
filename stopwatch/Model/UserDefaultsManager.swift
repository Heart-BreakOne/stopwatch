//
//  UserDefaultsManager.swift
//  stopwatch
//
//  Created by leon on 12/23/23.
//

import Foundation
import AppKit

class UserDefaultsManager {
    
    func getUserColors() -> (NSColor, NSColor) {
        
        func getColor(forKey key: String, defaultColor: NSColor) -> NSColor {
            guard let storedData = UserDefaults.standard.object(forKey: key) as? Data,
                  let decodedColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: storedData) else {
                return defaultColor
            }
            return decodedColor
        }
        
        let bgColor = getColor(forKey: "bgColorWell", defaultColor: .defaultBg)
        let txtColor = getColor(forKey: "txtColorWell", defaultColor: .defaultTxt)
        
        return (bgColor, txtColor)
    }
    
    
    func getUserCheckBox() -> (Bool, Bool) {
        var isTransparent = false
        var isOnTop = false
        
        if let transparentSetting = UserDefaults.standard.object(forKey: "isTransparentKey") as? Bool {
            isTransparent = transparentSetting
        }
        
        if let onTopSetting = UserDefaults.standard.object(forKey: "alwaysOnTopKey") as? Bool {
            isOnTop = onTopSetting
        }
        
        return (isTransparent, isOnTop)
    }
}
