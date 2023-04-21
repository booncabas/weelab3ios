import Foundation

//let weelab_customer_id: String = "b72b2570-69a2-11ed-95fe-4732c9ea5bca"

struct Utils: Codable {
    
    static func daysOfWeek2() -> [String] {
        var dateComponent = DateComponents()
        var currentDate = Date()
        let date = Date()
        var resp: [String] = []
        dateComponent.day = 1
        for _ in 0...6{
            let str = "\(currentDate.formatted(.dateTime.weekday()))"
            let newStr = str.prefix(1)
            resp.append("\(newStr)")
            let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)
            currentDate = futureDate!
        }
        return resp
    }
    
    static func daysOfWeek() -> [String] {
        var dateComponent = DateComponents()
        dateComponent.day = 1
        var currentDate = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.init(identifier: Locale.preferredLanguages.first!)
        formatter.setLocalizedDateFormatFromTemplate("E dd-MM-yyyy HH:mm")
        currentDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)!
        var resp: [String] = []
        for _ in 0...6{
            let stringDate = formatter.string(from: currentDate)
//            let str = "\(currentDate.formatted(.dateTime.weekday()))"
            let newStr = stringDate.prefix(1)
            resp.append("\(newStr.uppercased())")
            let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)
            currentDate = futureDate!
        }
        return resp
    }
    
    
    static func getCustomerId() -> String? {
//        let appGroup = "group.appwidget.weelab"
//        guard let name = UserDefaults(suiteName: appGroup)?.value(forKey: "weelab_customer_id") as? String else {
//            return nil
//        }
//        return name
        return "b72b2570-69a2-11ed-95fe-4732c9ea5bca"
    }

    static func getRefreshToken() -> String? {
// working on weelab flutter
//        let appGroup = "group.appwidget.weelab"
//        guard let name = UserDefaults(suiteName: appGroup)?.value(forKey: "weelab_refresh_token") as? String else {
//            return nil
//        }
//        return name
        
        return "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJkZW1vQHdlZWxhYi5pbyIsInVzZXJJZCI6ImU4ZWZjNzAwLTY5YTItMTFlZC05NWZlLTQ3MzJjOWVhNWJjYSIsInNjb3BlcyI6WyJSRUZSRVNIX1RPS0VOIl0sImlzcyI6InRoaW5nc2JvYXJkLmlvIiwiaWF0IjoxNjgxNzM3ODc2LCJleHAiOjE2ODIzNDI2NzYsImlzUHVibGljIjpmYWxzZSwianRpIjoiYWI3OWIyODItOTY1Mi00MmRkLTg2YmEtYmZiZTA2MjA1MWEzIn0.g4Csz1UE9RQoj9wVqMrZ6mqHmhpWvA7psd5A3zutu3IrTYwLjHeTv5zfN_yURl71TtsfuC__cLoPXjcZrO04fg"
    }
    
    static func setRefreshToken(refreshToken: String) {
        let appGroup = "group.net.cubosoft.weelab2"
        UserDefaults(suiteName: appGroup)?.setValue(refreshToken, forKey: "weelab_refresh_token")
    }
    
    
}
