import WidgetKit
import SwiftUI

struct Provider: IntentTimelineProvider {
    typealias Intent = SelectDeviceIntent
    var devs: [DeviceAndTimeSeries] = []
    
    func snapShotDevices() -> [DeviceAndTimeSeries]{
        var demo: [DeviceAndTimeSeries] = []
        var deviceAndTimeSeries1 = DeviceAndTimeSeries()
        var deviceAndTimeSeries2 = DeviceAndTimeSeries()
        var deviceAndTimeSeries3 = DeviceAndTimeSeries()
        deviceAndTimeSeries1.id = "111"
        deviceAndTimeSeries1.name = "\(NSLocalizedString("thermometer", comment: "")) 1"
        deviceAndTimeSeries1.temperatureThresholdHigh = 40.5
        deviceAndTimeSeries1.temperatureThresholdLow = 3.5
        deviceAndTimeSeries1.lastTelemetryTemperature = 25.5
        deviceAndTimeSeries1.lastTelemetryHumidity = 81.3
        deviceAndTimeSeries1.isAlarmActive = true
        deviceAndTimeSeries1.isMaintenanceActive = false
        deviceAndTimeSeries1.listTelemetryToDraw = [33.5, 30.7, 35.6, 34.8, 30.7, 35.6, 34.8, 44.4]
        demo.append(deviceAndTimeSeries1)
        deviceAndTimeSeries2.id = "222"
        deviceAndTimeSeries2.name = "\(NSLocalizedString("thermometer", comment: "")) 2"
        deviceAndTimeSeries2.temperatureThresholdHigh = 20.5
        deviceAndTimeSeries2.temperatureThresholdLow = 10.5
        deviceAndTimeSeries2.lastTelemetryTemperature = 18.2
        deviceAndTimeSeries2.lastTelemetryHumidity = 72.5
        deviceAndTimeSeries2.isAlarmActive = false
        deviceAndTimeSeries2.isMaintenanceActive = false
        deviceAndTimeSeries2.listTelemetryToDraw = [17.5, 13.7, 15.6, 16.8, 13.7, 15.6, 16.8, 14.4]
        demo.append(deviceAndTimeSeries2)
        deviceAndTimeSeries3.id = "333"
        deviceAndTimeSeries3.name = "\(NSLocalizedString("thermometer", comment: "")) 3"
        deviceAndTimeSeries3.temperatureThresholdHigh = 10.5
        deviceAndTimeSeries3.temperatureThresholdLow = 0.5
        deviceAndTimeSeries3.lastTelemetryTemperature = 5.3
        deviceAndTimeSeries3.lastTelemetryHumidity = 55.5
        deviceAndTimeSeries3.isAlarmActive = false
        deviceAndTimeSeries3.isMaintenanceActive = false
        deviceAndTimeSeries3.listTelemetryToDraw = [5.5, 4.7, 6.6, 6.8, 4.7, 6.6, 6.8, 8.4]
        demo.append(deviceAndTimeSeries3)
        return demo
    }
    
