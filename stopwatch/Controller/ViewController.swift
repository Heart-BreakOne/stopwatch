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
    
    var observer: Any?;
    var bgColor = NSColor.defaultBg
    var txtColor = NSColor.defaultTxt
    var transparencyCheck = true
    var isOnTop = true
    
    
    var time: Timer?
    var startTime: Date?
    var isTimerRunning: Bool = false
    
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
        print("start button clicked")
        // TODO: START STOP WATCH SERVICE

        let time = timeTextField.stringValue
        
        //If timer service is not running, check if it's 00:00:00.000. Start stopwatch
        if !isTimerRunning && (time == "" || time == "00:00:00.000" || time == "00:00:00" || time == "00:00") {
            // TODO: START STOP WATCH SERVICE
            runTimer(-1)
        }
        //If timer is running, pause it
        else if (isTimerRunning) {
            //TODO: PAUSE TIMER SERVICE
        }
        //Start timer
        else {
            //TODO: CHECK STRING AND START TIMER SERVICE UP UNTIL TIMER RUNS OUT
            
            let splitTime = time.split(separator: ":")
            var hrs = 0
            var mins = 0
            var secs = 0
            var millis = 0
            
            if (splitTime.count == 2) {
                secs = 0
                millis = 0
            } else if (splitTime.count == 3) {
                let secsAndMillis = splitTime[2].split(separator: ".")
                do {
                    guard let secondsValue = Int(secsAndMillis[0]), let millisValue = Int(secsAndMillis[1]) else { throw NSError(domain: "InvalidTime", code: 1, userInfo: nil)
                    }
                    secs = secondsValue
                    millis = millisValue
                }
                catch {
                    showAlert()
                    return
                }
                
            } else {
                showAlert()
                return
            }
            do {
                guard let hourValue = Int(splitTime[0]), let minuteValue = Int(splitTime[1]) else {
                    throw NSError(domain: "InvalidTime", code: 1, userInfo: nil)
                }
                hrs = hourValue
                mins = minuteValue
            } catch {
                showAlert()
                return
            }

            let totalMillis = (hrs * 3600 + mins * 60 + secs) * 1000 + millis
            //TODO: START TIMER SERVICE
            runTimer(totalMillis)
        }
        
    }
    
    
    //Stops and clear timer
    @IBAction func stopButtonClicked(_ sender: NSButton) {
        print("stop clicked")
        // If timer service is running, stop it.
        //If timer service is not running, reset the string
        if (isTimerRunning) {
            isTimerRunning = false
            time?.invalidate()
        }
        else {
            isTimerRunning = false
            time?.invalidate()
            timeTextField.stringValue = "00:00:00.000"
        }
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
    
    
    //Timer Service
    //TODO: TIMER SERVICE
    func runTimer(_ timer: Int) {
        
        if (timer == -1) {
            startTime = Date()
            if (isTimerRunning) {
                //Pause timer
            }
            else {
                isTimerRunning = true
                time?.invalidate()
                time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            }
        } else {
            //Start timer service
            //manager.startTimer()
            let delayInterval = TimeInterval(timer) / 1000.0
            let endTime = Date().addingTimeInterval(delayInterval)
            
            RunLoop.current.run(until: endTime)
        }
    }
    
    @objc func updateTimer() {
            guard let startTime = startTime else { return }
            
            // Get the current time
            let currentTime = Date()
            
            // Calculate the elapsed time in seconds
            let elapsedTime = currentTime.timeIntervalSince(startTime)
            
            // Convert the elapsed time to the desired format HH:MM:ss.SSS
            let hours = Int(elapsedTime) / 3600
            let minutes = (Int(elapsedTime) % 3600) / 60
            let seconds = (Int(elapsedTime) % 3600) % 60
            let milliseconds = Int(elapsedTime.truncatingRemainder(dividingBy: 1) * 1000)
            
            // Update the NSTextField with the timer value
            timeTextField.stringValue = String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        }
    
    func showAlert() {
        Alert(title: Text("ERROR"),
              message: Text("Insert a valid time: HH:MM, HH:MM:SS, HH:MM:SS.sss"),
              dismissButton: .default(Text("OK")))
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
