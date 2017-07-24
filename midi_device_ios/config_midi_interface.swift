//
//  core_midi_event.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/6/20.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import Foundation
import CoreMIDI
import os.log

import UIKit


let NOTIFICATION_NOTE = Notification.Name.init("MIDI_NOTE_NOTIFICATION")
let NOTIFICATION_DEV = Notification.Name.init("MIDI_DEV_NOTIFICATION")

protocol data_protocol:class
{
    func returnClass(dev_array:Array<Any>)
}

struct dict
{
    var name:String!
    var id:UInt8!
}

class config_midi_interface: UIViewController, UITabBarControllerDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate
{
    
    var active_textField:UITextField!
    let pickview = UIPickerView()
    var current_arr = [dict]()                      //for pickview confiruration
    
    @IBOutlet weak var instrusments_name: UILabel!
    @IBOutlet weak var use_local_synth: UISwitch!
    @IBOutlet weak var out_dev_num: UITextField!

    @IBOutlet weak var current_note_index: UILabel!
    @IBOutlet weak var channel_num: UITextField!
    @IBOutlet weak var midi_file_name: UILabel!
    @IBOutlet weak var cc_slider: UISlider!
    
    @IBOutlet weak var app_version: UILabel!
    @IBOutlet weak var intstrument_name: UITextField!
    @IBOutlet weak var minimal_cc_show: UILabel!
    @IBOutlet weak var quantizatin_cc_show: UILabel!
    @IBOutlet var quantization_cc: UIView!
    @IBOutlet weak var quantization_slider: UISlider!
    
    
    @IBAction func change_local_synth(_ sender: Any) {
        if(use_local_synth.isOn)
        {
            globalInfo.midi_dev_obj.use_local_sythesizer = true
        }
        else
        {
            globalInfo.midi_dev_obj.use_local_sythesizer = false
        }
    }
    
    @IBAction func play_sound_on(_ sender: UIButton) {
        
        globalInfo.midi_dev_obj.play_note_on(key:0x81)
        //globalInfo.note = midi_seq_.current_note
    }
    
    @IBAction func change_minimal_cc(_ sender: UISlider) {
        minimal_cc_show.text = String(Int(sender.value))
        globalInfo.midi_dev_obj.minimal_cc = UInt8(sender.value)
    }
    
    @IBAction func change_quantization_cc(_ sender: UISlider) {
        quantizatin_cc_show.text = String(Int(sender.value))
        globalInfo.midi_dev_obj.quantization = Int(sender.value)
        globalInfo.midi_dev_obj.change_quantity()
    }
    
    @IBAction func play_sound_off(_ sender: UIButton) {
        globalInfo.midi_dev_obj.play_note_off(key:0x81)
    }


    @IBAction func play_note(_ sender: UIButton) {
        //let num:Int? = Int(out_dev.text!)
        //midi_device.midi_play_note(dev_num: num!)
        //status_block.text.append(midi_seq_.note)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //show version
        if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            app_version.text = "ver." + version
        }
        out_dev_num.delegate = self
        channel_num.delegate = self
        intstrument_name.delegate = self
        pickview.delegate = self
        pickview.dataSource = self
        out_dev_num.inputView = pickview
        channel_num.inputView = pickview
        intstrument_name.inputView = pickview
        self.tabBarController?.delegate = self
        self.cc_slider.value = Float(Int(80))
        self.quantization_slider.value = Float(Int(globalInfo.midi_dev_obj.quantization))
        quantizatin_cc_show.text = String(globalInfo.midi_dev_obj.quantization)
        if(globalInfo.midi_dev_obj.dev_array.count == 0)
        {
            out_dev_num.isEnabled = false
        }
        else
        {
            out_dev_num.isEnabled = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(config_midi_interface.got_dev_change_event), name: NOTIFICATION_DEV, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        log(str:"file:\(globalInfo.select_file.path)")
        midi_file_name.text = globalInfo.select_file.lastPathComponent
        globalInfo.midi_dev_obj.midi_seq_.midiFileURL = globalInfo.select_file
        globalInfo.midi_dev_obj.midi_seq_.load_music()
        
        //instrusments_name.text = globalInfo.instrusment_.name
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func got_dev_change_event(notification:Notification) -> Void
    {
        log(str:"got event")
        if(globalInfo.midi_dev_obj.dev_array.count == 0)
        {
            out_dev_num.isEnabled = false
        }
        else
        {
            out_dev_num.isEnabled = true
        }
    }
    /* //Close keybroad
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        out_dev_num.resignFirstResponder()
        channel_num.resignFirstResponder()
    }
    */
    //textfield and pickview
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        active_textField = textField
        
        switch textField
        {
        case out_dev_num:
            log(str:"Edit out dev")
            current_arr = globalInfo.midi_dev_obj.dev_array
            break
        case channel_num:
            log(str:"Edit channel")
            current_arr = globalInfo.midi_dev_obj.channel
            break
        case intstrument_name:
            log(str:"Edit intstrument")
            current_arr = globalInfo.midi_dev_obj.instrusment_array
            break
        default:
            log(str:"default")
        }
        pickview.reloadAllComponents()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return current_arr.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return current_arr[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        log(str:"didSelect")
        
        if(current_arr[row].name.range(of: "Channel") != nil)
        {
            active_textField.text = String(current_arr[row].id + 1)
            globalInfo.midi_dev_obj.current_channel = current_arr[row].id
        }
        else if(current_arr[row].name.range(of: "Destination") != nil)
        {
            active_textField.text = String(current_arr[row].name)
            globalInfo.midi_dev_obj.current_dev = current_arr[row].id
        }
        else
        {
            active_textField.text = String(current_arr[row].name)
            globalInfo.instrusment_ = current_arr[row]
        
            globalInfo.midi_dev_obj.change_instrusment()
        }
        active_textField.resignFirstResponder()
        
    }

    
    func textViewDidChange(_ textView: UITextView) {
        print("change\n")
    }
}




