//
//  ViewController.swift
//  stopwatch
//
//  Created by leon on 11/27/23.
//

import Cocoa
import Foundation
import SwiftUI

class ViewController: NSViewController, NSMenuDelegate {
    
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var configButton: NSButton!
    @IBOutlet weak var timeTextField: NSTextField!
    @IBOutlet weak var timerTexField: NSTextFieldCell!
    
    let timerManager = TimerManager()
    var observer: Any?;
    var bgColor = NSColor.defaultBg
    var txtColor = NSColor.defaultTxt
    var transparencyCheck = true
    var isOnTop = true

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (transparencyCheck, isOnTop) = UserDefaultsManager().getUserCheckBox()
        (bgColor, txtColor) = UserDefaultsManager().getUserColors()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = bgColor.cgColor
        self.view.window?.backgroundColor = NSColor(cgColor: bgColor as! CGColor)
        
        timeTextField.textColor = txtColor
        startButton.image?.isTemplate = true
        startButton.contentTintColor = txtColor
        stopButton.image?.isTemplate = true
        stopButton.contentTintColor = txtColor
        configButton.image?.isTemplate = true
        configButton.contentTintColor = txtColor
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { (event) -> NSEvent? in
            self.handleMouseClick(event)
            return event
        }
        
        timerManager.updateClock = { [weak self] timeString in
            DispatchQueue.main.async {
                            self?.timeTextField.stringValue = timeString
                        }
        }
        
        timerManager.getTimeString = { [weak self] in
            return self?.timeTextField.stringValue ?? ""
        }
        
        //Observer to keep window always on top
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: OperationQueue.main ) { (note) in
                self.view.window?.titleVisibility = .hidden
                if #available(macOS 11.0, *) {
                    self.view.window?.titlebarSeparatorStyle = .none
                } else {
                    if let window = self.view.window {
                        for subview in window.contentView!.subviews {
                            if subview is NSBox {
                                subview.isHidden = true
                                break
                            }
                        }
                    }
                }
                
                if (self.transparencyCheck) {
                    self.view.window?.hasShadow = false
                    self.view.window?.isOpaque = false
                    self.view.layer?.backgroundColor = NSColor.clear.cgColor
                    self.view.window?.backgroundColor = NSColor.clear
                    self.startButton.alphaValue = 0.0
                    self.stopButton.alphaValue = 0.0
                    self.configButton.alphaValue = 0.0
                    self.startButton.isEnabled = false
                    self.stopButton.isEnabled = false
                    self.configButton.isEnabled = false
                    
                    // Make the title bar transparent
                    self.view.window?.titleVisibility = NSWindow.TitleVisibility.hidden
                    self.view.window?.styleMask.remove(.titled)
                }
                if (self.isOnTop) {
                    self.view.window?.level = .floating;
                } else {
                    self.view.window?.level = .normal
                }
            }
    }
    
    
    //Disable buttons so user doesn't misclick them
    func handleMouseClick(_ event: NSEvent) {
        // Handle the mouse click event
        if self.view.window != nil {
            // Toggle the alphaValue (you can implement a more sophisticated logic)
            if (self.transparencyCheck) {
                self.view.window?.isOpaque = true
                self.view.layer?.isOpaque = true
                self.view.layer?.backgroundColor = bgColor.cgColor
                self.view.window?.backgroundColor = bgColor
                
                self.view.window?.styleMask.insert(.titled)
                self.view.window?.titleVisibility = NSWindow.TitleVisibility.visible
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                    // Perform actions after the delay
                    self.startButton.alphaValue = 1
                    self.stopButton.alphaValue = 1
                    self.configButton.alphaValue = 1
                    self.startButton.isEnabled = true
                    self.stopButton.isEnabled = true
                    self.configButton.isEnabled = true
                }
            }
        }
    }
    
    /* IBActions here */
    @IBAction func startButtonClicked(_ sender: NSButton) {
        let tmString = timeTextField.stringValue
        timerManager.startClock(tmString: tmString)
    }
    
    //Stops and clear timer
    @IBAction func stopButtonClicked(_ sender: NSButton) {
        timerManager.stopTimer()
    }
    
    //Load modal so user can change colors and transparency
    @IBAction func configButtonClicked(_ sender: NSButton) {
        performSegue(withIdentifier: "colorPickerView", sender: nil)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "colorPickerView" {
            if let destinationVC = segue.destinationController as? ColorPickerViewController {
                destinationVC.dismissDelegate = self
            }
        }
    }
    
}

//Reload user variables after settings page is dismissed.
extension ViewController: ColorPickerDismissDelegate {
    func colorPickerViewControllerDidDismiss() {
        // Call your function from the caller view controller
        //Update variables and colors.
        (transparencyCheck, isOnTop) = UserDefaultsManager().getUserCheckBox()
        (bgColor, txtColor) = UserDefaultsManager().getUserColors()
        
        self.view.layer?.backgroundColor = bgColor.cgColor
        self.view.window?.backgroundColor = bgColor
        timeTextField.textColor = txtColor
        startButton.contentTintColor = txtColor
        stopButton.contentTintColor = txtColor
        configButton.contentTintColor = txtColor
    }
    
}