    var alarmCount: Int = 1
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), devices: devs, alarmCount: alarmCount)
    }

    func getSnapshot(for configuration: SelectDeviceIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let demoDevices = snapShotDevices()
            let entry = SimpleEntry(date: Date(), devices: demoDevices, alarmCount: alarmCount)
        completion(entry)
    }

    func getTimeline(for configuration: SelectDeviceIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        // ////////////////////////////////////////////
        var ids: [String] = []
        if configuration.device != nil {
            for i in 0 ..< configuration.device!.count {
                ids.append("\(configuration.device![i].identifier!)")
            }
            // /////////////////////////////////////////////
            // #############################################
            TBRest.getListDevicesAndTS (deviceIds: ids) { error, success, devices, aCount  in
                if let error = error {
                    return
                }
                if success {
                    let successDate = Date()
                    let devices = devices
                    let count = aCount
                    
                    let entry = SimpleEntry(date: successDate, devices: devices!, alarmCount: count!)
                    entries.append(entry)
                    
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                    return
                } else {
                    TBRest.getNewToken{ error, success, str in
                        if success, let tokenResp = str{
                            if tokenResp == "no_token"{
                                let successDate = Date()
                                var devicesDef: [DeviceAndTimeSeries] = []
                                var deviceAndTimeSeriesDef = DeviceAndTimeSeries()
                                deviceAndTimeSeriesDef.id = "222"
                                deviceAndTimeSeriesDef.name = "\(NSLocalizedString("user_not_logged", comment: ""))"
                                deviceAndTimeSeriesDef.temperatureThresholdHigh = 0.0
                                deviceAndTimeSeriesDef.temperatureThresholdLow = 0.0
                                deviceAndTimeSeriesDef.lastTelemetryTemperature = 0.0
                                deviceAndTimeSeriesDef.lastTelemetryHumidity = 0.0
                                deviceAndTimeSeriesDef.isAlarmActive = false
                                deviceAndTimeSeriesDef.isMaintenanceActive = true
                                deviceAndTimeSeriesDef.listTelemetryToDraw = [0.0, 0.0]
                                devicesDef.append(deviceAndTimeSeriesDef)
                                
                                let entry = SimpleEntry(date: successDate, devices: devicesDef, alarmCount: -100) // -100 code not token- not logged
                                entries.append(entry)
                                
                                let timeline = Timeline(entries: entries, policy: .atEnd)
                                completion(timeline)
                                return
                            }
                        }
                    }
                    return
                }
            } //end get devices ids
        } // end if count != nil
        else {
            TBRest.getNewToken{ error, success, str in
                if success, let tokenResp = str{
                    if tokenResp == "no_token"{
                        let successDate = Date()
                        var devicesDef: [DeviceAndTimeSeries] = []
                        var deviceAndTimeSeriesDef = DeviceAndTimeSeries()
                        deviceAndTimeSeriesDef.id = "222"
                        deviceAndTimeSeriesDef.name = "\(NSLocalizedString("user_not_logged", comment: ""))"
                        deviceAndTimeSeriesDef.temperatureThresholdHigh = 0.0
                        deviceAndTimeSeriesDef.temperatureThresholdLow = 0.0
                        deviceAndTimeSeriesDef.lastTelemetryTemperature = 0.0
                        deviceAndTimeSeriesDef.lastTelemetryHumidity = 0.0
                        deviceAndTimeSeriesDef.isAlarmActive = false
                        deviceAndTimeSeriesDef.isMaintenanceActive = true
                        deviceAndTimeSeriesDef.listTelemetryToDraw = [0.0, 0.0]
                        devicesDef.append(deviceAndTimeSeriesDef)
                        
                        let entry = SimpleEntry(date: successDate, devices: devicesDef, alarmCount: -100) // -100 code not token- not logged
                        entries.append(entry)
                        
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                        return
                    }
                }
            }
            return
        }
        // #############################################
    }
    

    
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let devices: [DeviceAndTimeSeries]
    let alarmCount : Int
}

struct AppWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
            case .systemMedium:
            GeometryReader { geometry in
                let frameSize = geometry.frame(in: .local)
                let boxPercentWidth: CGFloat = frameSize.width  / 100
                let boxPercentHeight: CGFloat = frameSize.height  / 100
                let rowHeight: CGFloat = boxPercentHeight * (100 / 8)
                let fontSize1: CGFloat = boxPercentWidth * 4
                let fontSizeBell2: CGFloat = boxPercentWidth * 2.3
                let fontSizeBell1: CGFloat = boxPercentWidth * 3.2
                let fontSize3: CGFloat = boxPercentWidth * 5
                let gray1:
                Color = Color(red: 210 / 255, green: 210 / 255, blue: 210 / 255)
                let gray2:
                Color = Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255)
                let date = Utils.daysOfWeek()
