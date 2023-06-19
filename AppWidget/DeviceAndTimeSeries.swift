import Foundation
struct DeviceAndTimeSeries: Identifiable {
    var id: String = ""
    var deviceName: String = ""
    var temperatureThresholdHigh: CGFloat = -99999
    var temperatureThresholdLow: CGFloat = -99999
    var lastTelemetryTemperature: CGFloat = -99999
    var lastTelemetryHumidity: CGFloat = -99999
    var listTelemetryToDraw: [CGFloat] = [0.0]
    var isAlarmActive: Bool = false
    var isMaintenanceActive: Bool = false
    var isDeviceActive: Bool = true
}

