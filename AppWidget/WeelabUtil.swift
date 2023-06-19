import Foundation

//let weelab_customer_id: String = "b72b2570-69a2-11ed-95fe-4732c9ea5bca"

struct Utils: Codable {
    
    static func daysOfWeek2() -> [String] {
        var dateComponent = DateComponents()
        var currentDate = Date()
//        let date = Date()
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
        return "6498d490-62ba-11ed-9580-699a520459db"
//        return "b72b2570-69a2-11ed-95fe-4732c9ea5bca"// demo
    }

    static func getRefreshToken() -> String? {
// working on weelab flutter
//        let appGroup = "group.appwidget.weelab"
//        guard let name = UserDefaults(suiteName: appGroup)?.value(forKey: "weelab_refresh_token") as? String else {
//            return nil
//        }
//        return name
        
        return "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhdXRvbGFiQHdlZWxhYi5pbyIsInVzZXJJZCI6IjA4YjZmZmMwLWYwNjQtMTFlZC1hNTM3LWQ5ZWJhZjYzYTA4ZCIsInNjb3BlcyI6WyJSRUZSRVNIX1RPS0VOIl0sImlzcyI6InRoaW5nc2JvYXJkLmlvIiwiaWF0IjoxNjg2NjcyNTQ3LCJleHAiOjE2ODcyNzczNDcsImlzUHVibGljIjpmYWxzZSwianRpIjoiNTA5MWJmNWUtNWU5YS00MjEzLWI2NzctYTA4N2VjM2M0MjIxIn0.9coS4tbuy6soTkioBlc136Kf2EON-6Zahac67Oqb8ez5InQDnL6NoD-HjD7L4y7_67U8HJz6kWAflyZYivOgUQ"
//        return "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJkZW1vQHdlZWxhYi5pbyIsInVzZXJJZCI6ImU4ZWZjNzAwLTY5YTItMTFlZC05NWZlLTQ3MzJjOWVhNWJjYSIsInNjb3BlcyI6WyJSRUZSRVNIX1RPS0VOIl0sImlzcyI6InRoaW5nc2JvYXJkLmlvIiwiaWF0IjoxNjg1NzEyMDQ3LCJleHAiOjE2ODYzMTY4NDcsImlzUHVibGljIjpmYWxzZSwianRpIjoiZjBjZWVkZWUtYjNiMS00YWJlLWE2NTQtNTcxOTQ4ZGY5YjlhIn0.RpvSVr6P3ZEvW73pqT7ZbGITtGbaRy_GMDvM9-6MG8NmdjyQpc4sO1NbjVEb1WSSsH_OaBeQm4SormoVGeYguw"

        //        return ""
    }
    
    static func setRefreshToken(refreshToken: String) {
        let appGroup = "group.net.cubosoft.weelab2"
        UserDefaults(suiteName: appGroup)?.setValue(refreshToken, forKey: "weelab_refresh_token")
    }
    
    
}
