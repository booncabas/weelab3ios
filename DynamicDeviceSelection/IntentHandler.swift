//
//  IntentHandler.swift
//  DynamicDeviceSelection
//
//  Created by Cubosoft on 3/27/23.
//

import Intents

class IntentHandler: INExtension, SelectDeviceIntentHandling {
    
    func provideDeviceOptionsCollection(for intent: SelectDeviceIntent,
                                        with completion: @escaping (INObjectCollection<Device>?, Error?) -> Void) {
        // *********************************************************
        TBRest.getListDevices { error, success, devices  in
            if success {
                var list: [Device] = []
                let devices = devices
                for i in 0...devices!.count-1 {
                    let dev = Device(identifier: devices![i].id, display: devices![i].name)
                    list.append(dev)
                }
                let collection = INObjectCollection(items: list)
                completion(collection, nil)
            } else{
                completion(nil, nil)
            }
        }
        // **********************************************************
    }
    
    func defaultDevice(for intent: SelectDeviceIntent) -> [Device]? {
        var list: [Device] = []
        var comp: Bool = false
        // **********************************************************
        // boon n Max = to AppWidgetIntent size medium
        TBRest.getDefaultListDevices(nMax: 3) { error, success, devices  in
            if success {
                let devices = devices
                for i in 0...devices!.count-1 {
                    let dev = Device(identifier: devices![i].id, display: devices![i].name)
                    list.append(dev)
                }
                comp = true
            }
            else {
                comp = true
            }
        }
        // ********************************************************
        var cont = 0
        while (comp == false){
            cont = cont + 1
            Thread.sleep(forTimeInterval: 1)
            if cont == 15 {
                break
            }
        }
        if list.count > 0 {
            return list
        } else {
            return nil
        }
    }
      
    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
}
