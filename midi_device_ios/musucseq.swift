//
//  musucseq.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/6/12.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import CoreMIDI

public class note
{
    var note_msg:MIDINoteMessage = MIDINoteMessage()
    public var previous:note?
    public var next:note?
    public var index = 0
    public var tick = 0
    public var bar_beat = CABarBeatTime(bar: 1, beat: 1, subbeat: 0, subbeatDivisor: 0, reserved: 0)
    init(note_msg: MIDINoteMessage, tick:Double, beat:CABarBeatTime)
    {
        self.note_msg.channel = note_msg.channel
        self.note_msg.duration = note_msg.duration
        self.note_msg.note = note_msg.note
        self.note_msg.releaseVelocity = note_msg.releaseVelocity
        self.note_msg.velocity = note_msg.velocity
        self.tick = Int(tick)
        self.bar_beat = beat
    }
}

public class note_list
{
    fileprivate var head: note?
    private var tail: note?
    var sampler:AVAudioUnitSampler!
    public var num = 0
    
    public var isEmpty: Bool {
        return head == nil
    }
    
    public var first: note? {
        return head
    }
    
    public var last: note? {
        return tail
    }
    
    public func append(note_msg: MIDINoteMessage, tick:Double, beat:CABarBeatTime) {
        // 1
        
        let new_note = note(note_msg: note_msg, tick:tick, beat:beat)
        num += 1
        new_note.index = num
        // 2
        if let tailNode = tail {
            new_note.previous = tailNode
            tailNode.next = new_note
        }
            // 3
        else {
            head = new_note
        }
        // 4
        tail = new_note
    }
    
    public func print() -> String
    {
        var text = "\n["
        var node = head
        
        while node != nil {
            text += "\(node!.note_msg)"
            node = node!.next
            if node != nil { text += "\n " }
        }
        
        return text + "]"
    }
    
    public func player() -> String
    {
        let engine = AVAudioEngine()
        
        self.sampler = AVAudioUnitSampler()
        
        engine.attach(self.sampler!)
        engine.connect(self.sampler, to: engine.outputNode, format: nil)
        
        guard let soundbank = Bundle.main.url(forResource: "gs_instruments", withExtension: "dls") else {
            return "Could not initalize soundbank."
        }
        
        let melodicBank:UInt8 = UInt8(kAUSampler_DefaultMelodicBankMSB)
        
        let gmHarpsichord:UInt8 = 6
        do {
            try engine.start()
            try self.sampler!.loadSoundBankInstrument(at: soundbank, program: gmHarpsichord, bankMSB: melodicBank, bankLSB: 0)
            
        }catch {
            return "An error occurred"
        }
        
        self.sampler!.startNote(60, withVelocity: 64, onChannel: 0)
        
        return "OK"
    }
    
}

public class midi_seq
{
    var musicSequence:MusicSequence?
    //let midiFileURL = Bundle.main.url(forResource: "A_Morning_in_the_Slag_Ravine_Trumpet_Solo", withExtension: "mid")
    var midiFileURL = Bundle.main.url(forResource: "Morning_in_the_Slag_Ravine_版本1", withExtension: "mid")
    var midi_song:note_list?
    var note:String = "empty"
    var engine: AVAudioEngine!
    
    var sampler: AVAudioUnitSampler!
    var current_note:note!
    var previous_note:note!
    
