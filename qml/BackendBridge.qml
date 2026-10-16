import QtQuick 2.7

Item {
    id: bridge

    readonly property string bridgeUrl: "http://127.0.0.1:8765"

    // CONNECTION & DEVICE PROPERTIES
    property bool bridgeOnline: false
    property bool connected: true
    property string deviceName: "Xiaomi Smart Band 9"
    property string deviceMac: "E4:5F:01:9A:88:C2"
    property string firmwareVersion: "v1.2.48"
    property int batteryLevel: 88

    // REAL-TIME TELEMETRY
    property int heartRate: 72
    property string heartRateZone: "Rest"
    property color heartRateZoneColor: "#38BDF8"
    property string heartRateZoneDesc: "Resting heart rate"
    property int steps: 4250
    property int stepGoal: 10000
    property int stepProgressPct: 43
    property real distanceKm: 3.23
    property real caloriesBurned: 178.5
    property bool isWorkoutMode: false
    property bool isSimulation: true

    signal heartRateUpdated(int hr)
    signal stepsUpdated(int count)
    signal connectionChanged(bool isConnected)

    // Poll the Python bridge every 1000ms
    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            fetchMetrics()
        }
    }

    // Secondary status poll every 5 seconds
    Timer {
        id: statusTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            fetchStatus()
        }
    }

    Component.onCompleted: {
        fetchStatus()
        fetchMetrics()
    }

    function fetchMetrics() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", bridgeUrl + "/api/metrics", true)
        xhr.timeout = 800

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    bridgeOnline = true
                    try {
                        var data = JSON.parse(xhr.responseText)
                        applyMetrics(data)
                    } catch (e) {
                        console.log("Error parsing bridge metrics: " + e)
                    }
                } else {
                    // Bridge server not responding; run intelligent local simulation
                    bridgeOnline = false
                    runLocalFallbackSimulation()
                }
            }
        }
        xhr.ontimeout = function() {
            bridgeOnline = false
            runLocalFallbackSimulation()
        }
        xhr.onerror = function() {
            bridgeOnline = false
            runLocalFallbackSimulation()
        }

        try {
            xhr.send()
        } catch (e) {
            bridgeOnline = false
            runLocalFallbackSimulation()
        }
    }

    function fetchStatus() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", bridgeUrl + "/api/status", true)
        xhr.timeout = 1500

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                bridgeOnline = true
                try {
                    var data = JSON.parse(xhr.responseText)
                    connected = data.is_connected
                    if (data.device_name) deviceName = data.device_name
                    if (data.device_mac) deviceMac = data.device_mac
                    isSimulation = data.is_simulation
                    isWorkoutMode = data.workout_mode
                } catch (e) {
                    console.log("Error parsing bridge status: " + e)
                }
            }
        }
        try { xhr.send() } catch (e) {}
    }

    function applyMetrics(data) {
        if (!data) return
        connected = data.connected !== false
        if (data.device_name) deviceName = data.device_name
        if (data.battery_level !== undefined) batteryLevel = data.battery_level
        if (data.firmware_version) firmwareVersion = data.firmware_version

        var prevHr = heartRate
        heartRate = data.heart_rate || 0
        if (heartRate !== prevHr) {
            heartRateUpdated(heartRate)
        }

        heartRateZone = data.heart_rate_zone || "Rest"
        heartRateZoneColor = data.heart_rate_zone_color || "#38BDF8"
        heartRateZoneDesc = data.heart_rate_zone_desc || ""

        var prevSteps = steps
        steps = data.steps || 0
        if (steps !== prevSteps) {
            stepsUpdated(steps)
        }

        stepGoal = data.step_goal || 10000
        stepProgressPct = data.step_progress_pct || 0
        distanceKm = data.distance_km || 0.0
        caloriesBurned = data.calories_burned || 0.0
        isWorkoutMode = data.workout_mode || false
    }

    function connectDevice(mac, authKey) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", bridgeUrl + "/api/connect", true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                connected = true
                connectionChanged(true)
                fetchMetrics()
            }
        }
        xhr.send(JSON.stringify({mac: mac, auth_key: authKey}))
    }

    function disconnectDevice() {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", bridgeUrl + "/api/disconnect", true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                connected = false
                connectionChanged(false)
            }
        }
        xhr.send()
    }

    function setWorkoutMode(enable) {
        isWorkoutMode = enable
        var xhr = new XMLHttpRequest()
        var endpoint = enable ? "/api/workout/start" : "/api/workout/stop"
        xhr.open("POST", bridgeUrl + endpoint, true)
        xhr.send()
    }

    // REALISTIC FALLBACK SIMULATION (Ensures interactive UI even when bridge script is cold)
    property real _simTime: 0
    function runLocalFallbackSimulation() {
        if (!connected) return
        _simTime += 1.0

        if (isWorkoutMode) {
            // Exercise heart rate ~ 135-155 BPM
            var targetHr = 145 + Math.round(8 * Math.sin(_simTime * 0.2)) + Math.round((Math.random() - 0.5) * 4)
            heartRate = Math.max(50, Math.min(195, targetHr))
            steps += Math.floor(Math.random() * 2) + 2
            caloriesBurned = Math.round((caloriesBurned + 0.16) * 10) / 10
        } else {
            // Resting heart rate ~ 68-76 BPM
            var restingTarget = 72 + Math.round(3 * Math.sin(_simTime * 0.15)) + Math.round((Math.random() - 0.5) * 2)
            heartRate = Math.max(50, Math.min(100, restingTarget))
            if (Math.random() < 0.35) {
                steps += Math.floor(Math.random() * 2) + 1
                caloriesBurned = Math.round((caloriesBurned + 0.04) * 10) / 10
            }
        }

        distanceKm = Math.round((steps * 0.00076) * 100) / 100
        stepProgressPct = Math.min(100, Math.round((steps / stepGoal) * 100))

        // Calculate HR Zone
        if (heartRate < 95) {
            heartRateZone = "Rest"
            heartRateZoneColor = "#38BDF8"
            heartRateZoneDesc = "Resting heart rate"
        } else if (heartRate < 115) {
            heartRateZone = "Warm-up"
            heartRateZoneColor = "#34D399"
            heartRateZoneDesc = "Light activity"
        } else if (heartRate < 135) {
            heartRateZone = "Fat Burn"
            heartRateZoneColor = "#FBBF24"
            heartRateZoneDesc = "Aerobic fat burning"
        } else if (heartRate < 155) {
            heartRateZone = "Cardio"
            heartRateZoneColor = "#FB923C"
            heartRateZoneDesc = "Cardiovascular training"
        } else {
            heartRateZone = "Peak"
            heartRateZoneColor = "#EF4444"
            heartRateZoneDesc = "Maximum effort"
        }

        heartRateUpdated(heartRate)
    }
}
