//
//  ViewController.swift
//  weelab2
//
//  Created by Cubosoft on 4/4/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var lbl1: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setTokenFirstTime()
        lbl1.text = getRefreshToken()
    }
    
    func setTokenFirstTime(){
        let refreshToken = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJkZW1vQHdlZWxhYi5pbyIsInVzZXJJZCI6ImU4ZWZjNzAwLTY5YTItMTFlZC05NWZlLTQ3MzJjOWVhNWJjYSIsInNjb3BlcyI6WyJSRUZSRVNIX1RPS0VOIl0sImlzcyI6InRoaW5nc2JvYXJkLmlvIiwiaWF0IjoxNjgxMTMyNTMzLCJleHAiOjE2ODE3MzczMzMsImlzUHVibGljIjpmYWxzZSwianRpIjoiMzNiZWQ4MjAtNTAwNS00NTRmLWJlOTMtMzkxM2RhY2YzYWRhIn0.ns_7vP4sG5jNgZ2jBsw2hb7bJPDcbF9WQESUmu67ZILx6uBjopqGU0bysN29jMQHZwi-R9yBuBoClH9-8BUNWA"
        let appGroup = "group.net.cubosoft.weelab2"
        UserDefaults(suiteName: appGroup)?.setValue(refreshToken, forKey: "weelab_refresh_token")
    }
    
    func getRefreshToken() -> String? {
        let appGroup = "group.net.cubosoft.weelab2"
        guard let name = UserDefaults(suiteName: appGroup)?.value(forKey: "weelab_refresh_token") as? String else {
            return nil
        }
        return name
    }


}

