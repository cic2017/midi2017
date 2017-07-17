//
//  display_the_sheet_music.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/7/17.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import UIKit

class display_the_sheet_music: UIViewController {

    @IBOutlet weak var test_notification: UILabel!
    var tap: UITapGestureRecognizer?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //NotificationCenter.default.addObserver(self, selector: #selector(display_the_sheet_music.listener), name: NOTIFICATION_NAME, object: nil)
        NotificationCenter.default.addObserver(forName: NOTIFICATION_NAME, object: nil, queue: OperationQueue.main, using:listener)
        log(str:"")
    }
    /*
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        tap = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        NotificationCenter.default.addObserver(self, selector: #selector(display_the_sheet_music.listener), name: NOTIFICATION_NAME, object: nil)
        log(str:"")
    }
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func listener(notification:Notification)
    {
        log(str:"got note:\(globalInfo.note.index)")
        test_notification.text = String(globalInfo.note.note_msg.note)
        
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
