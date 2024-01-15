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
    var isTimerRunning = false
    var isTimerPaused  = false
    var elapsedTime: TimeInterval = 0.0
    var pausedTime: TimeInterval = 0.0
    var isStopWatch = false
    var endTime: Date?
    var totalElapsedTime: TimeInterval = 0
    var remainingSeconds: TimeInterval = 0
    
    
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
        
        //TODO: If time is running, pause it
        if (isTimerRunning) {
            pauseTimer()
            return
        }
        //If time is not running and it's zeroed, start stopwatch
        else if !isTimerRunning && (time == "" || time == "00:00:00.000" || time == "00:00:00" || time == "00:00") {
            isTimerRunning = true
            isTimerPaused = false
            isStopWatch = true
            pausedTime = 0.0
            totalElapsedTime = 0.0
            runTimer(-1)
            return
        }
        //TODO: Start timer
        else if (!isTimerRunning){
            isTimerPaused = false
            isTimerRunning = true
            isStopWatch = false
            pausedTime = 0.0
            totalElapsedTime = 0.0
            let splitTime = time.split(separator: ":")
            var hrs = 0
            var mins = 0
            var secs = 0
            var millis = 0
            
            //TODO: CHECK IF SPLIT TIME ONLY HAS INTEGERS. return
            
            //User only gave hours and minutes
            if (splitTime.count == 2) {
                secs = 0
                millis = 0
            }
            //Get secs and millis or default them to 0
            else if (splitTime.count == 3) {
                let secsAndMillis = splitTime[2].split(separator: ".")
                if secsAndMillis.count == 2 {
                    secs = Int(secsAndMillis[0]) ?? 0
                    millis = Int(secsAndMillis[1]) ?? 0
                } else {
                    secs = Int(secsAndMillis[0]) ?? 0
                    millis = 0
                }
            }
            else {
                showAlert()
                return
            }
            
            hrs = Int(splitTime[0]) ?? 0
            mins = Int(splitTime[1]) ?? 0

            let totalMillis = (hrs * 3600 + mins * 60 + secs) * 1000 + millis
            //TODO: START TIMER SERVICE
            runTimer(totalMillis)
        }
        
    }
    
    //Stops and clear timer
    @IBAction func stopButtonClicked(_ sender: NSButton) {
        if (!isTimerRunning || (isTimerRunning && isTimerPaused)) {
            timeTextField.stringValue = "00:00:00.000"
        }
        isTimerRunning = false
        isTimerPaused = false
        time?.invalidate()
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
    
    func pauseTimer() {
        print(self.isTimerPaused)
        if isTimerPaused {
            if (isStopWatch) {
                print("unpausing")
                let tString = timeTextField.stringValue
                let components = tString.components(separatedBy: ":")
                    
                if components.count == 3 {
                        if let hours = Int(components[0]), let minutes = Int(components[1]) {
                            let secondsAndMillis = components[2].components(separatedBy: ".")
                            
                            if secondsAndMillis.count == 2,
                               let seconds = Int(secondsAndMillis[0]),
                               let milliseconds = Int(secondsAndMillis[1]) {
                                // Calculate the elapsed time in seconds
                                let elapsedSeconds = TimeInterval(hours * 3600 + minutes * 60 + seconds) + TimeInterval(milliseconds) / 1000.0
                                
                                // Set the new start time based on the elapsed time
                                startTime = Date().addingTimeInterval(-elapsedSeconds)
                            }
                        }
                    }
                time?.invalidate()
                time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateStopwatch), userInfo: nil, repeats: true)
            }
            else {
                //TODO: UNPAUSE TIMER CLOCK
                print("unpausing")
                time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(restartTimer), userInfo: nil, repeats: true)
            }
            self.isTimerPaused = false
        }
        else {
            //TODO: PAUSE TIME
            print("pausing")
            time?.invalidate()
            self.isTimerPaused = true
        }
    }
    
    //Timer Service
    //TODO: TIME SERVICE
    func runTimer(_ timer: Int) {
        //Run stopwatch
        if (timer == -1) {
            startTime = Date()
            isTimerRunning = true
            self.isTimerPaused = false
            time?.invalidate()
            time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateStopwatch), userInfo: nil, repeats: true)
            
        }
        //Run timer
        else {
            endTime = Date().addingTimeInterval(TimeInterval(timer) / 1000.0)
            time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
    }
    
    @objc func updateTimer() {
        //print("timer")
            guard let endTime = endTime else { return }
            
            let currentDate = Date()
            if currentDate >= endTime {
                isTimerPaused = false
                isTimerRunning = false
                timeTextField.stringValue = "00:00:00.000"
                time?.invalidate()
                return
            }
            
            let timeDifference = endTime.timeIntervalSince(currentDate)
            
            let hours = Int(timeDifference) / 3600
            let minutes = (Int(timeDifference) % 3600) / 60
            let seconds = Int(timeDifference) % 60
            let milliseconds = Int((timeDifference * 1000).truncatingRemainder(dividingBy: 1000))
            
        timeTextField.stringValue = String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        }

    
    @objc func updateStopwatch() {
        guard let startTime = startTime else {
            return
        }
        //print("stopwatch")
        let currentTime = Date()
        // Calculate the elapsed time including the time it was paused
        var elapsedTime = currentTime.timeIntervalSince(startTime)
        elapsedTime = max(0, elapsedTime)
        
        // Convert the elapsed time to hours, minutes, seconds, and milliseconds
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = (Int(elapsedTime) % 3600) % 60
        let milliseconds = Int(elapsedTime.truncatingRemainder(dividingBy: 1) * 1000)
        
        // Display the elapsed time in the text field
        timeTextField.stringValue = String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
    
    
    @objc func restartTimer() {

        // Handle case when the timer is not paused
        var tString = timeTextField.stringValue
        let components = tString.components(separatedBy: ":")
        self.remainingSeconds = TimeInterval()
        if components.count == 3 {
                if let hours = Int(components[0]), let minutes = Int(components[1]) {
                    let secondsAndMillis = components[2].components(separatedBy: ".")
                    
                    if secondsAndMillis.count == 2,
                       let secs = Int(secondsAndMillis[0]),
                       let millisecs = Int(secondsAndMillis[1]) {
                        // Calculate the elapsed time in seconds
                        self.remainingSeconds = TimeInterval(hours * 3600 + minutes * 60 + secs) + TimeInterval(millisecs) / 1000.0
                    }
                }
        }
        let currentDate = Date()
        let newEndTime = currentDate + self.remainingSeconds
        if currentDate >= newEndTime {
            print("stopping")
            isTimerPaused = false
            isTimerRunning = false
            timeTextField.stringValue = "00:00:00.000"
            time?.invalidate()
            remainingSeconds = 0
            return
        }
        
        let timeDifference = newEndTime.timeIntervalSince(currentDate)
        let hours = Int(timeDifference) / 3600
        let minutes = (Int(timeDifference) % 3600) / 60
        let seconds = Int(timeDifference) % 60
        let milliseconds = Int((timeDifference * 1000).truncatingRemainder(dividingBy: 1000)) - 10
        
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
