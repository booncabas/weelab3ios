import Foundation

struct TBRest: Codable {
    
    static func getNewToken(completion:@escaping ((Error?, Bool, String?) -> Void)) {
        let weelab_refresh_token = Utils.getRefreshToken()
        let checkTokenStr: String = weelab_refresh_token ?? ""
        if(checkTokenStr.count < 10){// no token is so small
            completion(nil, true, "no_token")
            return
        }
        let body: [String: Any] = ["refreshToken": weelab_refresh_token ?? ""]
                
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        let url = URL(string: "https://app.weelab.io:8080/api/auth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, true, "error_token")
                 return
             }
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 if let rToken = dictionary["refreshToken"] as? String {
                     Utils.setRefreshToken(refreshToken: rToken)
                 }
                 if let newToken = dictionary["token"] as? String {
                     completion(nil, true, newToken)
                 }
             }
         }
         task.resume()
     }
    
    static func getCountActiveAlarms(token: String, completion:@escaping ((Error?, Bool, Int?) -> Void)) {
        let weelab_customer_id = Utils.getCustomerId()
        let url = URL(string: "https://app.weelab.io:8080/api/customer/" + (weelab_customer_id ?? "") + "/devices?pageSize=1000&page=0")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             var alarmCount: Int = 0
             var listDevicesCount: [Bool] = []
             let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
             if let devices = json?["data"] as? [[String: Any]] {
                 for (device) in devices {
                     if let id = device["id"] as? [String: Any] {
                         if let idId = id["id"] as? String {
                             self.getActiveAlarmsByDeviceId(idDevice: "" + idId, token: token) { error, success, hasActiveAlarms in
                                 if success, let hasActiveAlarms = hasActiveAlarms {
                                     listDevicesCount.append(hasActiveAlarms)
                                     if (hasActiveAlarms){ alarmCount = alarmCount + 1}
                                     if (listDevicesCount.count == devices.count){
                                        completion(nil, true, alarmCount)
                                     }
                                 }
                             }
                         }
                     }
                 }
             }
         }
         task.resume()
     }
    
        
    static func getListDevicesAndTS(deviceIds: [String], completion:@escaping ((Error?, Bool, [DeviceAndTimeSeries]?, Int?) -> Void)) {
        self.getNewToken{ error, success, str in
            if success, let tokenResp = str{
                if tokenResp == "no_token"{
                    completion(nil, false, nil, 0)
                    return
                }
                // ******************************************
                var listDevicesAndTS: [DeviceAndTimeSeries] = []
                var listDevicesAndTS2: [DeviceAndTimeSeries] = []
                var order: [String] = []
                for id in deviceIds {
                    order.append(id)
                     self.getDeviceAndTimeSeries(idDevice: "\(id)", token: tokenResp) { error, success, deviceAndTimeSeries in
                         if success, let deviceAndTs = deviceAndTimeSeries {
                             listDevicesAndTS.append(deviceAndTs)
                             if (listDevicesAndTS.count == deviceIds.count){
                                 // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                 self.getCountActiveAlarms(token: tokenResp) { error, success, countAlarms in
                                     if success, let cAlarms = countAlarms {
                                         // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                         for i in 0..<listDevicesAndTS.count{
                                             for devAux in listDevicesAndTS{
                                                 if devAux.id == order[i] {
                                                     listDevicesAndTS2.append(devAux)
                                                     break
                                                 }
                                             }
                                         }
                                         // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                         completion(nil, true, listDevicesAndTS2, cAlarms)//working
                                     }
                                 }
                                // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                             }
                         }
                    }
                } // end for id
                // ***********************************************
            } // end of if success
            else{
                completion(nil, false, nil, 0)
            }
        }
     }
    
    static func getListDevices(completion:@escaping ((Error?, Bool, [DeviceAndTimeSeries]?) -> Void)) {
        self.getNewToken{ error, success, str in
            if success, let tokenResp = str{
                if tokenResp == "no_token"{
                    completion(nil, false, nil)
                    return
                }
                // ************************************************
                let weelab_customer_id = Utils.getCustomerId()
                let url = URL(string: "https://app.weelab.io:8080/api/customer/" + (weelab_customer_id ?? "") + "/devices?pageSize=1000&page=0")!
                var request = URLRequest(url: url)
                 let token = tokenResp
                 request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                 let task = URLSession.shared.dataTask(with: request){ data, response, error in
                     guard let data = data else {
                         completion(nil, false, nil)
                         return
                     }
                     var listDevicesAndTS: [DeviceAndTimeSeries] = []
                     let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
                     if let devices = json?["data"] as? [[String: Any]] {
                         for (device) in devices {
                             var tempName = ""
                             if let name = device["label"] as? String {
                                 tempName = name
                             } else if let name = device["name"] as? String {
                                 tempName = name
                             }
                             if let id = device["id"] as? [String: Any] {
                                 if let idId = id["id"] as? String {
                                     var deviceAndTimeSeries = DeviceAndTimeSeries()
                                     deviceAndTimeSeries.id = idId
                                     deviceAndTimeSeries.name = "\(tempName)"
                                     deviceAndTimeSeries.temperatureThresholdHigh = CGFloat(0.0)
                                     deviceAndTimeSeries.temperatureThresholdLow = CGFloat(0.0)
                                     deviceAndTimeSeries.lastTelemetryTemperature = CGFloat(0.0)
                                     deviceAndTimeSeries.lastTelemetryHumidity = CGFloat(0.0)
                                     deviceAndTimeSeries.isAlarmActive = false
                                     deviceAndTimeSeries.listTelemetryToDraw = [CGFloat(0.0), CGFloat(0.0)]
                                     listDevicesAndTS.append(deviceAndTimeSeries)
                                     if (listDevicesAndTS.count == devices.count){
                                         completion(nil, true, listDevicesAndTS)//working
                                     }
                                 }
                             }
                         } //end of for
                     }else{
                         completion(nil, true, listDevicesAndTS)
                         return
                     }
                 }
                 task.resume()
                // **********************************************
            }
            else{
                completion(nil, false, nil)
            }
        }
        
     }
    

    static func getDefaultListDevices(nMax: Int, completion:@escaping ((Error?, Bool, [DeviceAndTimeSeries]?) -> Void)) {
        self.getNewToken{ error, success, str in
            if success, let tokenResp = str{
                if tokenResp == "no_token"{
                    completion(nil, false, nil)
                    return
                }
                // *******************************************
                let weelab_customer_id = Utils.getCustomerId()
                let url = URL(string: "https://app.weelab.io:8080/api/customer/" + (weelab_customer_id ?? "") + "/devices?pageSize=1000&page=0")!
                var request = URLRequest(url: url)
                 let token = tokenResp
                 request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                 let task = URLSession.shared.dataTask(with: request){ data, response, error in
                     guard let data = data else {
                         completion(nil, false, nil)
                         return
                     }
                     var listDevicesAndTS: [DeviceAndTimeSeries] = []
                     var listDevicesAndTS2: [DeviceAndTimeSeries] = []
                     var order: [String] = []
                     var max: Int = nMax
                     let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
                     if let devices = json?["data"] as? [[String: Any]] {
                         if nMax > devices.count {
                             max = devices.count
                         }
                         let devicesAux = devices[..<max]
                         for (device) in devicesAux {
                             // ***********************************************
                             if let id = device["id"] as? [String: Any] {
                                 if let idId = id["id"] as? String {
                                     order.append(idId)
                                     self.getDeviceAndTimeSeries(idDevice: "\(idId)", token: token) { error, success, deviceAndTimeSeries in
                                         if success, let deviceAndTs = deviceAndTimeSeries {
                                             listDevicesAndTS.append(deviceAndTs)
                                             if (listDevicesAndTS.count == max){
                                                 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                 for i in 0..<listDevicesAndTS.count{
                                                     for devAux in listDevicesAndTS{
                                                         if devAux.id == order[i] {
                                                             listDevicesAndTS2.append(devAux)
                                                             break
                                                         }
                                                     }
                                                 }
                                                 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                 completion(nil, true, listDevicesAndTS2)//working
                                             }
                                         }
                                     }
                                 }
                             }
                             // ***********************************************
                         } //end of for
                     }else{
                         completion(nil, false, nil)
                         return
                     }
                 }
                 task.resume()
                // ************************************************************
            }
            else{
                completion(nil, false, nil)
                return
            }
        }

     }
    
    static func getSingleDevice(idDevice:String, token: String, completion:@escaping ((Error?, Bool, [String]?) -> Void)) {
        let url = URL(string: "https://app.weelab.io:8080/api/device/" + idDevice)!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             var singleDevice: [String] = []
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 if let name = dictionary["label"] as? String {
                     singleDevice.append(name)
                 } else if let name = dictionary["name"] as? String {
                     singleDevice.append(name)
                 }
                 if let id = dictionary["id"] as? [String: Any] {
                     if let idId = id["id"] as? String {
                     singleDevice.append(idId)
                     }
                 }
             }
             completion(nil, true, singleDevice)
         }
         task.resume()
     }

    static func getLastTelemetry(idDevice:String, token: String, completion:@escaping ((Error?, Bool, [Double]?) -> Void)) {
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/timeseries?keys=temperature,humidity&useStrictDataTypes=true")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             var lastTelemetry: [Double] = []
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                     if let temperature = dictionary["temperature"] as? [[String: Double]]{
                         lastTelemetry.append(temperature[0]["value"]!)
                     }
                     if let humidity = dictionary["humidity"] as? [[String: Double]]{
                         lastTelemetry.append(humidity[0]["value"]!)
                     }
                 }
             completion(nil, true, lastTelemetry)
         }
         task.resume()
     }

    static func getThresholdHighAndLow(idDevice:String, token: String, completion:@escaping ((Error?, Bool, [Double]?) -> Void)) {
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/attributes/SERVER_SCOPE?keys=temperatureThresholdHigh&keys=temperatureThresholdLow")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             var thresholdHighAndLow: [Double] = []//0 high 1 low
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [[String: Any]] {
                 if(dictionary[0]["key"] as! String == "temperatureThresholdHigh"){
                     thresholdHighAndLow.append(dictionary[0]["value"] as! Double)
                     thresholdHighAndLow.append(dictionary[1]["value"] as! Double)
                 } else{
                     thresholdHighAndLow.append(dictionary[1]["value"] as! Double)
                     thresholdHighAndLow.append(dictionary[0]["value"] as! Double)
                 }
             }
             completion(nil, true, thresholdHighAndLow)
         }
         task.resume()
     }
    
    static func getMaintenaceState(idDevice:String, token: String, completion:@escaping ((Error?, Bool, Bool?) -> Void)) {
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/attributes/SERVER_SCOPE?keys=maintenance")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             var maintenanceStatus: Bool = false//0 high 1 low
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [[String: Any]] {
                 if dictionary.count > 0{
                     maintenanceStatus = dictionary[0]["value"] as! Bool
                 }
             }
             completion(nil, true, maintenanceStatus)
         }
         task.resume()
     }

    static func getActiveAlarmsByDeviceId(idDevice:String, token: String, completion:@escaping ((Error?, Bool, Bool?) -> Void)) {
        let url = URL(string: "https://app.weelab.io:8080/api/alarm/DEVICE/" + idDevice + "?fetchOriginator=true&searchStatus=ACTIVE&pageSize=1000&page=0")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 if(dictionary["totalElements"] as! Int > 0){
                     //*********************************************
                     self.getMaintenaceState(idDevice: "" + idDevice, token: token) { error, success, maintenaceState in
                         if success, let state = maintenaceState {
                             if(state){
                                 completion(nil, true, false)
                             }else{
                                 completion(nil, true, true)
                             }
                         }
                     }
                     //*********************************************
                 } else{
                     completion(nil, true, false)
                 }
             } else{
                 return
             }
         }
         task.resume()
     }
    
    static func getTimeSeriesByDeviceId(idDevice:String, token: String, completion:@escaping ((Error?, Bool, [CGFloat]?) -> Void)) {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        let now =  since1970 * 1000
        let startTime = now - (3600000 * 24 * 7)
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/timeseries?keys=temperature&interval=3600000&limit=10000&agg=NONE&useStrictDataTypes=false&orderBy=ASC&startTs=" + String(format: "%.0f", startTime) + "&endTs=" + String(format: "%.0f", now))!

        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             var timeSeries: [CGFloat] = []
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 let posts = dictionary["temperature"] as? [[String: Any]] ?? []
                 for post in posts{
                     if let temperature = (post["value"] as? NSString)?.doubleValue {
                         timeSeries.append(temperature)
                     }
                 }
                 completion(nil, true, timeSeries)
             } else{
                 return
             }
         }
         task.resume()
     }
    
    static func getDeviceAndTimeSeries(idDevice:String, token: String, completion:@escaping ((Error?, Bool, DeviceAndTimeSeries?) -> Void)) {
        let url = URL(string: "https://app.weelab.io:8080/api/device/" + idDevice)!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             guard let data = data else {
                 completion(nil, false, nil)
                 return
             }
             var deviceAndTimeSeries = DeviceAndTimeSeries()
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 if let name = dictionary["label"] as? String {
                     deviceAndTimeSeries.name = name // working
                 } else if let name = dictionary["name"] as? String {
                     deviceAndTimeSeries.name = name // working
                 }
             if let id = dictionary["id"] as? [String: Any] {
                 if let idId = id["id"] as? String {
                     deviceAndTimeSeries.id = idId
                     }
                 }
             }
             //****************************************************
             self.getLastTelemetry(idDevice: "" + idDevice, token:  token) { error, success, lastTelemetry in
                 if success, let lastTelemetry = lastTelemetry {
                     if lastTelemetry.count > 1 {
                         deviceAndTimeSeries.lastTelemetryTemperature = lastTelemetry[0]
                         deviceAndTimeSeries.lastTelemetryHumidity = lastTelemetry[1]
                     }
                     //****************************************************
                     self.getThresholdHighAndLow(idDevice: "" + idDevice, token: token) { error, success, thresholdHighAndLow in
                         if success, let thresholdHighAndLow = thresholdHighAndLow {
                             if thresholdHighAndLow.count > 1 {
                                 deviceAndTimeSeries.temperatureThresholdHigh = thresholdHighAndLow[0]
                                 deviceAndTimeSeries.temperatureThresholdLow = thresholdHighAndLow[1]
                             }
                             //****************************************************
                             self.getActiveAlarmsByDeviceId(idDevice: "" + idDevice, token:  token) { error, success, hasActiveAlarms in
                                 if success, let hasActiveAlarms = hasActiveAlarms {
                                     deviceAndTimeSeries.isAlarmActive = hasActiveAlarms
                                     //****************************************************
                                     self.getTimeSeriesByDeviceId(idDevice: "" + idDevice, token: token) { error, success, timeSeries in
                                         if success, let timeSeries = timeSeries {
                                             deviceAndTimeSeries.listTelemetryToDraw = timeSeries
                                             self.getMaintenaceState(idDevice: "" + idDevice, token: token) { error, success, maintenaceState in
                                                 if success, let state = maintenaceState {
                                                     if(state){
                                                         deviceAndTimeSeries.isAlarmActive = false
                                                     }
                                                     deviceAndTimeSeries.isMaintenanceActive = state
                                                     let nnnname = deviceAndTimeSeries.name
                                                     print("******************** \(nnnname)")
                                                     completion(nil, true, deviceAndTimeSeries)
                                                     return
                                                 }
                                                 else{
                                                     deviceAndTimeSeries.isMaintenanceActive = false
                                                     completion(nil, true, deviceAndTimeSeries)
                                                     return
                                                 }
                                             }
                                             return
                                         } else{
                                             return
                                         }
                                     }
                                     //****************************************************
                                 } else{
                                     return
                                 }
                             }
                             //****************************************************
                         } else{
                             return
                         }
                     }
                     //****************************************************
                 } else{
                     return
                 }
             }
             //****************************************************
         }
         task.resume()
     }
    
}