//                **********************************************
                VStack(spacing: 0){
                    // /////////////////////////////////////
                    HStack(spacing: 0){
                        VStack(spacing: 0){
                            Spacer()
                            HStack(spacing: 0){
                                HStack(spacing: 0){
                                    Image(uiImage: UIImage(named: "weelab")!)
                                        .resizable()
                                        .frame(width: boxPercentWidth * 6, height: rowHeight * 0.6, alignment: .trailing)
                                }.frame(width: boxPercentWidth * 11, height: rowHeight, alignment: .trailing)
                                HStack(spacing: 0){
                                    Text(".")// space
                                        .foregroundColor(Color.black)
                                        .font(.system(size: fontSize1))
                                        .fixedSize()
                                        .frame(width: nil, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    Text("update")
                                        .foregroundColor(gray1)
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .fixedSize()
                                        .frame(width: nil, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    Text(" \(entry.date.formatted(.dateTime.hour().minute()))")
                                        .foregroundColor(gray1)
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .fixedSize()
                                        .frame(width: nil, height: rowHeight, alignment: .leading)
                                        .clipped()
                                }.frame(width: boxPercentWidth * 75, height: rowHeight, alignment: .leading)
                                    .clipped()
                                if entry.alarmCount == -100 {
                                    Text(Image(systemName: "person.crop.circle.fill.badge.exclamationmark")).font(.system(size: fontSizeBell1)).foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                        .frame(width: boxPercentWidth * 6, height: boxPercentWidth * 6)
                                    
                                    Text("")
                                        .foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .fixedSize()
                                        .frame(width: boxPercentWidth * 8, height: rowHeight, alignment: .leading)
                                        .clipped()
                                }else{
                                Text(Image(systemName: "bell.fill")).font(.system(size: fontSizeBell1)).foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 180 / 255, green: 120 / 255, blue: 0 / 255))
                                            .frame(width: boxPercentWidth * 2.1, height: boxPercentWidth * 2.1)
                                            .shadow(color: entry.alarmCount > 0 ? Color.yellow : Color.black, radius: 5, x: 0, y: 0)
                                    ).frame(width: boxPercentWidth * 6, height: boxPercentWidth * 6)
                                Text(" \(entry.alarmCount)")
                                    .foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                    .font(.system(size: fontSize1))
                                    .bold()
                                    .fixedSize()
                                    .frame(width: boxPercentWidth * 8, height: rowHeight, alignment: .leading)
                                    .clipped()
                            }
                                Spacer()
                            }.frame(width: frameSize.width, height: rowHeight)
                        }
                    }.background(Color.black).frame(width: frameSize.width, height: rowHeight * 1.2)
                    // ///////////////////////////
                    // ********TEST*********
