//
//  select_midi.swift
//  midi_device_ios
//
//  Created by Yu-An on 2017/7/7.
//  Copyright © 2017年 Yu-An. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    var urlLink: URL!
    var defaultSession: URLSession!
    var downloadTask: URLSessionDownloadTask!
}
/*
// MARK: Button Pressed
@IBAction func btnDownloadPressed(_ sender: UIButton) {
    let urlLink1 = URL.init(string: "https://github.com/VivekVithlani/QRCodeReader/archive/master.zip")
    startDownloading(url: urlLink!)
}
@IBAction func btnResumePressed(_ sender: UIButton) {
    downloadTask.resume()
}

@IBAction func btnStopPressed(_ sender: UIButton) {
    downloadTask.cancel()
}

@IBAction func btnPausePressed(_ sender: UIButton) {
    downloadTask.suspend()
}

func startDownloading (url:URL) {
    let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
    defaultSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
    downloadProgress.setProgress(0.0, animated: false)
    downloadTask = defaultSession.downloadTask(with: urlLink)
    downloadTask.resume()
}

// MARK:- URLSessionDownloadDelegate
func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    print("File download succesfully")
}

func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    downloadProgress.setProgress(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite), animated: true)
}

func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    downloadTask = nil
    downloadProgress.setProgress(0.0, animated: true)
    if (error != nil) {
        print("didCompleteWithError \(error?.localizedDescription)")
    }
    else {
        print("The task finished successfully")
    }
}
*/

class select_midi: UIViewController, UITableViewDelegate, UITableViewDataSource, URLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate {
    
    var urlLink: URL!
    var defaultSession: URLSession!
    var downloadTask: URLSessionDownloadTask!
    var fileList:[(name:String, url:String)] = []
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var downloadProgress: UIProgressView!
    override func viewDidLoad() {
        super.viewDidLoad()
        urlLink = URL.init(string: "https://www.dropbox.com/s/w8emodssfeo8wq6/midi_menu.txt?dl=1")
        startDownloading(url: urlLink!)
        //downloadTask = defaultSession.downloadTask(with: urlLink)
        //downloadTask.resume()
        // Do any additional setup after loading the view.
    }
    
    func startDownloading (url:URL) {
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        defaultSession = URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        downloadProgress.setProgress(0.0, animated: false)
        downloadTask = defaultSession.downloadTask(with: urlLink)
        downloadTask.resume()
    }
    
    
    // MARK:- URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/midi_menu.txt"))
        //let destinationURLForFile = URL(fileURLWithPath: NSHomeDirectory().appendingFormat("/file.txt"))

        if fileManager.fileExists(atPath: destinationURLForFile.path){
            //showFileWithPath(path: destinationURLForFile.path)
            //print(destinationURLForFile.path)
            do
            {
                try fileManager.removeItem(atPath: destinationURLForFile.path)
            }
            catch
            {
                print("Oooops\n")
            }
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                // show file
                //showFileWithPath(path: destinationURLForFile.path)
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
        else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                // show file
                //showFileWithPath(path: destinationURLForFile.path)
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
        parse_menu()
    }
    
    func showFileWithPath(path: String){
        let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
        if isFileFound == true{
            let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
            viewer.delegate = self
            viewer.presentPreview(animated: true)
        }
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        downloadProgress.setProgress(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite), animated: true)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        downloadTask = nil
        downloadProgress.setProgress(0.0, animated: true)
        if (error != nil) {
            print("didCompleteWithError \(error?.localizedDescription ?? "no value")")
        }
        else {
            print("The task finished successfully")
        }
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
    {
        return self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        cell.textLabel?.text = fileList[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("count:\(fileList.count)\n")
        return fileList.count
    }
    //select row
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("row:\(indexPath.row)\n")
        print("filelst[\(indexPath.row)]:\(fileList[indexPath.row].name)\n")
        
    }
    //delect row
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete)
        {
            print("delect\n")
        }
    }
    
    //download
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let download_action = UITableViewRowAction(style: .normal, title: "Download", handler:
        {(action, indexPath) in
            let dwLink = URL.init(string: self.fileList[indexPath.row].url)
            //self.startDownloading(url: dwLink!)
        })
        
        return [download_action]
    }
    
    func list_directory()
    {
        let tempPath = NSHomeDirectory()+"/Documents"
        do{
            let fileList = try FileManager.default.contentsOfDirectory(atPath: tempPath)
            for file in fileList{
                print(file)
            }
        }
        catch{
            print("Cannot list directory")
        }
    }
    
    func parse_menu()
    {
        let filePath = NSHomeDirectory()+"/Documents/midi_menu.txt"
        do{
            let loading = try NSString(contentsOfFile: filePath, encoding: String.Encoding.ascii.rawValue)
            print(loading)
            let str = loading.components(separatedBy: "\n")
            parse_file_into_array(str: str)
        }catch{
            print("No save file in path:\(filePath)\n")
        }
    }

    func parse_file_into_array(str:Array<String>)
    {
        for item in str
        {
           let file = item.components(separatedBy: "::")
            fileList.append(name:file[0], url:file[1])
        }
        tableview.reloadData()
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
