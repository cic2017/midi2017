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
import AVFoundation
import UIKit


let NOTIFICATION_NAME = Notification.Name.init("MIDI_NOTE_NOTIFICATION")

protocol data_protocol:class
{
    func returnClass(dev_array:Array<Any>)
}

extension UITextView {
    
    func scrollToBotom() {
        let range = NSMakeRange(text.characters.count - 1, 1);
        scrollRangeToVisible(range);
    }
    
}

class global_info
{
    var select_file:URL = Bundle.main.url(forResource: "Morning_in_the_Slag_Ravine_版本1", withExtension: "mid")!
    var instrusment_ = dict(name:"Trumpet", id:56)
    var note:note!
}
var globalInfo = global_info()

struct dict
{
    var name:String!
    var id:UInt8!
}

class core_midi_event: UIViewController, UITabBarControllerDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    let midi_seq_ = midi_seq()
    var midiClient = MIDIClientRef()
    var midiInputPortref = MIDIPortRef()
    //var midiClient_out: MIDIClientRef = 0
    var inPort = MIDIPortRef()
    var outPort = MIDIPortRef()
    var src:MIDIEndpointRef = MIDIGetSource(0)
    var processingGraph:AUGraph?
    var samplerUnit:AudioUnit?
    var virtualSourceEndpointRef = MIDIEndpointRef()
    var str_test:String = ""
    var str_event:String = ""
    var timer:Timer?
    var minimal_cc:UInt8 = 0
    var active_textField:UITextField!
    let pickview = UIPickerView()
    var current_dev:UInt8=0
    var current_channel:UInt8 = 0
    var channel=[dict]()
    //var current_arr : [String] = []
    
    var current_arr = [dict]()
    var dev_array = [dict]()
    @IBOutlet weak var instrusments_name: UILabel!
    @IBOutlet weak var use_local_synth: UISwitch!
    @IBOutlet weak var out_dev_num: UITextField!

    @IBOutlet weak var current_note_index: UILabel!
    @IBOutlet weak var channel_num: UITextField!
    @IBOutlet weak var midi_file_name: UILabel!
    @IBOutlet weak var cc_slider: UISlider!
    
    @IBOutlet weak var intstrument_name: UITextField!
    @IBOutlet weak var minimal_cc_show: UILabel!
    
    
    @IBAction func play_sound_on(_ sender: UIButton) {
        print("[main page] count:\(dev_array.count)")
        play_note_on(key:0x81)
        globalInfo.note = midi_seq_.current_note
        
    }
    
    @IBAction func change_minimal_cc(_ sender: UISlider) {
        minimal_cc_show.text = String(Int(sender.value))
        minimal_cc = UInt8(sender.value)
    }
    
    @IBAction func play_sound_off(_ sender: UIButton) {
        play_note_off(key:0x81)
    }


    @IBAction func play_note(_ sender: UIButton) {
        //let num:Int? = Int(out_dev.text!)
        //midi_device.midi_play_note(dev_num: num!)
        //status_block.text.append(midi_seq_.note)
    }
    func prepare_data()
    {
        //init channel arr
        for i in 0...15
        {
            channel.append(dict(name:String(format:"Channel:%d", i+1), id:UInt8(i)))
        }
        
        if(dev_array.count == 0)
        {
            out_dev_num.text = "No avalible dev"
        }
        
        for (key, value) in soundfontPresets
        {
            instrusment_array.append(dict(name:key, id:value))
        }
        
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
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
        self.minimal_cc = UInt8(minimal_cc_show.text!)!
        midi_init()
        display_device()
        prepare_data()
        log(str:"")
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        log(str:"file:\(globalInfo.select_file.path)")
        midi_file_name.text = globalInfo.select_file.lastPathComponent
        midi_seq_.midiFileURL = globalInfo.select_file
        midi_seq_.load_music()
        
        //instrusments_name.text = globalInfo.instrusment_.name
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            current_arr = dev_array
            break
        case channel_num:
            log(str:"Edit channel")
            current_arr = channel
            break
        case intstrument_name:
            log(str:"Edit intstrument")
            current_arr = instrusment_array
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
            current_channel = current_arr[row].id
            log(str:"id:\(current_channel)")
        }
        else if(current_arr[row].name.range(of: "Destination") != nil)
        {
            active_textField.text = String(current_arr[row].name)
            current_dev = current_arr[row].id
        }
        else
        {
            active_textField.text = String(current_arr[row].name)
            globalInfo.instrusment_ = current_arr[row]
            midi_seq_.loadSF2PresetIntoSampler(globalInfo.instrusment_.id)
        }
        active_textField.resignFirstResponder()
        
    }
    
    
    func set_file(file:String)
    {
        log(str: "\(file)")
        midi_file_name.text = file
        
    }
    func display_device()
    {
        dev_array.removeAll()
        let destinationNames = getDestinationNames()
        //dev_array.append(destinationNames.count)
        for (index,destName) in destinationNames.enumerated()
        {
            dev_array.append(dict(name:"Destination #\(index): \(destName)", id:UInt8(index)))
            log(str:"Destination #\(index): \(destName)\n")
        }
        if(out_dev_num.text?.range(of: "No avalible dev") != nil && dev_array.count != 0)
        {
            out_dev_num.text = dev_array[0].name
            current_dev = dev_array[0].id
            out_dev_num.isEnabled = true
        }
        if(dev_array.count == 0)
        {
            out_dev_num.isEnabled = false
            out_dev_num.text = "No avalible dev"
        }

    }
    /*
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tab_index = tabBarController.selectedIndex
        //print("tab bar:\(tab_index)\n")
    }
    */
    
    
    func getDeviceName(_ endpoint:MIDIEndpointRef) -> String? {
        var cfs: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &cfs)
        if status != noErr {
            print("error getting device name")
        }
        
        if let s = cfs {
            return s.takeRetainedValue() as String
        }
        
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        MIDIClientDispose(self.midiClient)
    }
    
    
    
    func getDisplayName(_ obj: MIDIObjectRef) -> String
    {
        var param: Unmanaged<CFString>?
        var name: String = "Error"
        
        let err: OSStatus = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
        if err == OSStatus(noErr)
        {
            name =  param!.takeRetainedValue() as String
        }
        
        return name
    }
    
    
    func getDestinationNames() -> [String]
    {
        var names:[String] = [String]();
        
        let count: Int = MIDIGetNumberOfDestinations();
        for i in 0 ..< count
        {
            let endpoint:MIDIEndpointRef = MIDIGetDestination(i);
            if (endpoint != 0)
            {
                names.append(getDisplayName(endpoint));
            }
        }
        return names;
    }
    
    
    
    func midi_play_note(dev_num: Int, event:MIDINoteMessage)
    {
        
        let destNum = dev_num
        
        let dest:MIDIEndpointRef = MIDIGetDestination(destNum)
        
        var packet1:MIDIPacket = MIDIPacket();
        packet1.timeStamp = 0;
        packet1.length = 3;
        
        packet1.data.0 = 0x90 + current_channel; // Note On event channel 1
        packet1.data.1 = event.note; // Note C3
        packet1.data.2 = event.velocity; // Velocity

       // print(str_event)
        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet1);
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NOTIFICATION_NAME, object: nil)
        }
        

        MIDISend(outPort, dest, &packetList)
        
        //MIDIPortConnectSource(inPort, src, &src)
    }
    
    func midi_play_send_cc(dev_num: Int, packet:MIDIPacket)
    {
        let destNum = dev_num
        
        let dest:MIDIEndpointRef = MIDIGetDestination(destNum)
        var packet1:MIDIPacket = MIDIPacket();
        packet1.timeStamp = 0;
        packet1.length = packet.length
        packet1.data.0 = packet.data.0 + current_channel // Note On event channel 1
        packet1.data.1 = packet.data.1; // Note C3\
        if(packet.data.2 < minimal_cc)
        {
            packet1.data.2 = minimal_cc
        }
        else
        {
            packet1.data.2 = packet.data.2
        }
        
        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet1)
        MIDISend(outPort, dest, &packetList)
    }
    
    func midi_play_note_off(dev_num: Int, event:UInt8)//event:MIDINoteMessage)
    {
        
        let destNum = dev_num
        
        let dest:MIDIEndpointRef = MIDIGetDestination(destNum)
        
        var packet1:MIDIPacket = MIDIPacket();
        packet1.timeStamp = 0;
        packet1.length = 3;
        packet1.data.0 = 0x90 + current_channel // Note On event channel 1
        packet1.data.1 = event; // Note C3\
        packet1.data.2 = 0; // Velocity
        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet1);
        
        MIDISend(outPort, dest, &packetList)
        
        //MIDIPortConnectSource(inPort, src, &src)
    }
    
    func connectSourcesToInputPort() {
        let sourceCount = MIDIGetNumberOfSources()
        print("source count \(sourceCount)")
        
        for srcIndex in 0 ..< sourceCount {
            let midiEndPoint = MIDIGetSource(srcIndex)
            
            let status = MIDIPortConnectSource(inPort,
                                               midiEndPoint,
                                               nil)
            
            if status == noErr {
                print("yay connected endpoint to inputPort")
            } else {
                print("oh crap!")
            }
        }
    }

    func midi_init(midiNotifier: MIDINotifyBlock? = nil, reader: MIDIReadBlock? = nil){
        var status = noErr
         midi_file_name.text = "QQ"
        //observeNotifications()
        //enableNetwork()
        log(str:"global:\(globalInfo.select_file.path)")
        var notifyBlock: MIDINotifyBlock
        
        if midiNotifier != nil {
            notifyBlock = midiNotifier!
        } else {
            notifyBlock = MyMIDINotifyBlock
        }
        
        var readBlock: MIDIReadBlock
        if reader != nil {
            print("reader nil")
            readBlock = reader!
        } else {
            print("reader not nil")
            readBlock = MyMIDIReadBlock
        }
        
        status = MIDIClientCreateWithBlock("MidiTestClient" as CFString, &midiClient, notifyBlock)
        if status == noErr {
            print("created MIDI client", midiClient)
        } else {
            print("error creating MIDI client %@", status)
        }
        //MyMIDIReadBlock
        
        
        status = MIDIInputPortCreateWithBlock(midiClient, "MidiTest_InPort" as CFString, &inPort, readBlock)
        if status == noErr {
            print("created MIDI inputport", inPort)
        } else {
            print("error creating MIDI input port fail %@", status)
        }
        
        status = MIDISourceCreate(midiClient,
                                  "Swift3MIDI.VirtualSource" as CFString,
                                  &virtualSourceEndpointRef
        )
        
        if status == noErr {
            print("created virtual source")
        } else {
            print("error creating virtual source")
        }
        connectSourcesToInputPort()
        
        
         MIDIClientCreate("MidiTestClient" as CFString, nil, nil, &midiClient)
         MIDIOutputPortCreate(midiClient, "MidiTest_OutPort" as CFString, &outPort)
    
        
        //timer =  Timer.scheduledTimer(timeInterval: 0.01, target: self, selector:#selector(self.update_ui), userInfo: nil, repeats: true)
    }
    
    func midi_deinit()
    {
        MIDIClientDispose(self.midiClient)
    }
    var note_mapping = [UInt8:UInt8]() //key:midiDev input, value:midiFile note
    public func play_note_on(key:UInt8)
    {
        var note:MIDINoteMessage = midi_seq_.current_note.note_msg
        if(note_mapping.count != 0)
        {
            delete_note(note:note.note)
            midi_seq_.get_note()
        }
        else
        {
            midi_seq_.get_note()
        }
        note = midi_seq_.current_note.note_msg
        note_mapping[key] = note.note
        //print(total_note_num)
        log(str:"dev:\(Int(current_dev))")
        midi_play_note(dev_num: Int(current_dev), event:note)
        if(use_local_synth.isOn)
        {
            midi_seq_.note_on(channel:current_channel)
        }
    }
    
    public func play_note_off(key:UInt8)
    {
        //let note:MIDINoteMessage = (midi_seq_.current_note.note_msg)
        if(note_mapping[key] != nil)
        {
            let note = note_mapping[key]
            midi_play_note_off(dev_num: Int(current_dev), event:note!)
            if(use_local_synth.isOn)
            {
                midi_seq_.note_off(channel:current_channel, note:note!)
            }
            note_mapping.removeValue(forKey: key)
        }
    }

    func delete_note(note:UInt8)
    {
        for (key, value) in note_mapping
        {
            if(value == note)
            {
                midi_play_note_off(dev_num: Int(current_dev), event:note)
                if(use_local_synth.isOn)
                {
                    midi_seq_.note_off(channel:current_channel, note:note)
                }
            }
        }
    }

    func MyMIDIReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
        let packets = packetList.pointee
        
        let packet:MIDIPacket = packets.packet
       
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to:packet)
        var p = ap.pointee
        //print("num: \(packets.numPackets)\n")
        for _ in 0 ..< packets.numPackets {
            p = ap.pointee
            str_event = handle(p)
            //show_note_event(event:str_event)
            /*
            DispatchQueue.main.async{
                
                self.current_note_index.text = self.str_event
                self.show_input_event.text.append(self.str_event)  //addend string to uitextview
                let range = NSMakeRange(self.show_input_event.text.characters.count - 1, 1)
                self.show_input_event.scrollRangeToVisible(range)

            }
 */
            str_test = String(format:"0x%X", p.data.0)
            ap = MIDIPacketNext(ap)
        }
        
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        print("change\n")
    }
    
    func handle(_ packet:MIDIPacket) -> String {
        
        let status = packet.data.0
        let d1 = packet.data.1
        let d2 = packet.data.2
        let rawStatus = status & 0xF0 // without channel
        let channel = status & 0x0F
        var result=""
        
        switch rawStatus {
            
        case 0x80:
            result = String("Note off. Channel \(channel) note \(d1) velocity \(d2)")
            self.play_note_off(key:d1)
            // forward to sampler
            
        case 0x90:
            result = String("Note on. Channel \(channel) note \(d1) velocity \(d2)")
            self.play_note_on(key:d1)
            // forward to sampler
            
        case 0xA0:
            result = String("Polyphonic Key Pressure (Aftertouch). Channel \(channel) note \(d1) pressure \(d2)")
            
        case 0xB0:
            result = String("[CC] Channel \(channel) controller \(d1) value \(d2)")
            if(d2 < minimal_cc)
            {
                midi_seq_.change_controller(value:minimal_cc, channel:current_channel)
            }
            else
            {
                midi_seq_.change_controller(value:d2, channel:current_channel)
            }
            self.midi_play_send_cc(dev_num: Int(current_dev), packet:packet)
        case 0xC0:
            result = String("[PC] Channel \(channel) program \(d1)")
            
        case 0xD0:
           result = String("Channel Pressure (Aftertouch). Channel \(channel) pressure \(d1)")
            
        case 0xE0:
            result = String("Pitch Bend Change. Channel \(channel) lsb \(d1) msb \(d2)")
            
        default: result = String("Unhandled message \(status)")
        }
        return result
    }
        
    public func MyMIDINotifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
        //show_input_event.text.append("got event\n")
        
        let notification = midiNotification.pointee
        print("MIDI Notify, messageId= \(notification.messageID)")
        print("MIDI Notify, messageSize= \(notification.messageSize)")
        //show_note_event(event:String("MIDI Notify, messageId= \(notification.messageID)"))
        switch notification.messageID {
            
        // Some aspect of the current MIDISetup has changed.  No data.  Should ignore this  message if messages 2-6 are handled.
        case .msgSetupChanged:
            print("MIDI setup changed")
            let ptr = UnsafeMutablePointer<MIDINotification>(mutating: midiNotification)
            //            let ptr = UnsafeMutablePointer<MIDINotification>(midiNotification)
            let m = ptr.pointee
            print(m)
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            //midi_deinit()
            //midi_init()
            display_device()
            self.connectSourcesToInputPort()
            break
            
            
        // A device, entity or endpoint was added. Structure is MIDIObjectAddRemoveNotification.
        case .msgObjectAdded:
            
            print("added")
            //            let ptr = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(midiNotification)
            
            midiNotification.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) {
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("child \(m.child)")
                print("child type \(m.childType)")
                //showMIDIObjectType(m.childType)
                print("parent \(m.parent)")
                print("parentType \(m.parentType)")
                //showMIDIObjectType(m.parentType)
                //print("childName \(getDeviceName(m.child))")
            }
            
            
            break
            
        // A device, entity or endpoint was removed. Structure is MIDIObjectAddRemoveNotification.
        case .msgObjectRemoved:
            print("kMIDIMsgObjectRemoved")
            //            let ptr = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(midiNotification)
            midiNotification.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) {
                
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("child \(m.child)")
                print("child type \(m.childType)")
                print("parent \(m.parent)")
                print("parentType \(m.parentType)")
                
                //print("childName \(getDeviceName(m.child))")
            }
            
            
            break
            
        // An object's property was changed. Structure is MIDIObjectPropertyChangeNotification.
        case .msgPropertyChanged:
            print("kMIDIMsgPropertyChanged")
            
            
            
            //            let ptr = UnsafeMutablePointer<MIDIObjectPropertyChangeNotification>(midiNotification)
            midiNotification.withMemoryRebound(to: MIDIObjectPropertyChangeNotification.self, capacity: 1) {
                
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("object \(m.object)")
                print("objectType  \(m.objectType)")
                print("propertyName  \(m.propertyName)")
                print("propertyName  \(m.propertyName.takeUnretainedValue())")
                
                if m.propertyName.takeUnretainedValue() as String == "apple.midirtp.session" {
                    print("connected")
                }
            }
            
            break
            
        // 	A persistent MIDI Thru connection wasor destroyed.  No data.
        case .msgThruConnectionsChanged:
            print("MIDI thru connections changed.")
            break
            
        //A persistent MIDI Thru connection was created or destroyed.  No data.
        case .msgSerialPortOwnerChanged:
            print("MIDI serial port owner changed.")
            break
            
        case .msgIOError:
            print("MIDI I/O error.")
            
            //let ptr = UnsafeMutablePointer<MIDIIOErrorNotification>(midiNotification)
            midiNotification.withMemoryRebound(to: MIDIIOErrorNotification.self, capacity: 1) {
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("driverDevice \(m.driverDevice)")
                print("errorCode \(m.errorCode)")
            }
            break
        }
        
    }

}




