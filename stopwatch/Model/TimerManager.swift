//
//  TimerManager.swift
//  stopwatch
//
//  Created by leon on 12/23/23.
//

import Foundation

class TimerManager {
    let tmString = ""
    var zeroedClock = "00:00:00.000"
    var isTimerRunning = false
    var isTimerPaused  = false
    var isStopWatch = false
    var endTime: Date?
    var startTime: Date?
    var remainingSeconds: TimeInterval = 0
    var pausedTime: TimeInterval = 0.0
    var elapsedTime: TimeInterval = 0.0
    var totalElapsedTime: TimeInterval = 0
    var time: Timer?
    var updateClock: ((String) -> Void)?
    var getTimeString: (() -> String)?
    
    func startClock(tmString: String) {
        if (isTimerRunning) {
            pauseTimer(tmString: tmString)
            return
        }
        //If time is not running and it's zeroed, start stopwatch
        else if !isTimerRunning && (tmString == "" || tmString == zeroedClock || tmString == "00:00:00" || tmString == "00:00") {
            
            setTimeVariables()
            runTimer(-1)
            return
        }
        else if (!isTimerRunning) {
            setTimeVariables()
            let splitTime = tmString.split(separator: ":")
            var hrs = 0
            var mins = 0
            var secs = 0
            var millis = 0
            
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
                return
            }
            
            hrs = Int(splitTime[0]) ?? 0
            mins = Int(splitTime[1]) ?? 0

            let totalMillis = (hrs * 3600 + mins * 60 + secs) * 1000 + millis
            runTimer(totalMillis)
        }
    }
    
    func stopTimer(){
        if (!isTimerRunning || (isTimerRunning && isTimerPaused)) {
            updateClock?(zeroedClock)
        }
        isTimerRunning = false
        isTimerPaused = false
        time?.invalidate()
    }
    func setTimeVariables(){
        isTimerRunning = true
        isTimerPaused = false
        isStopWatch = false
        pausedTime = 0.0
        totalElapsedTime = 0.0
    }
    
    
    func pauseTimer(tmString: String) {

        if isTimerPaused {
            if (isStopWatch) {

                let elapsedSeconds = extractTime(timeString: tmString)
                startTime = Date().addingTimeInterval(TimeInterval(-elapsedSeconds))

                time?.invalidate()
                time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateStopwatch), userInfo: nil, repeats: true)
            }
            else {
                time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(restartTimer), userInfo: nil, repeats: true)
            }
            isTimerPaused = false
        }
        else {
            time?.invalidate()
            isTimerPaused = true
        }
    }
    
    //Timer Service
    func runTimer(_ timer: Int) {
        //Run stopwatch
        if (timer == -1) {
            startTime = Date()
            isTimerRunning = true
            isTimerPaused = false
            time?.invalidate()
            isStopWatch = true
            time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateStopwatch), userInfo: nil, repeats: true)
            
        }
        //Run timer
        else {
            isTimerRunning = true
            isTimerPaused = false
            endTime = Date().addingTimeInterval(TimeInterval(timer) / 1000.0)
            time = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
    }
    
    @objc func updateTimer() {
            guard let endTime = endTime else { return }
            
            let currentDate = Date()
            if currentDate >= endTime {
                isTimerPaused = false
                isTimerRunning = false
                updateClock?(zeroedClock)
                time?.invalidate()
                return
            }
            
        let (hours, minutes, seconds, milliseconds) = breakDownTime(time: endTime.timeIntervalSince(currentDate))
            
            updateClock?(String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds))
        }

    
    @objc func updateStopwatch() {
        guard let startTime = startTime else {
            return
        }

        let currentTime = Date()
        // Calculate the elapsed time including the time it was paused
        var elapsedTime = currentTime.timeIntervalSince(startTime)
        elapsedTime = max(0, elapsedTime)
        
        let (hours, minutes, seconds, milliseconds) = breakDownTime(time: elapsedTime)
        
        // Display the elapsed time in the text field
        updateClock?(String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds))
    }
    
    @objc func restartTimer() {

        // Handle case when the timer is not paused
        let timeString = getTimeString?()
        remainingSeconds = TimeInterval()
        
        remainingSeconds = extractTime(timeString: timeString!)
        
        let currentDate = Date()
        let newEndTime = currentDate + remainingSeconds
        if currentDate >= newEndTime {
            isTimerPaused = false
            isTimerRunning = false
            updateClock?(zeroedClock)
            time?.invalidate()
            remainingSeconds = 0
            return
        }
        
        var (hours, minutes, seconds, milliseconds) = breakDownTime(time: newEndTime.timeIntervalSince(currentDate))

        milliseconds = max(0, milliseconds - 10)
        if milliseconds == 0 {
                if seconds > 0 {
                    seconds -= 1
                    milliseconds = 999
                } else {
                    milliseconds = 0
                }
            }
        updateClock?(String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds))
    }
    
    //Break down time into hrs, min, secs and millis
    func breakDownTime(time: TimeInterval) -> (Int, Int, Int, Int) {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time * 1000).truncatingRemainder(dividingBy: 1000))
        
        return (hours, minutes, seconds, milliseconds)
    }
    
    func extractTime(timeString: String) -> TimeInterval {
        let components = timeString.components(separatedBy: ":")
        if components.count == 3 {
                if let hours = Int(components[0]), let minutes = Int(components[1]) {
                    let secondsAndMillis = components[2].components(separatedBy: ".")
                    
                    if secondsAndMillis.count == 2,
                       let secs = Int(secondsAndMillis[0]),
                       let millisecs = Int(secondsAndMillis[1]) {
                        // Calculate the elapsed time in seconds
                        return TimeInterval(hours * 3600 + minutes * 60 + secs) + TimeInterval(millisecs) / 1000.0
                    }
                }
        }
        return 0.0
    }

}
