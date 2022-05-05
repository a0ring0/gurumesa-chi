//
//  DetailViewController.swift
//  map
//
//  Created by user on 2022/05/04.
//

import UIKit

class DetailViewController: UIViewController {
    
    var id: String = ""
    
    @IBOutlet weak var imageScrollView: UIScrollView! {
        didSet {
            imageScrollView.delegate = self
            imageScrollView.isPagingEnabled = true
            imageScrollView.showsHorizontalScrollIndicator = false
        }
    }
    @IBOutlet weak var imagePageControl: UIPageControl! {
        didSet {
            imagePageControl.isUserInteractionEnabled = false
        }
    }
    @IBOutlet weak var nameLabel: UILabel!      //お店の名前のラベル
    @IBOutlet weak var addressLabel: UILabel!   //お店の住所のラベル
    @IBOutlet weak var openLabel: UILabel!      //お店の営業時間のラベル
    
    private let scrollHeight: CGFloat = 200.0
    private let imageWidth: CGFloat = UIScreen.main.bounds.width
    
    var logoImage: URL = UserDefaults.standard.url(forKey: "logo_image")!
    var topImage: URL = UserDefaults.standard.url(forKey: "top_image")!
    
    private lazy var images: [UIImage] = {
        var s_logoImage: String = logoImage.absoluteString
        var s_topImage: String = topImage.absoluteString
        return [UIImage(url: s_logoImage),
                UIImage(url: s_topImage)]
       }()
    
    var storeDetail : [(name:String , address:String , open:String)] = []  //お店の詳細(タプル配列)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupImages()
        
        //idのアンラップ
        if let o_id = UserDefaults.standard.string(forKey: "id") {
            id = o_id
            print("detail_id:\(id)")
        }
        detail(id: id)
        
        //UILabelの設定
        nameLabel.textColor = UIColor.darkGray
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.numberOfLines = 0
        addressLabel.numberOfLines = 0
        openLabel.numberOfLines = 0
    }
    
    //JSONのshop内のデータ構造
    struct ShopJson: Codable {
        let name: String?
        let address: String?
        let open: String?
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
        print("detailメソッドリURL:\(req_url)")
        
        let req = URLRequest(url: req_url)  //リクエストに必要な情報を生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)    //データ転送を管理するためのセッションを生成
        let task = session.dataTask(with: req, completionHandler: { //リクエストをタスクとして登録
            (data , response , error) in
            session.finishTasksAndInvalidate()  //セッションを終了
            do {    //do try catchエラーハンドリング
                let decoder = JSONDecoder() //JSONDecoderのインスタンスを取得
                let json = try decoder.decode(resultJson.self, from: data!) //受け取ったJSONデータを解析して格納
                print("detailメソッドjson:\(json)")
                
                if let shops = json.results?.shop { //お店の情報を取得できているかの確認
                    self.storeDetail.removeAll()
                    for shop in shops {
                        if let name = shop.name, let address = shop.address, let open = shop.open { //お店の名称、住所、営業時間をアンラップ
                            let store = (name,address,open)    //お店をタプルでまとめて管理
                            self.storeDetail.append(store)                          //お店の配列へ追加
                            self.nameLabel.text = shop.name
                            self.addressLabel.text = shop.address
                            self.openLabel.text = shop.open
                        }
                    }
                }
            } catch {
                print("エラー")    //エラー処理
            }
        })
        task.resume()   //ダウンロード開始
    }

    private func setupImages() {
        imageScrollView.contentSize = CGSize(width: imageWidth * CGFloat(images.count),
                                                  height: scrollHeight)
            images.enumerated().forEach { index, image in
                let imageView = UIImageView(frame: CGRect(x: imageWidth * CGFloat(index),
                                                          y: 0,
                                                          width: imageWidth,
                                                          height: scrollHeight))
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageScrollView.addSubview(imageView)
            }
        imagePageControl.numberOfPages = images.count
        }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: UIScrollViewDelegate
extension DetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        imagePageControl.currentPage = Int(scrollView.contentOffset.x / scrollView.frame.width)
    }
}

extension UIImage {
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
