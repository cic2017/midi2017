//
//  core_midi.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/6/8.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import Foundation
import CoreMIDI
import os.log
import AVFoundation
import UIKit
/*
func MyMIDIReadProc(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
    print("got input event")
    let packets = packetList.pointee
    
    let packet:MIDIPacket = packets.packet
    
    var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
    ap.initialize(to:packet)
    
    for _ in 0 ..< packets.numPackets {
        let p = ap.pointee
        print("timestamp \(p.timeStamp)", terminator: "")
        var hex = String(format:"0x%X", p.data.0)
        print(" \(hex)", terminator: "")
        hex = String(format:"0x%X", p.data.1)
        print(" \(hex)", terminator: "")
        hex = String(format:"0x%X", p.data.2)
        print(" \(hex)")
    
        
        ap = MIDIPacketNext(ap)
    }
}
*/

class core_midi:UIViewController
{
    
    
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
    @IBOutlet weak var input_note_event: UITextField!
    
    
    func midiNetworkChanged(notification:NSNotification) {
        print("\(#function)")
        print("\(notification)")
        if let session = notification.object as? MIDINetworkSession {
            print("session \(session)")
            for con in session.connections() {
                print("con \(con)")
            }
            print("isEnabled \(session.isEnabled)")
            print("sourceEndpoint \(session.sourceEndpoint())")
            print("destinationEndpoint \(session.destinationEndpoint())")
            print("networkName \(session.networkName)")
            print("localName \(session.localName)")
            
            if let name = getDeviceName(session.sourceEndpoint()) {
                print("source name \(name)")
            }
            
            if let name = getDeviceName(session.destinationEndpoint()) {
                print("destination name \(name)")
            }
        }
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
    
    func midiNetworkContactsChanged(notification:NSNotification) {
        print("\(#function)")
        print("\(notification)")
        if let session = notification.object as? MIDINetworkSession {
            print("session \(session)")
            for con in session.contacts() {
                print("contact \(con)")
            }
        }
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(midiNetworkChanged(notification:)),
                                               name:NSNotification.Name(rawValue: MIDINetworkNotificationSessionDidChange),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(midiNetworkContactsChanged(notification:)),
                                               name:NSNotification.Name(rawValue: MIDINetworkNotificationContactsDidChange),
                                               object: nil)
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

    internal func augraphSetup() {
        
        var status = NewAUGraph(&self.processingGraph)
        //checkError(status)
        if let graph = self.processingGraph {
            
            // create the sampler
            
            //https://developer.apple.com/library/prerelease/ios/documentation/AudioUnit/Reference/AudioComponentServicesReference/index.html#//apple_ref/swift/struct/AudioComponentDescription
            
            var samplerNode = AUNode()
            var cd = AudioComponentDescription(
                componentType:         OSType(kAudioUnitType_MusicDevice),
                componentSubType:      OSType(kAudioUnitSubType_Sampler),
                componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                componentFlags:        0,
                componentFlagsMask:    0)
            status = AUGraphAddNode(graph, &cd, &samplerNode)
            //checkError(status)
            
            // create the ionode
            var ioNode = AUNode()
            var ioUnitDescription = AudioComponentDescription(
                componentType:         OSType(kAudioUnitType_Output),
                componentSubType:      OSType(kAudioUnitSubType_RemoteIO),
                componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                componentFlags:        0,
                componentFlagsMask:    0)
            status = AUGraphAddNode(graph, &ioUnitDescription, &ioNode)
            //checkError(status)
            
            // now do the wiring. The graph needs to be open before you call AUGraphNodeInfo
            status = AUGraphOpen(graph)
            //checkError(status)
            
            status = AUGraphNodeInfo(graph, samplerNode, nil, &self.samplerUnit)
            //checkError(status)
            
            var ioUnit: AudioUnit? = nil
            status = AUGraphNodeInfo(graph, ioNode, nil, &ioUnit)
            //checkError(status)
            
            let ioUnitOutputElement = AudioUnitElement(0)
            let samplerOutputElement = AudioUnitElement(0)
            status = AUGraphConnectNodeInput(graph,
                                             samplerNode, samplerOutputElement, // srcnode, inSourceOutputNumber
                ioNode, ioUnitOutputElement) // destnode, inDestInputNumber
            //checkError(status)
        } else {
            print("core audio augraph is nil")
        }
    }
    
    
    internal func graphStart() {
        //https://developer.apple.com/library/prerelease/ios/documentation/AudioToolbox/Reference/AUGraphServicesReference/index.html#//apple_ref/c/func/AUGraphIsInitialized
        
        if let graph = self.processingGraph {
            var outIsInitialized:DarwinBoolean = false
            var status = AUGraphIsInitialized(graph, &outIsInitialized)
            print("isinit status is \(status)")
            print("bool is \(outIsInitialized)")
            
            if outIsInitialized == false {
                status = AUGraphInitialize(graph)
                //checkError(status)
            }
            
            var isRunning = DarwinBoolean(false)
            status = AUGraphIsRunning(graph, &isRunning)
            //checkError(status)
            print("running bool is \(isRunning)")
            if isRunning == false {
                status = AUGraphStart(graph)
                //checkError(status)
            }
        } else {
            print("core audio augraph is nil")
        }
    }
    
    func enableNetwork() {
        MIDINetworkSession.default().isEnabled = true
        MIDINetworkSession.default().connectionPolicy = .anyone
        
        print("net session enabled \(MIDINetworkSession.default().isEnabled)")
        print("net session networkPort \(MIDINetworkSession.default().networkPort)")
        print("net session networkName \(MIDINetworkSession.default().networkName)")
        print("net session localName \(MIDINetworkSession.default().localName)")
        
    }
    
    func initGraph() {
        augraphSetup()
        graphStart()
        // after the graph starts
        //loadSF2Preset(0)
        //CAShow(UnsafeMutablePointer<MusicSequence>(self.processingGraph!))
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
        
        input_note_event.text?.append("test")
        observeNotifications()
        enableNetwork()
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
        midi_seq_.note_on(channel:UInt8(channel_num.text!)!)
    }
    public func play_note_off()
    {
        midi_seq_.note_off(channel:UInt8(channel_num.text!)!)
    }
    

    
    func MyMIDIReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
      
        let packets = packetList.pointee
        
        let packet:MIDIPacket = packets.packet
        
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to:packet)
        