//                    Text(" \(entry.sDate.formatted(.dateTime.hour().minute()))").foregroundColor(Color.green)

                    // **********************************************
                    // *********************************************
                    HStack(spacing: 0){
                        HStack(spacing: 0){
                            Text(".").font(.system(size: boxPercentWidth * 2)).foregroundColor(Color.black)
                        }.background(Color.black).frame(width: boxPercentWidth * 50, height: rowHeight * 0.5)
                        HStack(spacing: 0){
                            Text(date[0]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[1]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[2]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[3]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[4]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[5]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[6]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                        }.background(Color.green.opacity(0.0)).frame(width: boxPercentWidth * 40, height: rowHeight * 0.5, alignment: .leading)
                        Spacer()
                        
                    }.frame(width: frameSize.width, height: rowHeight * 0.5, alignment: .leading).background(Color.black.opacity(0.0))
                    // **********************************************
                    ForEach(entry.devices) { device in
                        HStack(spacing: 0){
                            VStack(spacing: 0){
                                HStack(spacing: 0){
                                    Text("_")
                                        .foregroundColor(Color.black)
                                        .font(.system(size: fontSize1))
                                        .truncationMode(.middle)
                                        .frame(width: boxPercentWidth * 4, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    Text(device.name)
                                        .foregroundColor(Color(red: 210 / 255, green: 210 / 255, blue: 210 / 255))
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .truncationMode(.middle)
                                        .frame(width: boxPercentWidth * 42, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    if device.isMaintenanceActive! {
                                        Text("").foregroundColor(Color.black).frame(width: boxPercentWidth * 4, height: rowHeight)
                                    }else{
                                        //########################################
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(device.isAlarmActive! ? Color.red : Color.black)
                                            .font(.system(size: fontSizeBell2))
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 4, height: rowHeight, alignment: .leading)
                                            .clipped()
                                        //########################################
                                    }
                                }.frame(maxHeight: rowHeight)
                                HStack(spacing: 0){
                                    if device.isMaintenanceActive! {
                                        Text("_")
                                            .foregroundColor(Color.black)
                                            .font(.system(size: fontSize1))
                                            .truncationMode(.middle)
                                            .frame(width: boxPercentWidth * 6, height: rowHeight, alignment: .leading)
                                            .clipped()
                                        Text("under_maintenance").foregroundColor(Color.orange).font(.system(size: fontSize1)).bold().frame(width: boxPercentWidth * 48, height: rowHeight * 2, alignment: .leading)
                                    }else{
                                        //######################################
                                        Image(systemName: "thermometer")
                                            .foregroundColor(Color.white)
                                            .font(.system(size: fontSize1))
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 7, height: rowHeight, alignment: .trailing)
                                            .clipped()
                                        let tempe = String(format: "%.1f", device.lastTelemetryTemperature!)
                                        let valTempe: String = device.lastTelemetryTemperature! > 0 ? "-": ""
                                        HStack(spacing: 0){
                                            Text("\(valTempe)")
                                                .foregroundColor(Color.black)
                                                .font(.system(size: fontSize3))
                                                .bold()
                                            Text(" \(tempe)")
                                                .foregroundColor(Color.orange)
                                                .font(.system(size: fontSize3))
                                                .bold()
                                            Spacer()
                                        }.frame(width: boxPercentWidth * 23, height: rowHeight).background(Color.black)
                                        Image(systemName: "drop.fill")
                                            .foregroundColor(Color.blue)
                                            .font(.system(size: fontSize1))
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 4, height: rowHeight, alignment: .trailing)
                                            .clipped()
                                        let humi = String(format: "%.1f", device.lastTelemetryHumidity!)
                                        Text(" \(humi)")
                                            .foregroundColor(Color.blue)
                                            .font(.system(size: fontSize1))
                                            .bold()
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 16, height: rowHeight, alignment: .leading)
                                            .clipped()
                                        //###################################
                                    }
                                }.frame(maxHeight: rowHeight)
                            }.frame(width: boxPercentWidth * 50)
                            HStack(spacing: 0){
                                if device.isMaintenanceActive! {
                                    if entry.alarmCount == -100{
                                        Text("")
                                    } else {
                                    Image(uiImage: UIImage(named: "tools")!)
                                        .resizable()
                                    }
                                } else {
                                    ChartMaker(thresholdHigh: device.temperatureThresholdHigh!, thresholdLow: device.temperatureThresholdLow!, dataSet: device.listTelemetryToDraw!, isAlarmActive: device.isAlarmActive!)
                                }
                                
                            }.frame(width: boxPercentWidth * 48, height: rowHeight * 2)
                            Spacer()
                        }.frame(width: frameSize.width, height: rowHeight * 2)
                            .overlay(Rectangle().frame(width: frameSize.width, height: 1, alignment: .bottom).foregroundColor(gray2), alignment: .top)
                        // **********************************************
                    }

                    Spacer()
                }.background(Color.black)
            }
                
            default:
            GeometryReader { geometry in
                let frameSize = geometry.frame(in: .local)
                let boxPercentWidth: CGFloat = frameSize.width  / 100
                let boxPercentHeight: CGFloat = frameSize.height  / 100
                let rowHeight: CGFloat = boxPercentHeight * (100 / 16)
                let fontSize1: CGFloat = boxPercentWidth * 4
                let fontSizeBell2: CGFloat = boxPercentWidth * 2.3
                let fontSizeBell1: CGFloat = boxPercentWidth * 3.2
                let fontSize3: CGFloat = boxPercentWidth * 5
                let gray1:
                Color = Color(red: 210 / 255, green: 210 / 255, blue: 210 / 255)
                let gray2:
                Color = Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255)
                let date = Utils.daysOfWeek()
