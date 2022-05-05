//
//  ResultViewController.swift
//  map
//  検索結果一覧画面
//  Created by user on 2022/04/23.
//

import UIKit

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //スクリーンの横幅、縦幅を定義
    let screenWidth = Int(UIScreen.main.bounds.size.width)
    let screenHeight = Int(UIScreen.main.bounds.size.height)
    
    //テーブルビューインスタンス作成
    var storeTableView: UITableView = UITableView()
    
    var r_lat = 0.0 //緯度
    var r_lon = 0.0 //経度
    var r_rad = 0   //半径
    var storeList : [(id:String , name:String , mobile_access:String , logo_image:URL , top_image:URL)] = [] //お店のリスト(タプル配列)
    var shopCount: Int = 0  //検索結果のお店の数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "戻る", style: .plain, target: nil, action: nil)    //戻るボタンのテキスト設定
        
        r_lat = UserDefaults.standard.double(forKey: "lat") //UserDefaultsの緯度を代入
        print("緯度:\(r_lat)")
        r_lon = UserDefaults.standard.double(forKey: "lon") //UserDefaultsの経度を代入
        print("経度:\(r_lon)")
        r_rad = UserDefaults.standard.integer(forKey: "rad")  //UserDefaultsの半径を代入
        print("半径:\(r_rad)")
        
        search(lat: r_lat, lon: r_lon, rad: r_rad)  //searchメソッド呼び出し
        
        storeTableView.frame = CGRect(x:screenWidth*0/100, y:screenHeight*10/100, width: screenWidth*100/100, height: screenHeight*90/100)  //テーブルビューの設置場所を指定
        storeTableView.delegate = self      //sampleTableViewのdelegateを問い合わせ先をselfに
        storeTableView.dataSource = self    //sampleTableViewのdataSourceを問い合わせ先をselfに
        storeTableView.register(UITableViewCell.self, forCellReuseIdentifier: "storeCell")  //cellに名前をつける
        self.view.addSubview(storeTableView)    //実際にviewにsampleTableViewを表示させる
        self.storeTableView.rowHeight = 80      //cellの高さを指定
        storeTableView.separatorColor = UIColor.darkGray    //セパレータの色を指定
        
    }
    
    //JSONのmobile内のデータ構造
    struct MobileJson: Codable {
        let l: URL?
    }
    //JSONのphoto内のデータ構造
    struct PhotoJson: Codable {
        let mobile: MobileJson?
    }
    //JSONのshop内のデータ構造
    struct ShopJson: Codable {
        let id: String?             //店舗のID
        let name: String?           //店舗の名称
        let mobile_access: String?  //交通アクセス
        let logo_image: URL?     //ロゴ画像
        let photo: PhotoJson?
    }
    //JSONのresults内のデータ構造
    struct ResultsJson: Codable {
        let shop: [ShopJson]?   //複数要素
    }
    //JSONのデータ構造
    struct resultJson: Codable {
        let results:ResultsJson?
    }
    
    //searchメソッド 第一引数:緯度,第二引数:経度,第三引数:範囲
    func search(lat: Double, lon: Double, rad: Int) {
        //リクエストURLの組み立て
        guard let req_url = URL(string: "http://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=d77478a006fd6eb6&lat=\(lat)&lng=\(lon)&range=\(rad)&order=4&count=100&format=json") else {
            return
        }
        //print(req_url)
        
        let req = URLRequest(url: req_url)  //リクエストに必要な情報を生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)    //データ転送を管理するためのセッションを生成
        let task = session.dataTask(with: req, completionHandler: { //リクエストをタスクとして登録
            (data , response , error) in
            session.finishTasksAndInvalidate()  //セッションを終了
            do {    //do try catchエラーハンドリング
                let decoder = JSONDecoder() //JSONDecoderのインスタンスを取得
                let json = try decoder.decode(resultJson.self, from: data!) //受け取ったJSONデータを解析して格納
                //print("json:\(json)")
                
                if let shops = json.results?.shop { //お店の情報を取得できているかの確認
                    self.storeList.removeAll()  //リストを削除
                    
                    for shop in shops { //取得しているお店の数だけ処理
                        if let id = shop.id, let name = shop.name, let mobile_access = shop.mobile_access, let logo_image = shop.logo_image, let top_image = shop.photo?.mobile?.l { //お店の名称、アクセス、ロゴ画像をアンラップ
                            let store = (id,name,mobile_access,logo_image,top_image) //1つのお店をタプルでまとめて管理
                            self.storeList.append(store)                //お店の配列へ追加
                            self.shopCount += 1
                        }
                    }
                    self.navigationItem.title = "検索結果:\(self.shopCount)件"
                    print("shopCount:\(self.shopCount)")
                    self.storeTableView.reloadData()
                    if let storedbg = self.storeList.first {
                        //print("------------")
                        //print("storeList[0] = \(storedbg)")
                    }
                }
            } catch {
                print("エラー")    //エラー処理
            }
        })
        task.resume()   //ダウンロード開始
    }
    
    //セクション数を指定
    func numberOfSections(in storeTableView: UITableView) -> Int {
        return 1
    }
    //表示するcellの数を指定
    func tableView(_ storeTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storeList.count
    }
    //cellのコンテンツ
    func tableView(_ storeTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = storeTableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath)  //今回表示を行うcellを取得する
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "storeCell")                      //セルのスタイル
        cell.textLabel?.text = storeList[indexPath.row].name                                        //お店のタイトル設定
        cell.textLabel?.numberOfLines = 0   //長文が「...」で省略されないように設定
        cell.detailTextLabel?.text = storeList[indexPath.row].mobile_access                         //お店のサブタイトル(アクセス)設定
        cell.detailTextLabel?.numberOfLines = 0   //長文が「...」で省略されないように設定
        if let imageData = try? Data(contentsOf: storeList[indexPath.row].logo_image) {             //ロゴ画像を取得
            cell.imageView?.image =  UIImage(data: imageData)
        }
        return cell
    }
    
    //cellが選択されたときの処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(indexPath.row)番セルが押されたよ!")
        UserDefaults.standard.set(storeList[indexPath.row].id, forKey: "id")
        UserDefaults.standard.set(storeList[indexPath.row].logo_image, forKey: "logo_image")
        UserDefaults.standard.set(storeList[indexPath.row].top_image, forKey: "top_image")
        performSegue(withIdentifier: "toDetailViewController", sender: nil)
        
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toDetailViewController") {
            let detailVC: DetailViewController = (segue.destination as? DetailViewController)!
        }
    }
    
}