        for _ in 0 ..< packets.numPackets {
            let p = ap.pointee
            print("timestamp \(p.timeStamp)", terminator: "")
            var hex = String(format:"0x%X", p.data.0)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.1)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.2)
            print(" \(hex)")
            
            if(p.data.0 & 0xF0 == 0x80)
            {
                play_note_off()
            }
            
            if(p.data.0 & 0xF0 == 0x90)
            {
                play_note_on()
            }
            
            ap = MIDIPacketNext(ap)
        }
    }
    
    
    public func MyMIDINotifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
        print("\ngot a MIDINotification!")
        
        let notification = midiNotification.pointee
        print("MIDI Notify, messageId= \(notification.messageID)")
        print("MIDI Notify, messageSize= \(notification.messageSize)")
        
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
    
    

    
    func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
                        readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void
    {
        let packetList:MIDIPacketList = pktList.pointee
        //let srcRef:MIDIEndpointRef = srcConnRefCon!.load(as: MIDIEndpointRef.self)
        
        print("got input event\n")
        var packet:MIDIPacket = packetList.packet
        for _ in 1...packetList.numPackets
        {
            let bytes = Mirror(reflecting: packet.data).children
            var dumpStr = ""
            
            // bytes mirror contains all the zero values in the ridiulous packet data tuple
            // so use the packet length to iterate.
            var i = packet.length
            for (_, attr) in bytes.enumerated()
            {
                dumpStr += String(format:"$%02X ", attr.value as! UInt8)
                i -= 1
                if (i <= 0)
                {
                    break
                }
            }
            
            print(dumpStr)
            packet = MIDIPacketNext(&packet).pointee
        }
    }

}


