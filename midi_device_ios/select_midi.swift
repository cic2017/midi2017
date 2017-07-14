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
    log(str:"File download succesfully")
}

func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    downloadProgress.setProgress(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite), animated: true)
}

func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    downloadTask = nil
    downloadProgress.setProgress(0.0, animated: true)
    if (error != nil) {
        log(str:"didCompleteWithError \(error?.localizedDescription)")
    }
    else {
        log(str:"The task finished successfully")
    }
}
*/
func log(line: Int = #line,funtcion:String = #function, str:String)
{
    print("[\(funtcion)][\(line)]: \(str)\n")
}


class midi_file
{
    var name:String=""
    var url:String=""
    var is_exist:Bool=false
    var location = URL(string: "https://www.apple.com")
    var cell_index:IndexPath!
    var is_select:Bool=false
    init(name:String, url:String)
    {
        self.name = name
        self.url = url
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
        var file_name:String=""
        var is_menu:Bool = false
        var tmp_file_class:midi_file?
        //let destinationURLForFile = URL(fileURLWithPath: NSHomeDirectory().appendingFormat("/file.txt"))
        
        log(str:"count:\(file_name)")
        if((downloadTask.originalRequest?.url?.lastPathComponent)!.range(of: "txt") != nil)
        {
            is_menu = true
            file_name = "/" + (downloadTask.originalRequest?.url?.lastPathComponent)!
        }
        else if((downloadTask.originalRequest?.url?.lastPathComponent)!.range(of: "mid") != nil)
        {
            tmp_file_class = get_file_call_by_url(url: (downloadTask.originalRequest?.url?.path)!)
            if(tmp_file_class != nil)
            {
                file_name = "/" + (tmp_file_class?.name)! + ".mid"
            }
            else
            {
                log(str:"Cannot get file class")
            }
            
        }
        log(str:"count:\(file_name)")
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat(file_name))
        
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            //showFileWithPath(path: destinationURLForFile.path)
            log(str:destinationURLForFile.path)
            if(is_menu == true)
            {
                do
                {
                    try fileManager.removeItem(atPath: destinationURLForFile.path)
                }
                catch
                {
                         log(str:"Oooops")
                }
                do {
                    try fileManager.moveItem(at: location, to: destinationURLForFile)
                    // show file
                    //showFileWithPath(path: destinationURLForFile.path)
                }catch{
                    log(str: "An error occurred while moving file to destination url")
                }
            }
        }
        else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                // show file
                //showFileWithPath(path: destinationURLForFile.path)
            }catch {
                log(str:"An error occurred while moving file to destination url. Error#\((error))\n")
            }
        }
        
        if(is_menu == true)
        {
            parse_menu()
        }
        else
        {
            log(str: "file:\(destinationURLForFile.path)")
            tmp_file_class?.location = destinationURLForFile
            tmp_file_class?.is_exist = true
            tableview.cellForRow(at: (tmp_file_class?.cell_index)!)?.textLabel?.textColor = UIColor.black
        }
    }
    
    func get_file_call_by_url(url:String) -> midi_file?
    {
        for item in file_class
        {
            log(str: "url:\(item.url), ori_url:\(url)")
            if(item.url.range(of: url) != nil)
            {
                return item
            }
        }
        return nil
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
            log(str:"didCompleteWithError \(error?.localizedDescription ?? "no value")")
        }
        else {
            log(str:"The task finished successfully")
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
        else
        {
            cell.textLabel?.textColor = UIColor.black
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        log(str: "count:\(file_class.count)")
        return file_class.count
    }
    //select row
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        log(str: "row:\(indexPath.row)")
        log(str: "filelst[\(indexPath.row)]:\(file_class[indexPath.row].name)")
        
    }
    //delect row
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete)
        {
            log(str:"delete")
        }
    }
    
    //download
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        if(self.file_class[indexPath.row].is_exist == false)
        {
            let download_action = UITableViewRowAction(style: .default, title: "Download", handler:
            {(action, indexPath) in
            
            let file = self.file_class[indexPath.row].url
            log(str: "\(file)")
            guard let dwLink = URL(string: file.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            else
            {
                log(str: "Could not parse URL")
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
                let tempPath = NSHomeDirectory()+"/Documents/" + self.file_class[indexPath.row].name + ".mid"
                do
                {
                    try fileManager.removeItem(atPath: tempPath)
                }
                catch
                {
                    log(str:"Delete File Failed. Error:\(error)\n")
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
                    log(str: "\(select_file)")
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
            log(str: "file_name:\(file_name), item:\(item)")
            if(item.range(of: file_name) != nil)
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
                log(str:file)
            }
        }
        catch{
            log(str:"Cannot list directory")
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
                    log(str:"file:\(file)")
                }
            }
        }
        catch{
            log(str:"Cannot list directory")
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
            log(str:"No save file in path:\(filePath)\n")
        }
    }

    func parse_file_into_array(str:Array<String>)
    {
        for item in str
        {
            let file = item.components(separatedBy: "::")
            var midifile:midi_file = midi_file.init(name: file[0], url: file[1])
            if(file[0].range(of: ".mid") == nil)
            {
                midifile.name = midifile.name + ".mid"
            }
            log(str:"[ \(#line) ]:\(midifile.name)\n")
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