    func loadSF2PresetIntoSampler(_ preset:UInt8)  {
        
        guard let bankURL = Bundle.main.url(forResource: "FluidR3 GM2-2", withExtension: "SF2") else {
            print("could not load sound font")
            return
        }
        
        do {
            try self.sampler.loadSoundBankInstrument(at: bankURL,
                                                     program: preset,
                                                     bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                     bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        } catch {
            print("error loading sound bank instrument")
        }
        
    }
    
    func startEngine() {
        
        if engine.isRunning {
            print("audio engine already started")
            return
        }
        
        do {
            try engine.start()
            print("audio engine started")
        } catch {
            print("oops \(error)")
            print("could not start audio engine")
        }
    }
    
    func send_event_dev(dev_num:Int, outPort:MIDIPortRef)
    {
        let dest:MIDIEndpointRef = MIDIGetDestination(dev_num)
    
        var packet:MIDIPacket = MIDIPacket()
        packet.timeStamp = 0
        packet.data.0 = current_note.note_msg.note
        packet.data.1 = current_note.note_msg.velocity
        packet.data.2 = current_note.note_msg.releaseVelocity
        
        var packetlist:MIDIPacketList = MIDIPacketList(numPackets:1, packet:packet)
        MIDISend(outPort, dest, &packetlist)
        print("send event to device\(current_note.note_msg)")
        //MIDIPortConnectSource(<#T##port: MIDIPortRef##MIDIPortRef#>, <#T##source: MIDIEndpointRef##MIDIEndpointRef#>, <#T##connRefCon: UnsafeMutableRawPointer?##UnsafeMutableRawPointer?#>)
    }
    
    public func get_note()
    {
        if(current_note.next != nil)
        {
            current_note = current_note.next
        }
        else
        {
            current_note = midi_song?.head
        }
        globalInfo.note = current_note
    }
    
    public func reset()
    {
        if(current_note != nil && midi_song?.head != nil)
        {
            current_note = midi_song?.head
        }
    }
    
    public func note_on(channel:UInt8)
    {
        sampler.startNote(current_note.note_msg.note, withVelocity: current_note.note_msg.velocity, onChannel: channel)
    }
    
    public func change_controller(value:UInt8, channel:UInt8)
    {
        sampler.sendController(7, withValue: value, onChannel: channel)

    }
    
    //for local sythesizer
    public func note_off(channel:UInt8, note:UInt8)
    {
        sampler.stopNote(note, onChannel: channel)
    }
    
    public func note_off(channel:UInt8)
    {
        let note_:note? = current_note
        sampler.stopNote((note_?.note_msg.note)!, onChannel: channel)
        /*
        if(current_note.next != nil)
        {
            current_note = current_note.next
        }
        else
        {
            current_note = midi_song.head
        }
 */
    }
    
    func load_music()
    {
        midi_song = note_list()
        var status = NewMusicSequence(&musicSequence)
        if status != OSStatus(noErr) {
            print("bad status \(status) creating sequence")
        }
        
        var track:MusicTrack? = nil
        status = MusicSequenceNewTrack(musicSequence!, &track)
        if status != OSStatus(noErr) {
            print("bad status \(status) creating track")
        }
        
        let typeId:MusicSequenceFileTypeID = MusicSequenceFileTypeID.midiType
        let flags = MusicSequenceLoadFlags.smf_ChannelsToTracks
        //let localUrl  = file.path as! CFString
        
        MusicSequenceFileLoad(musicSequence!, midiFileURL as! CFURL, typeId, flags)
        var tempo_track:MusicTrack?
        MusicSequenceGetIndTrack(musicSequence!, 1,&tempo_track)
        var event:MusicEventIterator?
        NewMusicEventIterator(tempo_track!,  &event)
        var property_len:UInt32 = 0
        var time_resolution:UInt32 = 0
        var lengthFromMusicTimeStamp = MusicTimeStamp(1.75)
        var tempo_track1:MusicTrack?
        MusicSequenceGetTempoTrack(musicSequence!, &tempo_track1)
        MusicTrackGetProperty(tempo_track1!, kSequenceTrackProperty_TimeResolution, &lengthFromMusicTimeStamp, &property_len)
        MusicTrackGetProperty(tempo_track1!, kSequenceTrackProperty_TimeResolution, &time_resolution, &property_len)
    
        log(str:"lengthFromMusicTimeStamp:\(lengthFromMusicTimeStamp)")
        log(str:"property_len:\(property_len)")
        log(str:"time_resolution:\(time_resolution)")
        var hasNext:DarwinBoolean = true
        var timestamp:MusicTimeStamp = 0
        var eventType:MusicEventType = 0
        var eventData:UnsafeRawPointer?
        var eventDataSize:UInt32 = 0
        
        // Run the loop
        MusicEventIteratorHasCurrentEvent(event!, &hasNext);
        while (hasNext).boolValue {
            MusicEventIteratorGetEventInfo(event!,
                                           &timestamp,
                                           &eventType,
                                           &eventData,
                                           &eventDataSize);
            
            // Process each event he
            switch(eventType)
            {
            case kMusicEventType_Meta:
                print("Meta")
            case kMusicEventType_User:
                print("User")
            case kMusicEventType_MIDINoteMessage:
                let data = UnsafePointer<MIDINoteMessage>(eventData?.assumingMemoryBound(to: MIDINoteMessage.self))
                
                let channel = data?.pointee.channel
                let note = data?.pointee.note
                let velocity = data?.pointee.velocity
                let dur = data?.pointee.duration
                let newNote = MIDINoteMessage(channel: channel!,note: note!,velocity: velocity!,releaseVelocity: 0,duration: dur!)
                //print(newNote)
                let tick:Double = Double(timestamp) * Double(time_resolution)
                var beat_time:CABarBeatTime = CABarBeatTime(bar: 1, beat: 1, subbeat: 0, subbeatDivisor: 0, reserved: 0)
                MusicSequenceBeatsToBarBeatTime(musicSequence!, timestamp, UInt32(time_resolution), &beat_time)
            
                log(str:"note:\(newNote.note) duration:\(newNote.duration) timestamp:\(timestamp) tick:\(tick) barBeatTime:\(beat_time.bar) Beat:\(beat_time.beat)")
                
                midi_song?.append(note_msg: newNote, tick:tick, beat:beat_time)
            case kMusicEventType_MIDIChannelMessage:
                print("")
            default:
                print("unknown")
            }
            
            MusicEventIteratorNextEvent(event!);
            MusicEventIteratorHasCurrentEvent(event!, &hasNext);
            
        }
        
        previous_note = midi_song?.head
        current_note = midi_song?.head
    }
 
    init()
    {
        log(str:"global:\(globalInfo.select_file.path)  local:\(midiFileURL?.path)\n")
        engine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        loadSF2PresetIntoSampler(globalInfo.instrusment_.id)
        startEngine()
        
        //
        //let midi_song = note_list()
        
        
        
        load_music()
        /*
        let typeId:MusicSequenceFileTypeID = MusicSequenceFileTypeID.midiType
        let flags = MusicSequenceLoadFlags.smf_ChannelsToTracks
        
        MusicSequenceFileLoad(musicSequence!, midiFileURL as! CFURL, typeId, flags)
        
        var tempo_track:MusicTrack?
        MusicSequenceGetIndTrack(musicSequence!, 1,&tempo_track)
        
        var event:MusicEventIterator?
        NewMusicEventIterator(tempo_track!,  &event)
        
        var hasNext:DarwinBoolean = true
        var timestamp:MusicTimeStamp = 0
        var eventType:MusicEventType = 0
        var eventData:UnsafeRawPointer?
        var eventDataSize:UInt32 = 0
        
        // Run the loop
        MusicEventIteratorHasCurrentEvent(event!, &hasNext);
        while (hasNext).boolValue {
            MusicEventIteratorGetEventInfo(event!,
                                           &timestamp,
                                           &eventType,
                                           &eventData,
                                           &eventDataSize);
            
            // Process each event he
            
            switch(eventType)
            {
            case kMusicEventType_Meta:
                print("Meta")
            case kMusicEventType_User:
                print("User")
            case kMusicEventType_MIDINoteMessage:
                let data = UnsafePointer<MIDINoteMessage>(eventData?.assumingMemoryBound(to: MIDINoteMessage.self))
                
                let channel = data?.pointee.channel
                let note = data?.pointee.note
                let velocity = data?.pointee.velocity
                let dur = data?.pointee.duration
                let newNote = MIDINoteMessage(channel: channel!,note: note!,velocity: velocity!,releaseVelocity: 0,duration: dur!)
                //print(newNote)
                midi_song.append(note_msg: newNote)
            case kMusicEventType_MIDIChannelMessage:
                print("")
            default:
                print("unknown")
            }
            
            MusicEventIteratorNextEvent(event!);
            MusicEventIteratorHasCurrentEvent(event!, &hasNext);
    
        }
        note = midi_song.print()
        previous_note = midi_song.head
        current_note = midi_song.head
        */
    }
}
