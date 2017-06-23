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

class core_midi_event: UIViewController {

    let midi_seq_ = midi_seq()
    var midiClient = MIDIClientRef()
    var midiInputPortref = MIDIPortRef()
    //var midiClient_out: MIDIClientRef = 0
    var inPort = MIDIPortRef()
    var outPort:MIDIPortRef = 0
    var src:MIDIEndpointRef = MIDIGetSource(0)
    var processingGraph:AUGraph?
    var samplerUnit:AudioUnit?
    var virtualSourceEndpointRef = MIDIEndpointRef()
    
    @IBOutlet weak var staus_block: UITextView!
    @IBOutlet weak var show_input_event: UITextView!
    
    @IBAction func play_sound_on(_ sender: UIButton) {
        show_input_event.text.append("on\n")
        play_note_on()
    }
    
    @IBAction func play_sound_off(_ sender: UIButton) {
        show_input_event.text.append("off\n")
        play_note_off()
    }
    

    @IBAction func play_note(_ sender: UIButton) {
        //let num:Int? = Int(out_dev.text!)
        //midi_device.midi_play_note(dev_num: num!)
        //status_block.text.append(midi_seq_.note)
    }
    
    @IBAction func get_device(_ sender: UIButton) {
        staus_block.text = ""
        let destinationNames = getDestinationNames()
        for (index,destName) in destinationNames.enumerated()
        {
            staus_block.text.append("Destination #\(index): \(destName)\n")
        }
    }
    
    override func viewDidLoad() {
        print("load +++++\n")
        super.viewDidLoad()
        midi_init()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
    
    
    
    func midi_play_note(dev_num: Int)
    {
        
        let destNum = dev_num
        
        let dest:MIDIEndpointRef = MIDIGetDestination(destNum)
        
        var packet1:MIDIPacket = MIDIPacket();
        packet1.timeStamp = 0;
        packet1.length = 3;
        packet1.data.0 = 0x90 + 0; // Note On event channel 1
        packet1.data.1 = 0x3C; // Note C3\
        packet1.data.2 = 100; // Velocity
        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet1);
        
        MIDISend(outPort, dest, &packetList)
        
        MIDIPortConnectSource(inPort, src, &src)
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
        
        
        //observeNotifications()
        //enableNetwork()
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
        
        /*
         MIDIClientCreate("MidiTestClient" as CFString, nil, nil, &midiClient_out)
         MIDIOutputPortCreate(midiClient_out, "MidiTest_OutPort" as CFString, &outPort)*/
    }
    public func play_note_on()
    {
        midi_seq_.note_on()
    }
    public func play_note_off()
    {
        midi_seq_.note_off()
    }
    
    
    func show_note_event(event:String)
    {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.show_input_event.text.append("\(event)\n")
                let range = NSMakeRange(self.show_input_event.text.characters.count - 1, 1)
                self.show_input_event.scrollRangeToVisible(range)
            }
        }
    }
 
    func MyMIDIReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
        let packets = packetList.pointee
        
        let packet:MIDIPacket = packets.packet
       
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to:packet)
        var p = ap.pointee
        var result=""
        for _ in 0 ..< packets.numPackets {
            p = ap.pointee
            print("timestamp \(p.timeStamp)", terminator: "")
            var hex = String(format:"0x%X", p.data.0)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.1)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.2)
            print(" \(hex)")
            
            result = handle(p)
            show_note_event(event:result)
            ap = MIDIPacketNext(ap)
        }
        
        
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
            self.play_note_off()
            // forward to sampler
            
        case 0x90:
            result = String("Note on. Channel \(channel) note \(d1) velocity \(d2)")
            self.play_note_on()
            // forward to sampler
            
        case 0xA0:
            result = String("Polyphonic Key Pressure (Aftertouch). Channel \(channel) note \(d1) pressure \(d2)")
            
        case 0xB0:
            result = String("[CC] Channel \(channel) controller \(d1) value \(d2)")
            midi_seq_.change_controller(value:d2)
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
        
        print("\ngot a MIDINotification!")
        
        let notification = midiNotification.pointee
        print("MIDI Notify, messageId= \(notification.messageID)")
        print("MIDI Notify, messageSize= \(notification.messageSize)")
        show_note_event(event:String("MIDI Notify, messageId= \(notification.messageID)"))
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





