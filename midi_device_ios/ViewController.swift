//
//  ViewController.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/6/8.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    

    @IBOutlet weak var out_dev: UITextField!
    @IBOutlet weak var select_input_dev: UITextField!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var status_block: UITextView!
    //let midi_device = core_midi_event()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("load")
        //midi_device.midi_init()
        //status_block.text.append(midi_device.midi_seq_.note)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

