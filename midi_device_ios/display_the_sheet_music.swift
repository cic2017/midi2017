//
//  display_the_sheet_music.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/7/17.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import UIKit

class global_info
{
    var select_file:URL = Bundle.main.url(forResource: "Morning_in_the_Slag_Ravine_版本1", withExtension: "mid")!
    var instrusment_ = dict(name:"Trumpet", id:56)
    var midi_dev_obj:midi_dev!
    var note:note!
    init()
    {
        log(str:"init global info")
    }
}
var globalInfo = global_info()

class display_the_sheet_music: UIViewController
{

    @IBOutlet weak var test_notification: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(display_the_sheet_music.listener), name: NOTIFICATION_NOTE, object: nil)
       
        // Do any additional setup after loading the view.
        test_notification.text = globalInfo.instrusment_.name
        globalInfo.midi_dev_obj = midi_dev()
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log(str:"")
        // Dispose of any resources that can be recreated.
    }
    
    func listener(notification:Notification) -> Void
    {
        let info = notification.userInfo as? Dictionary<String, note>
        let data:note = (info?["data"])!
        
        test_notification.text = "Index:\(data.index), Tick:\(data.tick)" + ", Bar:\(data.bar_beat.bar), beat:\(data.bar_beat.beat)"
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
