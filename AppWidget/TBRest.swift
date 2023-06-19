import Foundation

struct TBRest: Codable {
    
    static func getNewToken(completion:@escaping ((Error?, Bool, String?) -> Void)) {
        // boon tested
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
             if error != nil {
                 completion(nil, true, "error_token") // always success token ok
                 // error_token -> not_connected | no_token->not_logged
                 return
             }
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
                     return
                 } else{
                     completion(nil, true, "error_token")
                     return
                 }
             } else{
                 completion(nil, true, "error_token")
                 return
             }
         }
         task.resume()
     }
    
    static func getCountActiveAlarms(token: String, completion:@escaping ((Error?, Bool, Int?) -> Void)) {
        // boon tested
        let weelab_customer_id = Utils.getCustomerId()
        let url = URL(string: "https://app.weelab.io:8080/api/customer/" + (weelab_customer_id ?? "") + "/devices?pageSize=1000&page=0")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             //true and number if success / false if some error of not connected
             if error != nil {
                 completion(error, false, nil)
                 return
             }
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
                                 //always success /false by default
                                 if success, let hasActiveAlarms = hasActiveAlarms {
                                     listDevicesCount.append(hasActiveAlarms)
                                     if (hasActiveAlarms){ alarmCount = alarmCount + 1}
                                     if (listDevicesCount.count == devices.count){
                                        completion(nil, true, alarmCount)
                                         return
                                     }
                                 }
                             }
                         }
                         else{
                             listDevicesCount.append(false)
                             if (listDevicesCount.count == devices.count){
                                completion(nil, true, alarmCount)
                                 return
                             }
                         }
                     }
                     else{
                         listDevicesCount.append(false)
                         if (listDevicesCount.count == devices.count){
                            completion(nil, true, alarmCount)
                             return
                         }
                     }
                 }
             }else{
                 completion(nil, false, nil)
                 return
             }
         }
         task.resume()
     }
    
        
    static func getListDevicesAndTS(deviceIds: [String], completion:@escaping ((Error?, Bool, [DeviceAndTimeSeries]?, Int?) -> Void)) { // boon tested
        self.getNewToken{ error, success, str in
            if success, let tokenResp = str{
                if tokenResp == "no_token"{
                    completion(nil, false, nil, 0)
                    return
                }
                if tokenResp == "error_token"{
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
                         //always success /empty device by default just with the id
                         if success, let deviceAndTs = deviceAndTimeSeries {
                             listDevicesAndTS.append(deviceAndTs)
                             if (listDevicesAndTS.count == deviceIds.count){
                                 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% put in order
                                 for i in 0..<listDevicesAndTS.count{
                                     for devAux in listDevicesAndTS{
                                         if devAux.id == order[i] {
                                             listDevicesAndTS2.append(devAux)
                                             break
                                         }
                                     }
                                 }
                                 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                 // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                 self.getCountActiveAlarms(token: tokenResp) { error, success, countAlarms in
                                     // true and number || false
                                     if success, let cAlarms = countAlarms {
                                         if listDevicesAndTS2.count > 0 {
                                             completion(nil, true, listDevicesAndTS2, cAlarms)//working
                                             return
                                         }else{
                                             completion(nil, false, nil, 0)
                                             return
                                         }
                                     } else{
                                         if listDevicesAndTS2.count > 0 {
                                             completion(nil, true, listDevicesAndTS2, 0)
                                             return
                                         }else{
                                             completion(nil, false, nil, 0)
                                             return
                                         }
                                     }
                                 }
                                // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                             }
                         } else{ // if some error in any device
                             var deviceAndTimeSeriesNull = DeviceAndTimeSeries()
                             deviceAndTimeSeriesNull.id = id
                             deviceAndTimeSeriesNull.deviceName = ""
                             deviceAndTimeSeriesNull.lastTelemetryTemperature = -99999
                             deviceAndTimeSeriesNull.lastTelemetryHumidity = -99999
                             deviceAndTimeSeriesNull.temperatureThresholdHigh = -99999
                             deviceAndTimeSeriesNull.temperatureThresholdLow = -99999
                             var timeSeriesNull: [CGFloat] = []
                             timeSeriesNull.append(0.0)
                             deviceAndTimeSeriesNull.listTelemetryToDraw = timeSeriesNull
                             deviceAndTimeSeriesNull.isAlarmActive = false
                             deviceAndTimeSeriesNull.isMaintenanceActive = false
                             deviceAndTimeSeriesNull.isDeviceActive = true
                             listDevicesAndTS.append(deviceAndTimeSeriesNull)
                             if (listDevicesAndTS.count == deviceIds.count){
                                 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% put in order
                                 for i in 0..<listDevicesAndTS.count{
                                     for devAux in listDevicesAndTS{
                                         if devAux.id == order[i] {
                                             listDevicesAndTS2.append(devAux)
                                             break
                                         }
                                     }
                                 }
                                 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                 // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                 self.getCountActiveAlarms(token: tokenResp) { error, success, countAlarms in
                                     // true and number || false
                                     if success, let cAlarms = countAlarms {
                                         if listDevicesAndTS2.count > 0 {
                                             completion(nil, true, listDevicesAndTS2, cAlarms)//working
                                             return
                                         }else{
                                             completion(nil, false, nil, 0)
                                             return
                                         }
                                     } else{
                                         if listDevicesAndTS2.count > 0 {
                                             completion(nil, true, listDevicesAndTS2, 0)
                                             return
                                         }else{
                                             completion(nil, false, nil, 0)
                                             return
                                         }
                                     }
                                 }
                                // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                             }
                         }
                    }
                } // end for id
                // ***********************************************
            } // end of if success (always)
            else{
                completion(nil, false, nil, 0)
                return
            }
        }
     }
    
    static func getListDevicesNamesAndIds(completion:@escaping ((Error?, Bool, [DeviceAndTimeSeries]?) -> Void)) { // tested boon
        self.getNewToken{ error, success, str in
            //always success
            if success, let tokenResp = str{
                if tokenResp == "no_token"{
                    completion(nil, false, nil)
                    return
                }
                if tokenResp == "error_token"{
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
                     if error != nil {
                         completion(error, false, nil)
                         return
                     }
                     guard let data = data else {
                         completion(nil, false, nil)
                         return
                     }
                     var listDevicesAndTS: [DeviceAndTimeSeries] = []
                     let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
                     if let devices = json?["data"] as? [[String: Any]] {
                         var cont: Int = 0
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
                                     deviceAndTimeSeries.deviceName = "\(tempName)"
                                     deviceAndTimeSeries.temperatureThresholdHigh = CGFloat(0.0)
                                     deviceAndTimeSeries.temperatureThresholdLow = CGFloat(0.0)
                                     deviceAndTimeSeries.lastTelemetryTemperature = CGFloat(0.0)
                                     deviceAndTimeSeries.lastTelemetryHumidity = CGFloat(0.0)
                                     deviceAndTimeSeries.isAlarmActive = false
                                     deviceAndTimeSeries.isMaintenanceActive = false
                                     deviceAndTimeSeries.isDeviceActive = true
                                     deviceAndTimeSeries.listTelemetryToDraw = [CGFloat(0.0), CGFloat(0.0)]
                                     listDevicesAndTS.append(deviceAndTimeSeries)
                                     cont = cont + 1
                                     if (cont == devices.count){
                                         completion(nil, true, listDevicesAndTS)//working
                                         return
                                     }
                                 } else{
                                     cont = cont + 1
                                     if (cont == devices.count){
                                         if listDevicesAndTS.count > 0{
                                             completion(nil, true, listDevicesAndTS)
                                             return
                                         }else{
                                             completion(nil, false, nil)
                                             return
                                         }
                                     }
                                 }
                             }
                             else{
                                 cont = cont + 1
                                 if (cont == devices.count){
                                     if listDevicesAndTS.count > 0{
                                         completion(nil, true, listDevicesAndTS)
                                         return
                                     }else{
                                         completion(nil, false, nil)
                                         return
                                     }
                                 }
                             }
                         } //end of for
                     }else{
                         if listDevicesAndTS.count > 0{
                             completion(nil, true, listDevicesAndTS)
                             return
                         }else{
                             completion(nil, false, nil)
                             return
                         }
                     }
                 }
                 task.resume()
                // **********************************************
            }
            else{
                completion(nil, false, nil)
                return
            }
        }
        
     }
    

    static func getDefaultListDevicesNamesAndIds(nMax: Int, completion:@escaping ((Error?, Bool, [DeviceAndTimeSeries]?) -> Void)) { // tested boon
        self.getNewToken{ error, success, str in
            if error != nil { // always success
                completion(error, false, nil)
                return
            }
            if success, let tokenResp = str{ // always success
                if tokenResp == "no_token"{
                    completion(nil, false, nil)
                    return
                }
                if tokenResp == "error_token"{
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
                     if error != nil {
                         completion(error, false, nil)
                         return
                     }
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
                         var cont: Int = 0
                         for (device) in devicesAux {
                             // ***********************************************
                             var tempName = ""
                             if let name = device["label"] as? String {
                                 tempName = name
                             } else if let name = device["name"] as? String {
                                 tempName = name
                             }
                             if let id = device["id"] as? [String: Any] {
                                 if let idId = id["id"] as? String {
                                     order.append(idId)
                                     var deviceAndTimeSeries = DeviceAndTimeSeries()
                                     deviceAndTimeSeries.id = idId
                                     deviceAndTimeSeries.deviceName = "\(tempName)"
                                     deviceAndTimeSeries.temperatureThresholdHigh = CGFloat(0.0)
                                     deviceAndTimeSeries.temperatureThresholdLow = CGFloat(0.0)
                                     deviceAndTimeSeries.lastTelemetryTemperature = CGFloat(0.0)
                                     deviceAndTimeSeries.lastTelemetryHumidity = CGFloat(0.0)
                                     deviceAndTimeSeries.isAlarmActive = false
                                     deviceAndTimeSeries.isMaintenanceActive = false
                                     deviceAndTimeSeries.isDeviceActive = true
                                     deviceAndTimeSeries.listTelemetryToDraw = [CGFloat(0.0), CGFloat(0.0)]
                                     listDevicesAndTS.append(deviceAndTimeSeries)
                                     cont = cont + 1
                                     if (cont == max){
                                         // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% re order
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
                                         return
                                     }
                                 }
                                 else{
                                     cont = cont + 1
                                     if cont == max {
                                         if listDevicesAndTS.count > 0 {
                                             completion(nil, true, listDevicesAndTS)
                                             return
                                         } else{
                                             completion(nil, false, nil)
                                             return
                                         }
                                     }
                                 }
                             }
                             else{
                                 cont = cont + 1
                                 if cont == max {
                                     if listDevicesAndTS.count > 0 {
                                         completion(nil, true, listDevicesAndTS)
                                         return
                                     } else{
                                         completion(nil, false, nil)
                                         return
                                     }
                                 }
                             }
                             // ***********************************************
                         } //end of for
                     }
                     else{
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
    
    static func getDefaultListDevices(nMax: Int, strToken: String, completion:@escaping ((Error?, Bool, [DeviceAndTimeSeries]?, Int?) -> Void)) { //tested boon
        // *******************************************
        let weelab_customer_id = Utils.getCustomerId()
        let url = URL(string: "https://app.weelab.io:8080/api/customer/" + (weelab_customer_id ?? "") + "/devices?pageSize=1000&page=0")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(strToken)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             if error != nil {
                 completion(error, false, nil, 0)
                 return
             }
             guard let data = data else {
                 completion(nil, false, nil, 0)
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
                 var cont: Int = 0
                 for (device) in devicesAux {
                     if let id = device["id"] as? [String: Any] {
                         if let idId = id["id"] as? String {
                             order.append(idId)
                             self.getDeviceAndTimeSeries(idDevice: "\(idId)", token: strToken) { error, success, deviceAndTimeSeries in
                                 //always success -> empty by default with id
                                 if success, let deviceAndTs = deviceAndTimeSeries {
                                     listDevicesAndTS.append(deviceAndTs)
                                     cont = cont + 1
                                     if (cont == max){
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
                                         // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                         self.getCountActiveAlarms(token: strToken) { error, success, countAlarms in
                                             //true and number || false if error or not_connected
                                             if success, let cAlarms = countAlarms {
                                                completion(nil, true, listDevicesAndTS2, cAlarms)//working
                                                 return
                                             } else{
                                                 completion(nil, true, listDevicesAndTS2, 0)//working
                                                 return
                                             }
                                         }
                                        // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                     }
                                 }
                             }
                         }
                         else{
                             cont = cont + 1
                             if (cont == max){
                                 if listDevicesAndTS.count > 0 {
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
                                     // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                     self.getCountActiveAlarms(token: strToken) { error, success, countAlarms in
                                         //true and number || false if error or not_connected
                                         if success, let cAlarms = countAlarms {
                                             completion(nil, true, listDevicesAndTS2, cAlarms)//working
                                             return
                                         } else{
                                             completion(nil, true, listDevicesAndTS2, 0)//working
                                             return
                                         }
                                     }
                                     // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                 }
                                 else{
                                     completion(nil, false, nil, 0)
                                     return
                                 }
                                 //////
                             }
                         }
                     }
                     else{
                         cont = cont + 1
                         if (cont == max){
                             if listDevicesAndTS.count > 0 {
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
                                 // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                                 self.getCountActiveAlarms(token: strToken) { error, success, countAlarms in
                                     //true and number || false if error or not_connected
                                     if success, let cAlarms = countAlarms {
                                         completion(nil, true, listDevicesAndTS2, cAlarms)//working
                                         return
                                     } else{
                                         completion(nil, true, listDevicesAndTS2, 0)//working
                                         return
                                     }
                                 }
                                 // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
                             }
                             else{
                                 completion(nil, false, nil, 0)
                                 return
                             }
                             //////
                         }
                     }
                 } //end of for
             }
             else{
                 completion(nil, false, nil, 0)
                 return
             }
         }
         task.resume()
     }
    

    static func getLastTelemetry(idDevice:String, token: String, completion:@escaping ((Error?, Bool, [Double]?) -> Void)) { // tested boon
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/timeseries?keys=temperature,humidity&useStrictDataTypes=true")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             var lastTelemetry: [Double] = []
             lastTelemetry.append(-99999 as Double)
             lastTelemetry.append(-99999 as Double)
             if error != nil {
                 completion(nil, true, lastTelemetry)
                 return
             }
             guard let data = data else {
                 completion(nil, true, lastTelemetry)
                 return
             }
             
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                     if let temperature = dictionary["temperature"] as? [[String: Double]]{
                         if temperature.count > 0{
                             if temperature[0]["value"] != nil {
                                 if let t = temperature[0]["value"]{
                                     lastTelemetry[0] = t
                                 }
                             }
                         }
                     }
                     if let humidity = dictionary["humidity"] as? [[String: Double]]{
                         if humidity.count > 0 {
                             if humidity[0]["value"] != nil {
                                 if let h = humidity[0]["value"] {
                                     lastTelemetry[1] = h
                                 }
                             }
                         }
                     }
                 }
             completion(nil, true, lastTelemetry)
             return
         }
         task.resume()
     }

    static func getThresholdHighAndLow(idDevice:String, token: String, completion:@escaping ((Error?, Bool, [Double]?) -> Void)) { // tested boon
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/attributes/SERVER_SCOPE?keys=temperatureThresholdHigh&keys=temperatureThresholdLow")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             var thresholdHighAndLow: [Double] = []//0 high 1 low
             thresholdHighAndLow.append(-99999)
             thresholdHighAndLow.append(-99999)
             if error != nil {
                 completion(nil, true, thresholdHighAndLow)// always success needed
                 return
             }
             guard let data = data else {
                 completion(nil, true, thresholdHighAndLow)// always success needed
                 return
             }
             
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [[String: Any]] {
                 if dictionary.count > 1{
                     if(dictionary[0]["key"] as! String == "temperatureThresholdHigh"){
                         if dictionary[0]["value"] != nil {
                             if let th = dictionary[0]["value"] as? Double{
                                 thresholdHighAndLow[0] = th
                             }
                         }
                         if dictionary[1]["value"] != nil {
                             if let th = dictionary[1]["value"] as? Double{
                                 thresholdHighAndLow[1] = th
                             }
                         }
                     } else{
                         if dictionary[1]["value"] != nil {
                             if let th = dictionary[1]["value"] as? Double{
                                 thresholdHighAndLow[0] = th
                             }
                         }
                         if dictionary[0]["value"] != nil {
                             if let th = dictionary[0]["value"] as? Double{
                                 thresholdHighAndLow[1] = th
                             }
                         }
                     }
                 } else if dictionary.count > 0 {
                     if(dictionary[0]["key"] as! String == "temperatureThresholdHigh"){
                         if let th = dictionary[0]["value"] as? Double{
                             thresholdHighAndLow[0] = th
                         }
                     } else{
                         if let th = dictionary[0]["value"] as? Double{
                             thresholdHighAndLow[1] = th
                         }
                     }
                 }
             }
             completion(nil, true, thresholdHighAndLow)
             return
         }
         task.resume()
     }
    
    static func getMaintenaceState(idDevice:String, token: String, completion:@escaping ((Error?, Bool, Bool?) -> Void)) {//tested boon
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/attributes/SERVER_SCOPE?keys=maintenance")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             if error != nil {
                 completion(nil, true, false)//always success needed, false by default
                 return
             }
             guard let data = data else {
                 completion(nil, true, false)//always success needed, false by default
                 return
             }
             var maintenanceStatus: Bool = false // by default
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [[String: Any]] {
                 if dictionary.count > 0{
                     if dictionary[0]["value"] != nil {
                         if let maintenanceSt = dictionary[0]["value"] as? Bool {
                             maintenanceStatus = maintenanceSt
                         }
                     }
                 }
             }
             completion(nil, true, maintenanceStatus)
             return
         }
         task.resume()
     }
    
    static func getActiveState(idDevice:String, token: String, completion:@escaping ((Error?, Bool, Bool?) -> Void)) { // tested boon
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/attributes/SERVER_SCOPE?keys=active")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             if error != nil {
                 completion(nil, true, true)//always success needed, true by default
                 return
             }
             guard let data = data else {
                 completion(nil, true, true)//always success needed, true by default
                 return
             }
             var activeStatus: Bool = true// active by default
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [[String: Any]] {
                 if dictionary.count > 0{
                     if dictionary[0]["value"] != nil {
                         if let activeSt = dictionary[0]["value"] as? Bool {
                             activeStatus = activeSt
                         }
                     }
                 }
             }
             completion(nil, true, activeStatus)
             return
         }
         task.resume()
     }

    static func getActiveAlarmsByDeviceId(idDevice:String, token: String, completion:@escaping ((Error?, Bool, Bool?) -> Void)) { // tested boon
        let url = URL(string: "https://app.weelab.io:8080/api/alarm/DEVICE/" + idDevice + "?fetchOriginator=true&searchStatus=ACTIVE&pageSize=1000&page=0")!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             if error != nil{
                 completion(nil, true, false)// always success needed
                 return
             }
             guard let data = data else {
                 completion(nil, true, false)// always success needed
                 return
             }
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 if dictionary["totalElements"] != nil {
                     if let totalEl = dictionary["totalElements"] as? Int{
                         if(totalEl > 0){
                             //*********************************************
                             self.getMaintenaceState(idDevice: "" + idDevice, token: token) { error, success, maintenaceState in
                                 //always success, false by default
                                 if success, let state = maintenaceState {
                                     if(state){
                                         completion(nil, true, false)
                                         return
                                     }else{
                                         completion(nil, true, true)
                                         return
                                     }
                                 }
                             }
                             //*********************************************
                         } else{
                             completion(nil, true, false)
                             return
                         }
                     } else{
                         completion(nil, true, false)
                         return
                     }
                 }// en if there's key
                 else{
                     completion(nil, true, false)
                     return
                 }
             } else{
                 completion(nil, true, false)
                 return
             }
         }
         task.resume()
     }
    
    static func getTimeSeriesByDeviceId(idDevice:String, token: String, completion:@escaping ((Error?, Bool, [CGFloat]?) -> Void)) { // tested boon
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        let now =  since1970 * 1000
        let startTime = now - (3600000 * 24 * 7)
        let url = URL(string: "https://app.weelab.io:8080/api/plugins/telemetry/DEVICE/" + idDevice + "/values/timeseries?keys=temperature&interval=3600000&limit=10000&agg=NONE&useStrictDataTypes=false&orderBy=ASC&startTs=" + String(format: "%.0f", startTime) + "&endTs=" + String(format: "%.0f", now))!

        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             if error != nil {
                 var timeSeries2: [CGFloat] = []
                 timeSeries2.append(0.0 as CGFloat)
                 completion(nil, true, timeSeries2)// always success needed [0.0] by default
                 return
             }
             guard let data = data else {
                 var timeSeries2: [CGFloat] = []
                 timeSeries2.append(0.0 as CGFloat)
                 completion(nil, true, timeSeries2)// always success needed [0.0] by default
                 return
             }
             var floatArray: [CGFloat] = []
             var tsIndexArray: [Double] = []
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 let rows = dictionary["temperature"] as? [[String: Any]] ?? []
                 var mycont = 0
                 for row in rows{
                     mycont = mycont + 1
                     if let temperature = (row["value"] as? NSString)?.doubleValue {
                         floatArray.append(temperature)
                     }
                     if let ts = (row["ts"]){
                         let tsString: String = "\(ts)"
                         let tsNumber: Double = Double(tsString) ?? 0.0
                         if tsNumber > 1000 { // big number expected
                             tsIndexArray.append(tsNumber)
                         }
                     }
                 }
                 if floatArray.count > 0 {
                     if floatArray.count == tsIndexArray.count{
                         let newArray = reduceTSArray(floatArray: floatArray, tsIndexArray: tsIndexArray)
                         if newArray.count > 1{
                             completion(nil, true, newArray)
                             return
                         }else{
                             completion(nil, true, floatArray)
                             return
                         }
                     } else{
                         completion(nil, true, floatArray)
                         return
                     }
                 } else{
                     var timeSeries2: [CGFloat] = []
                     timeSeries2.append(0.0 as CGFloat)
                     completion(nil, true, timeSeries2)// always success needed [0.0] by default
                     return
                 }
             } else{
                 var timeSeries2: [CGFloat] = []
                 timeSeries2.append(0.0 as CGFloat)
                 completion(nil, true, timeSeries2)// always success needed [0.0] by default
                 return
             }
         }
         task.resume()
     }
    

    
    static func reduceTSArray(floatArray: [CGFloat], tsIndexArray: [Double]) -> Array<CGFloat> {
        let floatArray = floatArray
        let tsIndexArray = tsIndexArray
        var floatArrayReduce: [CGFloat] = []
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        let now: Double =  since1970 * 1000
        if floatArray.count > 1 {
            var tempArray4hours: [CGFloat] = []
            var commonStart: Int = 0
            var cont4hours = 1
            for _ in 0 ... 41 { // 7 days * 6[4hours]
                tempArray4hours.removeAll()
                for k in commonStart ... tsIndexArray.count - 1 {
                    //604800000 -> 3600000 * 24 * 7; 4 * 3600000 -> 14400000
                    let startTimeNew4Hours: Double = (now) - Double((604800000 - (14400000 * cont4hours)))
                    if tsIndexArray[k] >= startTimeNew4Hours {
                        commonStart = k
                        break
                    }else{
                        tempArray4hours.append(floatArray[k])
                    }
                }
                if tempArray4hours.count > 0 {
                    if (tempArray4hours.count > 1) {
                        var tsMax: CGFloat = tempArray4hours[0]
                        var tsMin: CGFloat = tempArray4hours[0]
                        var indexMax = 0
                        var indexMin = 0
                        for c in 0 ... tempArray4hours.count - 1 {
                            if (tempArray4hours[c] > tsMax){
                                tsMax = tempArray4hours[c]
                                indexMax = c
                            }
                            if tempArray4hours[c] < tsMin {
                                tsMin = tempArray4hours[c]
                                indexMin = c
                            }
                        }
                        if indexMax > indexMin {
                            floatArrayReduce.append(tsMin)
                            floatArrayReduce.append(tsMax)
                        }else{
                            floatArrayReduce.append(tsMax)
                            floatArrayReduce.append(tsMin)
                        }
                    }
                    else{
                        floatArrayReduce.append(tempArray4hours[0])
                    }
                }
                cont4hours = cont4hours + 1
            }
            if floatArrayReduce.count > 0{
                let lastTS = floatArray[floatArray.count - 1]
//                floatArray = floatArrayReduce
                floatArrayReduce.append(lastTS)
            }
            else{
                floatArrayReduce.append(0.0 as CGFloat)
            }
        }
        return floatArrayReduce

    }
    
    static func getDeviceAndTimeSeries(idDevice:String, token: String, completion:@escaping ((Error?, Bool, DeviceAndTimeSeries?) -> Void)) { // boon tested
        let url = URL(string: "https://app.weelab.io:8080/api/device/" + idDevice)!
        var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         let task = URLSession.shared.dataTask(with: request){ data, response, error in
             
             var deviceAndTimeSeriesNull = DeviceAndTimeSeries()
             deviceAndTimeSeriesNull.id = idDevice
             deviceAndTimeSeriesNull.deviceName = ""
             deviceAndTimeSeriesNull.lastTelemetryTemperature = -99999
             deviceAndTimeSeriesNull.lastTelemetryHumidity = -99999
             deviceAndTimeSeriesNull.temperatureThresholdHigh = -99999
             deviceAndTimeSeriesNull.temperatureThresholdLow = -99999
             var timeSeriesNull: [CGFloat] = []
             timeSeriesNull.append(0.0)
             deviceAndTimeSeriesNull.listTelemetryToDraw = timeSeriesNull
             deviceAndTimeSeriesNull.isAlarmActive = false
             deviceAndTimeSeriesNull.isMaintenanceActive = false
             deviceAndTimeSeriesNull.isDeviceActive = true
                         
             if error != nil {
                 completion(nil, true, deviceAndTimeSeriesNull) //always success needed
                 return
             }
             guard let data = data else {
                 completion(nil, true, deviceAndTimeSeriesNull) //always success needed
                 return
             }
             var deviceAndTimeSeries = DeviceAndTimeSeries()
             let json = try? JSONSerialization.jsonObject(with: data, options: [])
             if let dictionary = json as? [String: Any] {
                 if let name = dictionary["label"] as? String {
                     deviceAndTimeSeries.deviceName = name // working
                 } else if let name = dictionary["name"] as? String {
                     deviceAndTimeSeries.deviceName = name // working
                 } else{
                     deviceAndTimeSeries.deviceName = ""
                 }
             }
             //default values
             deviceAndTimeSeries.id = idDevice
             deviceAndTimeSeries.lastTelemetryTemperature = -99999
             deviceAndTimeSeries.lastTelemetryHumidity = -99999
             deviceAndTimeSeries.temperatureThresholdHigh = -99999
             deviceAndTimeSeries.temperatureThresholdLow = -99999
             deviceAndTimeSeries.listTelemetryToDraw = timeSeriesNull
             deviceAndTimeSeries.isDeviceActive = true
             deviceAndTimeSeries.isAlarmActive = false
             deviceAndTimeSeries.isMaintenanceActive = false
             //****************************************************
             self.getLastTelemetry(idDevice: "" + idDevice, token:  token) { error, success, lastTelemetry in
                 //always success, tempe and humi -99999(Double) by default
                 if success, let lastTelemetry = lastTelemetry {
                     if lastTelemetry.count > 1 {
                         deviceAndTimeSeries.lastTelemetryTemperature = lastTelemetry[0]
                         deviceAndTimeSeries.lastTelemetryHumidity = lastTelemetry[1]
                     }
                     //****************************************************
                     self.getThresholdHighAndLow(idDevice: "" + idDevice, token: token) { error, success, thresholdHighAndLow in
                         //always success -99999(Double) by default
                         if success, let thresholdHighAndLow = thresholdHighAndLow {
                             deviceAndTimeSeries.temperatureThresholdHigh = thresholdHighAndLow[0]
                             deviceAndTimeSeries.temperatureThresholdLow = thresholdHighAndLow[1]
                             //****************************************************
                             self.getActiveAlarmsByDeviceId(idDevice: "" + idDevice, token:  token) { error, success, hasActiveAlarms in
                                 //always success false by default
                                 if success, let hasActiveAlarms = hasActiveAlarms {
                                     deviceAndTimeSeries.isAlarmActive = hasActiveAlarms
                                     //****************************************************
                                     self.getActiveState(idDevice: "" + idDevice, token:  token) { error, success, isActive in
                                         //always success false by default
                                         if success, let isActive = isActive {
                                             deviceAndTimeSeries.isDeviceActive = isActive
                                             //****************************************************
                                             self.getTimeSeriesByDeviceId(idDevice: "" + idDevice, token: token) { error, success, timeSeries in
                                                 //always success [0.0](CGFloat) by default
                                                 if success, let timeSeries = timeSeries {
                                                     deviceAndTimeSeries.listTelemetryToDraw = timeSeries
                                                     self.getMaintenaceState(idDevice: "" + idDevice, token: token) { error, success, maintenaceState in
                                                         //always success, false by default
                                                         if success, let state = maintenaceState {
                                                             if(state){
                                                                 deviceAndTimeSeries.isAlarmActive = false
                                                             }
                                                             deviceAndTimeSeries.isMaintenanceActive = state
                                                             // let nnnname = deviceAndTimeSeries.deviceName
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
                                                     completion(nil, true, deviceAndTimeSeriesNull) //always success needed
                                                     return
                                                 }
                                             }
                                             //****************************************************
                                         } else{
                                             completion(nil, true, deviceAndTimeSeriesNull) //always success needed
                                             return
                                         }
                                     }
                                         //****************************************************
                                 } else{
                                     completion(nil, true, deviceAndTimeSeriesNull) //always success needed
                                     return
                                 }
                             }
                             //****************************************************
                         } else{
                             completion(nil, true, deviceAndTimeSeriesNull) //always success needed
                             return
                         }
                     }
                     //****************************************************
                 } else{
                     completion(nil, true, deviceAndTimeSeriesNull) //always success needed
                     return
                 }
             }
             //****************************************************
         }
         task.resume()
     }
    

    
}


