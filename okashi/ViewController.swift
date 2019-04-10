//
//  ViewController.swift
//  okashi
//
//  Created by yuka on 2019/04/07.
//  Copyright © 2019 Swift-Beginners. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        searchText.delegate = self
        searchText.placeholder = "お菓子の名前を入力してください"
        
        tableView.dataSource = self
        tableView.delegate = self
    }

    @IBOutlet weak var searchText: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    var okashiList : [(name:String, maker:String, link:URL, image:URL)] = []
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        
        if let searchWord = searchBar.text{
            //DEBUG
            print(searchWord)
            //入力された文字列で検索
            searchOkashi(keyword: searchWord)
        }
    }
    
    func searchOkashi(keyword : String){
        
        guard let keyWordEncode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        guard let reqUrl = URL(string: "http://www.sysbird.jp/toriko/api/?apikey=guest&format=json&keyword=\(keyWordEncode)&max=10&order=r") else{
            return
        }
        
        print(reqUrl)
        
        let req = URLRequest(url: reqUrl)
        
        let session = URLSession(configuration: .default,
                                 delegate: nil,
                                 delegateQueue: OperationQueue.main)
        
        let task = session.dataTask(with: req, completionHandler: {
            (data, response, error) in
            
            session.finishTasksAndInvalidate()
            
            do {
                let decoder = JSONDecoder();
                let json = try decoder.decode(ResultJson.self, from: data!)
                //print(json);
                
                if let items = json.item{
                    
                    //初期化
                    self.okashiList.removeAll()
                    
                    for item in items{
                        if let name = item.name, let maker = item.maker, let link = item.url, let image = item.image{
                            let okashi = (name, maker, link, image)
                            self.okashiList.append(okashi)
                        }
                    }
                    
                    //TableViewを更新する
                    self.tableView.reloadData()
                    
                    if let okashidbg = self.okashiList.first {
                        print("----------")
                        print("okashiList[0] = \(okashidbg)")
                    }
                }
            } catch {
                print("occured error")
            }
        })
        
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return okashiList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "okashiCell", for: indexPath)
        
        cell.textLabel?.text = okashiList[indexPath.row].name
        if let imageData = try? Data(contentsOf: okashiList[indexPath.row].image){
            cell.imageView?.image = UIImage(data: imageData)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //ハイライト解除
        tableView.deselectRow(at: indexPath, animated: true)
        //SFSafariViewを開く
        let safariViewController = SFSafariViewController(url: okashiList[indexPath.row].link)
        //delegateの通知先を自分自身
        safariViewController.delegate = self
        //SafariViewが開かれる
        present(safariViewController, animated: true, completion: nil)
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController){
        //Safariを閉じる
        dismiss(animated: true, completion: nil)
    }
    
    struct ItemJson : Codable{
        let name : String?
        let maker : String?
        let url : URL?
        let image : URL?
    }
    
    struct ResultJson: Codable{
        let item:[ItemJson]?
    }
}

class IOError: Error {
    
}
