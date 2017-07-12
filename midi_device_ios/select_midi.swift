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
func log(_ line:Int, str:String)
{
    print("[\(line)]: \(str)\n")
}


class midi_file
{
    var name:String=""
    var url:String=""
    var is_exist:Bool=false
    var location = URL(string: "https://www.apple.com")
    var cell_index:IndexPath!
    var is_select:Bool=false
    init(name:String, url:String, is_exist:Bool)
    {
        self.name = name
        self.url = url
        self.is_exist = is_exist
    }
}


class select_midi: UIViewController, UITableViewDelegate, UITableViewDataSource, URLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate {
    
    
    var defaultSession: URLSession!
    var downloadTask: URLSessionDownloadTask!
    //var fileList:[(name:String, url:String)] = []
    var file_class:[midi_file] = []
    var localfile = [String]()
    var refresh_cntl = UIRefreshControl()
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var downloadProgress: UIProgressView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let urlLink = URL.init(string: "https://www.dropbox.com/s/w8emodssfeo8wq6/midi_menu.txt?dl=1")
        startDownloading(url: urlLink!)
        list_local_midi_file()
        list_directory()
        //downloadTask = defaultSession.downloadTask(with: urlLink)
        //downloadTask.resume()
        // Do any additional setup after loading the view.
    }
    
    func startDownloading (url:URL) {
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        defaultSession = URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        downloadProgress.setProgress(0.0, animated: false)
        downloadTask = defaultSession.downloadTask(with: url)
        downloadTask.resume()
    }
    
    
    // MARK:- URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        let file_name:String = "/" + (downloadTask.originalRequest?.url?.lastPathComponent)!
        var is_menu:Bool = false
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat(file_name))
        //let destinationURLForFile = URL(fileURLWithPath: NSHomeDirectory().appendingFormat("/file.txt"))
        
        log(#line, str: "count:\(file_name)")
        if(file_name.range(of: "txt") != nil)
        {
            is_menu = true
        }
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            //showFileWithPath(path: destinationURLForFile.path)
            print(destinationURLForFile.path)
            if(is_menu == true)
            {
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
        }
        else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                // show file
                //showFileWithPath(path: destinationURLForFile.path)
            }catch {
                print("An error occurred while moving file to destination url. Error#\((error))\n")
            }
        }
        
        if(is_menu == true)
        {
            parse_menu()
        }
        else
        {
            log(#line, str: "file:\(destinationURLForFile.path)")
            guard let tmp_class:midi_file = (search_file_by_name(name: destinationURLForFile.lastPathComponent))!
            else
            {
                log(#line, str: "search file failed")
                return
            }
            tmp_class.location = destinationURLForFile
            tmp_class.is_exist = true
            tableview.cellForRow(at: tmp_class.cell_index)?.textLabel?.textColor = UIColor.black
        }
    }
    
    func search_file_by_name(name:String) -> midi_file?
    {
        for item in file_class
        {
            if(item.name == name)
            {
                return item
            }
        }
        return nil
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        cell.textLabel?.text = file_class[indexPath.row].name
        is_exist(file: file_class[indexPath.row])
        file_class[indexPath.row].cell_index = indexPath
        if(file_class[indexPath.row].is_exist == false)
        {
            cell.textLabel?.textColor = UIColor.darkGray
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        log(#line, str: "count:\(file_class.count)")
        return file_class.count
    }
    //select row
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        log(#line, str: "row:\(indexPath.row)")
        log(#line, str: "filelst[\(indexPath.row)]:\(file_class[indexPath.row].name)")
        
    }
    //delect row
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete)
        {
            log(#line, str: "delete")
        }
    }
    
    //download
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        if(self.file_class[indexPath.row].is_exist == false)
        {
            let download_action = UITableViewRowAction(style: .default, title: "Download", handler:
            {(action, indexPath) in
            
            let file = self.file_class[indexPath.row].url
            log(#line, str: "\(file)")
            guard let dwLink = URL(string: file.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            else
            {
                log(#line, str: "Could not parse URL")
                return
            }
            self.startDownloading(url: dwLink)
            tableView.isEditing = false
            })
            return [download_action]
        }
        else
        {
            let delete_action = UITableViewRowAction(style: .destructive, title: "Delete", handler:
            {(action, indexPath) in
                let fileManager = FileManager()
                let tempPath = NSHomeDirectory()+"/Documents/" + self.file_class[indexPath.row].name
                do
                {
                    try fileManager.removeItem(atPath: tempPath)
                }
                catch
                {
                    print("Delete File Failed. Error:\(error)\n")
                    self.list_directory()
                }
                self.file_class[indexPath.row].is_exist = false
                tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.darkGray
                tableView.isEditing = false
            })
            
            if(self.file_class[indexPath.row].is_select == false)
            {
                let select_action = UITableViewRowAction(style: .normal, title: "Select", handler:
                {(action, indexPath) in
                    let select_file = self.file_class[indexPath.row].name
                    log(#line, str: "\(select_file)")
                    self.file_class[indexPath.row].is_select = true
                    tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.blue
                    self.unselect_file_for_tableview(row:indexPath.row)
                
                    globalInfo.select_file = self.file_class[indexPath.row].location!
                    tableView.isEditing = false
                })
                return [delete_action, select_action]
            }
            return [delete_action]
        }
    }
    
    func unselect_file_for_tableview(row:Int)
    {
        var i = 0
        for item in file_class
        {
            if(i != row)
            {
                item.is_select = false
                tableview.cellForRow(at: item.cell_index)?.textLabel?.textColor = UIColor.black
            }
            i+=1
        }
    }
    
    func is_exist(file:midi_file)
    {
        let file_name = file.name
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]+"/"
        for item in localfile
        {
            if(file_name == item)
            {
                file.is_exist = true
                file.location = URL(fileURLWithPath: documentDirectoryPath.appendingFormat(file_name))
            }
        }
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
    
    
    func list_local_midi_file()
    {
        let tempPath = NSHomeDirectory()+"/Documents"
        localfile = []
        do{
            let fileList = try FileManager.default.contentsOfDirectory(atPath: tempPath)
            for file in fileList
            {
                if(file.range(of: "mid") != nil)
                {
                    self.localfile.append(file)
                    print(file)
                }
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
            var midifile:midi_file = midi_file.init(name: file[0], url: file[1], is_exist: false)
            print("[ \(#line) ]:\(midifile.url)\n")
            file_class.append(midifile)
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