//                **********************************************
                VStack(spacing: 0){
                    // /////////////////////////////////////
                    HStack(spacing: 0){
                        VStack(spacing: 0){
                            Spacer()
                            HStack(spacing: 0){
                                HStack(spacing: 0){
                                    Image(uiImage: UIImage(named: "weelab")!)
                                        .resizable()
                                        .frame(width: boxPercentWidth * 6, height: rowHeight * 0.6, alignment: .trailing)
                                }.frame(width: boxPercentWidth * 11, height: rowHeight, alignment: .trailing)
                                HStack(spacing: 0){
                                    Text(".")// space
                                        .foregroundColor(Color.black)
                                        .font(.system(size: fontSize1))
                                        .fixedSize()
                                        .frame(width: nil, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    Text("update")
                                        .foregroundColor(gray1)
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .fixedSize()
                                        .frame(width: nil, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    Text(" \(entry.date.formatted(.dateTime.hour().minute()))")
                                        .foregroundColor(gray1)
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .fixedSize()
                                        .frame(width: nil, height: rowHeight, alignment: .leading)
                                        .clipped()
                                }.frame(width: boxPercentWidth * 75, height: rowHeight, alignment: .leading)
                                    .clipped()
                                if entry.alarmCount == -100 {
                                    Text(Image(systemName: "person.crop.circle.fill.badge.exclamationmark")).font(.system(size: fontSizeBell1)).foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                        .frame(width: boxPercentWidth * 6, height: boxPercentWidth * 6)
                                    
                                    Text("")
                                        .foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .fixedSize()
                                        .frame(width: boxPercentWidth * 8, height: rowHeight, alignment: .leading)
                                        .clipped()
                                }else{
                                Text(Image(systemName: "bell.fill")).font(.system(size: fontSizeBell1)).foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 180 / 255, green: 120 / 255, blue: 0 / 255))
                                            .frame(width: boxPercentWidth * 2.1, height: boxPercentWidth * 2.1)
                                            .shadow(color: entry.alarmCount > 0 ? Color.yellow : Color.black, radius: 5, x: 0, y: 0)
                                    ).frame(width: boxPercentWidth * 6, height: boxPercentWidth * 6)
                                Text(" \(entry.alarmCount)")
                                    .foregroundColor(entry.alarmCount > 0 ? Color.red : gray1)
                                    .font(.system(size: fontSize1))
                                    .bold()
                                    .fixedSize()
                                    .frame(width: boxPercentWidth * 8, height: rowHeight, alignment: .leading)
                                    .clipped()
                            }
                                Spacer()
                            }.frame(width: frameSize.width, height: rowHeight)
                        }
                    }.background(Color.black).frame(width: frameSize.width, height: rowHeight * 1.2)
                    // ///////////////////////////
                    // ********TEST*********
