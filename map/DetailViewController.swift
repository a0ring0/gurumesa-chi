//
//  DetailViewController.swift
//  map
//  店舗詳細画面
//  Created by user on 2022/05/04.
//

import UIKit

class DetailViewController: UIViewController {
    
    var id: String = ""     //店舗ID
    
    @IBOutlet weak var imageScrollView: UIScrollView! {     //画像のスクロールビューの設定
        didSet {
            imageScrollView.delegate = self
            imageScrollView.isPagingEnabled = true          //ページング
            imageScrollView.showsHorizontalScrollIndicator = false      //スライドバーを非表示
        }
    }
    
    @IBOutlet weak var imagePageControl: UIPageControl! {   //ページコントロールの設定
        didSet {
            imagePageControl.isUserInteractionEnabled = false       //タップ無効化
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!      //お店の名前のラベル
    @IBOutlet weak var addressLabel: UILabel!   //お店の住所のラベル
    @IBOutlet weak var stationLabel: UILabel!   //お店の最寄駅のラベル
    @IBOutlet weak var openLabel: UILabel!      //お店の営業時間のラベル
    @IBOutlet weak var genreLabel: UILabel!     //お店のジャンルのラベル
    @IBOutlet weak var closeLabel: UILabel!     //お店の定休日のラベル
    @IBOutlet weak var capacityLabel: UILabel!  //お店の総席数のラベル
    @IBOutlet weak var averageLabel: UILabel!   //お店の平均予算のラベル
    
    var capacityInt: Int = 0                    //総席数の変数
    
    private let scrollHeight: CGFloat = 200.0
    private let imageWidth: CGFloat = UIScreen.main.bounds.width        //画像の横幅
    
    var logoImage: URL = UserDefaults.standard.url(forKey: "logo_image")!       //ロゴ画像のURL
    var topImage: URL = UserDefaults.standard.url(forKey: "top_image")!         //トップ写真のURL
    
    private lazy var images: [UIImage] = {  //画像のURL(String型)を設定
        var s_logoImage: String = logoImage.absoluteString      //URLをString型に変換
        var s_topImage: String = topImage.absoluteString
        return [UIImage(url: s_logoImage),
                UIImage(url: s_topImage)]
       }()
    
    var storeDetail : [(name:String , address:String , open:String , station_name:String , genreName:String , close:String , capacity:Int , average:String)] = []  //お店の詳細(タプル配列)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupImages()   //画像を設定
        
        if let o_id = UserDefaults.standard.string(forKey: "id") {  //idのアンラップ
            id = o_id
        }
        detail(id: id)
        
        //UILabelの設定
        nameLabel.textColor = UIColor.darkGray                  //名称ラベルの色
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)      //名称ラベルのフォント
        nameLabel.numberOfLines = 0                             //名称ラベルの改行設定
        addressLabel.numberOfLines = 0
        stationLabel.numberOfLines = 0
        openLabel.numberOfLines = 0
        genreLabel.numberOfLines = 0
        closeLabel.numberOfLines = 0
        capacityLabel.numberOfLines = 0
        averageLabel.numberOfLines = 0
    }
    
    //---------------JSONデータ構造---------------
    //JSONのbudget内のデータ構造
    struct BudgetJson: Codable {
        let average: String?        //平均予算
    }
    //JSONのgenre内のデータ構造
    struct GenreJson: Codable {
        let name: String?           //ジャンル名
    }
    //JSONのshop内のデータ構造
    struct ShopJson: Codable {
        let name: String?           //お店の名称
        let address: String?        //住所
        let open: String?           //営業時間
        let station_name: String?   //最寄駅
        let genre: GenreJson?       //ジャンル
        let close: String?          //定休日
        let capacity: Int?          //総席数
        let budget: BudgetJson?     //予算
    }
    //JSONのresults内のデータ構造
    struct ResultsJson: Codable {
        let shop: [ShopJson]?   //複数要素
    }
    //JSONのデータ構造
    struct resultJson: Codable {
        let results: ResultsJson?
    }
    
    //detailメソッド
    func detail(id: String) {
        //リクエストURLの組み立て
        guard let req_url = URL(string: "http://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=d77478a006fd6eb6&id=\(id)&format=json") else {
            return
        }
        
        let req = URLRequest(url: req_url)  //リクエストに必要な情報を生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)    //データ転送を管理するためのセッションを生成
        let task = session.dataTask(with: req, completionHandler: { //リクエストをタスクとして登録
            (data , response , error) in
            session.finishTasksAndInvalidate()  //セッションを終了
            do {    //do try catchエラーハンドリング
                let decoder = JSONDecoder() //JSONDecoderのインスタンスを取得
                let json = try decoder.decode(resultJson.self, from: data!) //受け取ったJSONデータを解析して格納
                
                if let shops = json.results?.shop { //お店の情報を取得できているかの確認
                    self.storeDetail.removeAll()  //既にあるリストを削除
                    for shop in shops {
                        if let name = shop.name, let address = shop.address, let open = shop.open, let station_name = shop.station_name, let genre = shop.genre?.name, let close = shop.close, let capacity = shop.capacity, let average = shop.budget?.average { //お店の名称、住所、営業時間をアンラップ
                            let store = (name,address,open,station_name,genre,close,capacity,average)    //お店をタプルでまとめて管理
                            self.storeDetail.append(store)                          //お店の配列へ追加
                            self.nameLabel.text = shop.name                         //名称ラベルに名前を設定
                            self.addressLabel.text = shop.address                   //住所ラベルに住所を設定
                            self.stationLabel.text = shop.station_name              //最寄駅ラベルに最寄駅を設定
                            self.openLabel.text = shop.open                         //営業時間ラベルに営業時間を設定
                            self.genreLabel.text = shop.genre?.name                 //ジャンルラベルにジャンルを設定
                            self.closeLabel.text = shop.close                       //定休日ラベルに定休日を設定
                            self.capacityInt = shop.capacity!                       //総席数の変数に総席数を設定
                            self.capacityLabel.text = "\(self.capacityInt)席"       //総席数ラベルに設定
                            self.averageLabel.text = shop.budget?.average           //平均予算ラベルに平均予算を設定
                        }
                    }
                }
            } catch {
                print("エラー")    //エラー処理
            }
        })
        task.resume()   //ダウンロード開始
    }

    private func setupImages() {        //画像セットメソッド
        imageScrollView.contentSize = CGSize(width: imageWidth * CGFloat(images.count),height: scrollHeight)        //スクロール内部のサイズ指定
            images.enumerated().forEach { index, image in               //スクロール内部に画像を配置
                let imageView = UIImageView(frame: CGRect(x: imageWidth * CGFloat(index),
                                                          y: 0,
                                                          width: imageWidth,
                                                          height: scrollHeight))
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageScrollView.addSubview(imageView)
            }
        imagePageControl.numberOfPages = images.count       //ScrollViewとPageControllの連動
        }

}

// MARK: UIScrollViewDelegate
extension DetailViewController: UIScrollViewDelegate {      //表示している画像
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        imagePageControl.currentPage = Int(scrollView.contentOffset.x / scrollView.frame.width)
    }
}

extension UIImage {     //URLでUIImageを指定
    public convenience init(url: String) {
        let url = URL(string: url)
        do {
            let data = try Data(contentsOf: url!)
            self.init(data: data)!
            return
        } catch let err {
            print("Error : \(err.localizedDescription)")
        }
        self.init()
    }
}

