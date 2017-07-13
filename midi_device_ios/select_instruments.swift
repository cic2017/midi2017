//
//  select_instruments.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/7/13.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import UIKit

let soundfontPresets: [String: UInt8] = [
    "Acoustic Grand Piano" : 0,
    "Bright Acoustic Piano" : 1,
    "Electric Grand Piano" : 2,
    "Honky-tonk Piano" : 3,
    "Electric Piano 1" : 4,
    "Electric Piano 2" : 5,
    "Harpsichord" : 6,
    "Clavi" : 7,
    "Celesta" : 8,
    "Glockenspiel" : 9,
    "Music Box" : 10,
    "Vibraphone" : 11,
    "Marimba" : 12,
    "Xylophone" : 13,
    "Tubular Bells" : 14,
    "Dulcimer" : 15,
    "Drawbar Organ" : 16,
    "Percussive Organ" : 17,
    "Rock Organ" : 18,
    "ChurchPipe" : 19,
    "Positive" : 20,
    "Accordion" : 21,
    "Harmonica" : 22,
    "Tango Accordion" : 23,
    "Classic Guitar" : 24,
    "Acoustic Guitar" : 25,
    "Jazz Guitar" : 26,
    "Clean Guitar" : 27,
    "Muted Guitar" : 28,
    "Overdriven Guitar" : 29,
    "Distortion Guitar" : 30,
    "Guitar harmonics" : 31,
    "JazzBass" : 32,
    "DeepBass" : 33,
    "PickBass" : 34,
    "FretLess" : 35,
    "SlapBass1" : 36,
    "SlapBass2" : 37,
    "SynthBass1" : 38,
    "SynthBass2" : 39,
    "Violin" : 40,
    "Viola" : 41,
    "Cello" : 42,
    "ContraBass" : 43,
    "TremoloStr" : 44,
    "Pizzicato" : 45,
    "Harp" : 46,
    "Timpani" : 47,
    "String Ensemble 1" : 48,
    "String Ensemble 2" : 49,
    "SynthStrings 1" : 50,
    "SynthStrings 2" : 51,
    "Choir" : 52,
    "DooVoice" : 53,
    "Voices" : 54,
    "OrchHit" : 55,
    "Trumpet" : 56,
    "Trombone" : 57,
    "Tuba" : 58,
    "MutedTrumpet" : 59,
    "FrenchHorn" : 60,
    "Brass" : 61,
    "SynBrass1" : 62,
    "SynBrass2" : 63,
    "SopranoSax" : 64,
    "AltoSax" : 65,
    "TenorSax" : 66,
    "BariSax" : 67,
    "Oboe" : 68,
    "EnglishHorn" : 69,
    "Bassoon" : 70,
    "Clarinet" : 71,
    "Piccolo" : 72,
    "Flute" : 73,
    "Recorder" : 74,
    "PanFlute" : 75,
    "Bottle" : 76,
    "Shakuhachi" : 77,
    "Whistle" : 78,
    "Ocarina" : 79,
    "SquareWave" : 80,
    "SawWave" : 81,
    "Calliope" : 82,
    "SynChiff" : 83,
    "Charang" : 84,
    "AirChorus" : 85,
    "fifths" : 86,
    "BassLead" : 87,
    "New Age" : 88,
    "WarmPad" : 89,
    "PolyPad" : 90,
    "GhostPad" : 91,
    "BowedGlas" : 92,
    "MetalPad" : 93,
    "HaloPad" : 94,
    "Sweep" : 95,
    "IceRain" : 96,
    "SoundTrack" : 97,
    "Crystal" : 98,
    "Atmosphere" : 99,
    "Brightness" : 100,
    "Goblin" : 101,
    "EchoDrop" : 102,
    "SciFi effect" : 103,
    "Sitar" : 104,
    "Banjo" : 105,
    "Shamisen" : 106,
    "Koto" : 107,
    "Kalimba" : 108,
    "Scotland" : 109,
    "Fiddle" : 110,
    "Shanai" : 111,
    "MetalBell" : 112,
    "Agogo" : 113,
    "SteelDrums" : 114,
    "Woodblock" : 115,
    "Taiko" : 116,
    "Tom" : 117,
    "SynthTom" : 118,
    "RevCymbal" : 119,
    "FretNoise" : 120,
    "NoiseChiff" : 121,
    "Seashore" : 122,
    "Birds" : 123,
    "Telephone" : 124,
    "Helicopter" : 125,
    "Stadium" : 126,
    "GunShot" : 127
]

struct instrusment
{
    var name:String!
    var id:UInt8!
}

var instrusment_array = [instrusment]()

class select_instruments: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        for (key, value) in soundfontPresets
        {
            instrusment_array.append(instrusment(name:key, id:value))
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return instrusment_array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        
        cell.textLabel?.text = instrusment_array[indexPath.row].name
        return cell
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
