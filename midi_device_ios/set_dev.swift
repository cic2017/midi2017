//
//  set_dev.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/6/27.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import UIKit
import Foundation

/*
class get_dev_from
{
    weak var params_protocol:data_protocol?
    func start()
    {
        print("[main page] count:\(dev_array.count)")
        self.params_protocol?.returnClass(dev_array: self.dev_array)
    }
}
*/
class set_dev: UIViewController, data_protocol {
    

    func returnClass(dev_array: Array<Any>) {
        print("[dev page] count:\(dev_array.count)")
        for (index,destName) in dev_array.enumerated()
        {
            print("dev_page Destination #\(index): \(destName)\n")
        }
    }


    //var obj = get_dev_from()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("set dev page\n")
       // obj.params_protocol = self
       // obj.start()
        // Do any additional setup after loading the view.
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
