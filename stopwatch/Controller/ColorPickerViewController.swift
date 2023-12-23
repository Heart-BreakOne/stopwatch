//
//  ColorPickerViewController.swift
//  stopwatch
//
//  Created by leon on 12/23/23.
//

import Foundation
import Cocoa
import Foundation
import SwiftUI

protocol ColorPickerDismissDelegate: AnyObject {
    func colorPickerViewControllerDidDismiss()
}

class ColorPickerViewController: NSViewController{
    
    var bgColor = NSColor.defaultBg
    var txtColor = NSColor.defaultTxt
    
    @IBOutlet weak var bgColorWell: NSColorWell!
    @IBOutlet weak var txtColorWell: NSColorWell!
    
    @IBOutlet weak var alwaysOnTopCheck: NSButton!
    @IBOutlet weak var transparencyCheck: NSButton!
    weak var dismissDelegate: ColorPickerDismissDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (bgColorWell.color, txtColorWell.color) = UserDefaultsManager().getUserColors()
        
        let (isTransparent, isOnTop) = UserDefaultsManager().getUserCheckBox()

        transparencyCheck.state = isTransparent ? .on : .off
        alwaysOnTopCheck.state = isOnTop ? .on : .off
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if self.parent == nil {
                dismissDelegate?.colorPickerViewControllerDidDismiss()
            }
    }
    
    // Save user selected key-color pair on storage.
    @IBAction func colorWellAction(_ sender: NSColorWell) {
        @Binding var isPresented: Bool
        
        let key = sender.identifier?.rawValue
        do {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: sender.color, requiringSecureCoding: false)
            
            UserDefaults.standard.set(colorData, forKey: key ?? "")
            UserDefaults.standard.synchronize()
        } catch {
            Alert(title: Text("ERROR"),
                  message: Text("An error occoured while trying to set the new color"),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    @IBAction func checkBoxSelected(_ sender: NSButton) {
        let isTransparent = sender.state
        let key = sender.identifier?.rawValue ?? ""
        UserDefaults.standard.set(isTransparent, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
}