//                    Text(" \(entry.sDate.formatted(.dateTime.hour().minute()))").foregroundColor(Color.green)

                    // **********************************************
                    // *********************************************
                    HStack(spacing: 0){
                        HStack(spacing: 0){
                            Text(".").font(.system(size: boxPercentWidth * 2)).foregroundColor(Color.black)
                        }.background(Color.black).frame(width: boxPercentWidth * 50, height: rowHeight * 0.5)
                        HStack(spacing: 0){
                            Text(date[0]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[1]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[2]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[3]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[4]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[5]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                            Text(date[6]).foregroundColor(Color.gray).font(.system(size: boxPercentWidth * 3)).bold().frame(width: boxPercentWidth * 6.4, height: nil)
                        }.background(Color.green.opacity(0.0)).frame(width: boxPercentWidth * 40, height: rowHeight * 0.5, alignment: .leading)
                        Spacer()
                        
                    }.frame(width: frameSize.width, height: rowHeight * 0.5, alignment: .leading).background(Color.black.opacity(0.0))
                    // **********************************************
                    ForEach(entry.devices) { device in
                        HStack(spacing: 0){
                            VStack(spacing: 0){
                                HStack(spacing: 0){
                                    Text("_")
                                        .foregroundColor(Color.black)
                                        .font(.system(size: fontSize1))
                                        .truncationMode(.middle)
                                        .frame(width: boxPercentWidth * 4, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    Text(device.name)
                                        .foregroundColor(Color(red: 210 / 255, green: 210 / 255, blue: 210 / 255))
                                        .font(.system(size: fontSize1))
                                        .bold()
                                        .truncationMode(.middle)
                                        .frame(width: boxPercentWidth * 42, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    if device.isMaintenanceActive! {
                                        Text("").foregroundColor(Color.black).frame(width: boxPercentWidth * 4, height: rowHeight)
                                    }else{
                                        //########################################
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(device.isAlarmActive! ? Color.red : Color.black)
                                            .font(.system(size: fontSizeBell2))
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 4, height: rowHeight, alignment: .leading)
                                            .clipped()
                                        //########################################
                                    }
                                }.frame(maxHeight: rowHeight)
                                HStack(spacing: 0){
                                    if device.isMaintenanceActive! {
                                        Text("_")
                                            .foregroundColor(Color.black)
                                            .font(.system(size: fontSize1))
                                            .truncationMode(.middle)
                                            .frame(width: boxPercentWidth * 6, height: rowHeight, alignment: .leading)
                                            .clipped()
                                        Text("under_maintenance").foregroundColor(Color.orange).font(.system(size: fontSize1)).bold().frame(width: boxPercentWidth * 48, height: rowHeight * 2, alignment: .leading)
                                    }else{
                                        //######################################
                                        Image(systemName: "thermometer")
                                            .foregroundColor(Color.white)
                                            .font(.system(size: fontSize1))
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 7, height: rowHeight, alignment: .trailing)
                                            .clipped()
                                        let tempe = String(format: "%.1f", device.lastTelemetryTemperature!)
                                        let valTempe: String = device.lastTelemetryTemperature! > 0 ? "-": ""
                                        HStack(spacing: 0){
                                            Text("\(valTempe)")
                                                .foregroundColor(Color.black)
                                                .font(.system(size: fontSize3))
                                                .bold()
                                            Text(" \(tempe)")
                                                .foregroundColor(Color.orange)
                                                .font(.system(size: fontSize3))
                                                .bold()
                                            Spacer()
                                        }.frame(width: boxPercentWidth * 23, height: rowHeight).background(Color.black)
                                        Image(systemName: "drop.fill")
                                            .foregroundColor(Color.blue)
                                            .font(.system(size: fontSize1))
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 4, height: rowHeight, alignment: .trailing)
                                            .clipped()
                                        let humi = String(format: "%.1f", device.lastTelemetryHumidity!)
                                        Text(" \(humi)")
                                            .foregroundColor(Color.blue)
                                            .font(.system(size: fontSize1))
                                            .bold()
                                            .fixedSize()
                                            .frame(width: boxPercentWidth * 16, height: rowHeight, alignment: .leading)
                                            .clipped()
                                        //###################################
                                    }
                                }.frame(maxHeight: rowHeight)
                            }.frame(width: boxPercentWidth * 50)
                            HStack(spacing: 0){
                                if device.isMaintenanceActive! {
                                    if entry.alarmCount == -100{
                                        Text("")
                                    } else {
                                    Image(uiImage: UIImage(named: "tools")!)
                                        .resizable()
                                    }
                                } else {
                                    ChartMaker(thresholdHigh: device.temperatureThresholdHigh!, thresholdLow: device.temperatureThresholdLow!, dataSet: device.listTelemetryToDraw!, isAlarmActive: device.isAlarmActive!)
                                }
                                
                            }.frame(width: boxPercentWidth * 48, height: rowHeight * 2)
                            Spacer()
                        }.frame(width: frameSize.width, height: rowHeight * 2)
                            .overlay(Rectangle().frame(width: frameSize.width, height: 1, alignment: .bottom).foregroundColor(gray2), alignment: .top)
                        // **********************************************
                    }

                    Spacer()
                }.background(Color.black)
            }// end default
            } // end switch family
    } // end of var body: some View
}



struct AppWidget: Widget {
    let kind: String = "AppWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectDeviceIntent.self, provider: Provider()) { entry in
            AppWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("weelab_widget")
        .description("weelab_use")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
    
}

struct AppWidget_Previews: PreviewProvider {
    static var previews: some View {
        let devs: [DeviceAndTimeSeries] = []
        AppWidgetEntryView(entry: SimpleEntry(date: Date(), devices: devs, alarmCount: 9))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}


