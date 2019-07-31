//
//  ViewController.swift
//  LogDisplay
//
//  Created by wangwei on 2019/7/26.
//  Copyright © 2019 XJK. All rights reserved.
//

import Cocoa
let errInfo:String = "~~~日志内容解析失败~~~"
let defaulContent:String = "~~~日志显示区域~~~"
class ViewController: NSViewController {
    var fileData:NSData = NSData()
    var content:NSString = ""
    var currentContent:String = ""
    let manager:EncryptAndDecryptMananger = EncryptAndDecryptMananger()
    var searchResults:NSMutableArray = NSMutableArray()
    var searchLineResults:NSMutableArray = NSMutableArray()
    var textColor:NSColor = NSColor()
    var currentIndex = 0
    var flag:Bool = false  //搜索区分大小写
    @IBOutlet weak var searchedNumLabel: NSTextField!
    @IBOutlet var showFiled: NSTextView!
    @IBOutlet var showFiled2: NSTextView!
    @IBOutlet weak var scrollView2: NSScrollView!
    @IBOutlet weak var dragDropView: DragDropView!
    @IBOutlet weak var searchTextField: NSTextField!
    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var loadingView: NSProgressIndicator!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showFiled.string = defaulContent
        self.dragDropView.dragDropFileURLs = {[weak self] urls in
            self?.openAndPraseFile(urls.first?.path ?? "")
        }
        self.progressView.minValue = 0.0
        self.progressView.maxValue = 1.0
        self.progressView.doubleValue = 0.0
        self.loadingView.isDisplayedWhenStopped = false;
        self.textColor = self.showFiled.textColor!
        self.searchedNumLabel.stringValue = ""
        self.scrollView2.isHidden = true;
    }
    private final func openAndPraseFile(_ path:String){
        self.searchedNumLabel.stringValue = ""
        do {
            self.fileData = self.manager.decryptorLog(path) as NSData
            let content:String = String.init(data: self.fileData as Data, encoding: String.Encoding.utf8) ?? "error"
            if content.elementsEqual("error") {
                self.fileData = try NSData.init(contentsOf: NSURL.init(fileURLWithPath: path) as URL)
            }
            if (self.fileData.length == 0){
                self.content =  errInfo as NSString
            } else {
                self.content = String.init(data: self.fileData as Data, encoding: String.Encoding.utf8) as NSString? ?? errInfo as NSString
            }
            self.showFiled.string = self.content as String;
        } catch {
            print("文件代开失败")
        }
    }
    @IBAction func clearAction(_ sender: Any) {
        self.showFiled.string = defaulContent
        self.showFiled2.string = ""
        self.searchedNumLabel.stringValue = ""
        self.searchTextField.stringValue = ""
    }
    @IBAction func startToSearch(_ sender: NSButton) {
        self.searchResults.removeAllObjects()
        self.searchLineResults.removeAllObjects()
        self.currentIndex = 0
        self.searchedNumLabel.stringValue = ""
        self.showFiled.textColor = self.textColor
        self.loadingView.startAnimation(nil)
        var searchStr:String = self.searchTextField.stringValue
        var searchContent:NSString = self.content.copy() as! NSString
        if (!self.flag){
            searchContent = searchContent.lowercased as NSString
            searchStr = searchStr.lowercased()
        }
        DispatchQueue.global(qos: .default).async {
            var location:NSInteger = 0
            let separateArray:NSArray = searchContent.components(separatedBy: searchStr) as NSArray
            separateArray.enumerateObjects({ (object, index, stop) in
                if (index != separateArray.count - 1){
                    location += (object as! NSString).length
                    let currentRange:NSRange = NSMakeRange(location, (searchStr as NSString).length )
                    location += (searchStr as NSString).length
                    self.searchResults.add(currentRange)
                }
            })
            DispatchQueue.main.async {
                for range in self.searchResults{
                    self.showFiled.setTextColor(NSColor.orange, range: range as! NSRange)
                }
                if self.searchResults.count > 0{
                    self.showFiled.setTextColor(NSColor.green, range: self.searchResults[self.currentIndex] as! NSRange)
                }
                self.searchedNumLabel.stringValue = String(format: "共搜索到:%d条", self.searchResults.count)
            }
        }
        DispatchQueue.global(qos: .default).async {
            var length:NSInteger = 0
            let separateArray:NSArray = searchContent.components(separatedBy: "\r\n") as NSArray
            separateArray.enumerateObjects { (object, index, stop) in
                let stringValue:NSString = String(format: "%@", object as! CVarArg) as NSString
                if stringValue.contains(searchStr){
                    //搜索字符串所在行的range
                    let lineRange:NSRange = NSMakeRange(length, stringValue.length+2)
                    self.searchLineResults.add(lineRange)
                }
                length += stringValue.length+2
                DispatchQueue.main.async {
                    var progress:Double = Double(index) / Double(separateArray.count)
                    if (progress > 0.99){
                        progress = 0.0
                        self.loadingView.stopAnimation(nil)
                    }
                    self.progressView.doubleValue = progress
                }
            }
             DispatchQueue.main.async {
                if self.searchLineResults.count > 0{
                   self.showFiled.setSelectedRange(self.searchLineResults[self.currentIndex] as! NSRange, affinity: NSSelectionAffinity.upstream, stillSelecting: true)
                }
            }
        }
    }
    @IBAction func openFileAction(_ sender: Any) {
        let panel:NSOpenPanel = NSOpenPanel.init()
        panel.allowsMultipleSelection = false;
        panel.canChooseDirectories = false;
        panel.allowedFileTypes = ["txt","txt1","txt2","text3"]
        
        panel.begin { [weak self](result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let path:String = panel.urls.first?.path ?? ""
                self?.openAndPraseFile(path)
            }
        }
    }
    
    @IBAction func caseSensitiveAction(_ sender: NSButton) {
        self.flag = sender.state.rawValue == 1 ? true : false
    }
    
    @IBAction func onlyShowSearchResultAction(_ sender: NSButton) {
        if sender.state.rawValue == 1 {
            self.scrollView2.isHidden = false;
            var currentContent:String = ""
            self.searchLineResults.enumerateObjects { (range, index, stop) in
                let currentLineRange = range as! NSRange
                currentContent.append(self.content.substring(with: currentLineRange))
            }
            self.showFiled2.string = currentContent;
        } else {
            self.scrollView2.isHidden = true;
        }
    }
    
    @IBAction func previousAction(_ sender: NSButton) {
        if (self.searchResults.count > 0){
            self.currentIndex -= 1
            if (self.currentIndex < 0){
                self.currentIndex = 0
            }
            self.showFiled.scrollRangeToVisible(self.searchResults[self.currentIndex] as! NSRange)
            self.showFiled.setTextColor(NSColor.green, range: self.searchResults[self.currentIndex] as! NSRange)
            if (self.currentIndex + 1 < self.searchResults.count - 1){
                self.showFiled.setTextColor(NSColor.orange, range: self.searchResults[self.currentIndex + 1] as! NSRange)
            } else {
                self.showFiled.setTextColor(NSColor.orange, range: self.searchResults[self.searchResults.count - 1] as! NSRange)
            }
            self.searchLineResults.enumerateObjects { (range, index, stop) in
                let currentLineRange = range as! NSRange
                if (currentLineRange.intersection(self.searchResults[self.currentIndex] as! NSRange) != nil){
                    self.showFiled.setSelectedRange(self.searchLineResults[index] as! NSRange, affinity: NSSelectionAffinity.upstream, stillSelecting: true)
                }
            }
            self.searchedNumLabel.stringValue = String(format: "共搜索到:%d条 当前第:%d条", self.searchResults.count,self.currentIndex+1)
        }
    }
    
    @IBAction func nextAction(_ sender: NSButton) {
        if (self.searchResults.count > 0){
            self.currentIndex += 1
            if (self.currentIndex > self.searchResults.count - 1){
                self.currentIndex = self.searchResults.count - 1 > 0 ? self.searchResults.count - 1 : 0
            }
            self.showFiled.scrollRangeToVisible(self.searchResults[self.currentIndex] as! NSRange)
            self.showFiled.setTextColor(NSColor.green, range: self.searchResults[self.currentIndex] as! NSRange)
            if (self.currentIndex - 1 > 0){
                self.showFiled.setTextColor(NSColor.orange, range: self.searchResults[self.currentIndex - 1] as! NSRange)
            } else {
                self.showFiled.setTextColor(NSColor.orange, range: self.searchResults[0] as! NSRange)
            }
            self.searchLineResults.enumerateObjects { (range, index, stop) in
                let currentLineRange = range as! NSRange
                if (currentLineRange.intersection(self.searchResults[self.currentIndex] as! NSRange) != nil){
                    self.showFiled.setSelectedRange(self.searchLineResults[index] as! NSRange, affinity: NSSelectionAffinity.upstream, stillSelecting: true)
                }
            }
            self.searchedNumLabel.stringValue = String(format: "共搜索到:%d条 当前第:%d条", self.searchResults.count,self.currentIndex+1)
        }
    }
    
    override var representedObject: Any? {
        didSet {
            
        }
    }
    
    
}

