import Foundation
struct DeviceAndTimeSeries: Identifiable {
    var id: String = ""
    var name: String = ""
    var temperatureThresholdHigh: CGFloat?
    var temperatureThresholdLow: CGFloat?
    var lastTelemetryTemperature: CGFloat?
    var lastTelemetryHumidity: CGFloat?
    var isAlarmActive: Bool?
    var isMaintenanceActive: Bool?
    var listTelemetryToDraw: [CGFloat]?
}

