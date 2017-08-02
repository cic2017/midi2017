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
class set_dev: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webview: UIWebView!
    var refresh_cntl:UIRefreshControl!
    
    @IBAction func download_midi(_ sender: Any) {
     //   webview.loadRequest(URLRequest(url: URL(string:"https://yuan-test.pancakeapps.com")!))
    }
    //var obj = get_dev_from()

    override func viewDidLoad() {
        super.viewDidLoad()
        webview.loadRequest(URLRequest(url: URL(string:"http://yuan-test.pancakeapps.com")!))
        print("set dev page\n")
        print("test select midi\n")
        super.viewDidLoad()
        refresh_cntl = UIRefreshControl.init()
        refresh_cntl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresh_cntl.addTarget(self, action: #selector(set_dev.refresh), for: UIControlEvents.valueChanged)
        webview.delegate = self
        webview.scrollView.addSubview(refresh_cntl)
       // obj.params_protocol = self
       // obj.start()
        // Do any additional setup after loading the view.
    }
 
    func refresh()
    {
        webview.loadRequest(URLRequest(url: URL(string:"http://yuan-test.pancakeapps.com")!))
        self.refresh_cntl.endRefreshing()
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
