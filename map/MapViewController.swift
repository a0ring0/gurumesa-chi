//
//  MapViewController.swift
//  map
//  検索条件入力画面
//  Created by user on 2022/04/23.
//

import UIKit
import MapKit       //地図
import CoreLocation //位置情報

class MapViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!          //地図
    @IBOutlet weak var decisionButton: UIButton!    //検索範囲決定ボタン
    
    var locationManager = CLLocationManager()       //位置情報
    
    var latitude: Double = 0.0   //Double型緯度プロパティ
    var longitude: Double = 0.0  //Double型経度プロパティ
    var s_latitude: String?      //Optional String型緯度プロパティ
    var s_longitude: String?     //Optional String型経度プロパティ
    
    var c_center = CLLocationCoordinate2DMake(35.681236,139.767125) //円の中心座標
    var c_radius = CLLocationDistance(1000)                         //円の半径の初期値
    
    var c_radius_0 = CLLocationDistance(300)                         //円の半径 300m
    var c_radius_1 = CLLocationDistance(500)                         //円の半径 500m
    var c_radius_2 = CLLocationDistance(1000)                        //円の半径 1km
    var c_radius_3 = CLLocationDistance(2000)                        //円の半径 2km
    var c_radius_4 = CLLocationDistance(3000)                        //円の半径 3km
    var mkCircle = MKCircle(center: CLLocationCoordinate2DMake(35.681236,139.767125), radius: CLLocationDistance(1000)) //円
    
    var isFirst: Bool = false       //地図の中心位置更新フラグ
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "半径を設定してください"        //ナビゲーションコントローラのタイトル設定
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "戻る", style: .plain, target: nil, action: nil)    //戻るボタンのテキスト設定
        
        //地図の設定
        let center = CLLocationCoordinate2DMake(35.681236,139.767125)           //最初の中心座標
        let span = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)  //表示範囲
        let region = MKCoordinateRegion(center: center, span: span)             //中心座標と表示範囲をマップに登録する
        mapView.setRegion(region, animated: true)                               //regionに設定したマップ表示設定を反映
       
        //現在地を取得
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        //円を描画する
        c_radius = c_radius_2                       //初期設定は半径1km
        UserDefaults.standard.set(2, forKey: "rad") //UserDefaultsに半径を保存
        mkCircle = MKCircle(center: c_center, radius: c_radius) //円の中心座標と半径を設定
        mapView.addOverlay(mkCircle)    //地図にcircleを追加
    }
    
    //現在地を取得する許可を求めるためのメソッド
    func permission(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            
        case .notDetermined:                            //許可されてない場合
            manager.requestWhenInUseAuthorization()     //許可を求める
            
        case .restricted, .denied:                      //拒否されてる場合
            break                                       //何もしない
            
        case .authorizedAlways, .authorizedWhenInUse:   //許可されている場合
            manager.startUpdatingLocation()             //現在地の取得を開始
            break
            
        default:
            break
        }
    }

    //半径選択
    @IBAction func rangeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
                case 0:
                    c_radius = c_radius_0   //300m
                    UserDefaults.standard.set(1, forKey: "rad") //UserDefaultsに半径を保存
                case 1:
                    c_radius = c_radius_1   //500m
                    UserDefaults.standard.set(2, forKey: "rad")
                case 2:
                    c_radius = c_radius_2   //1km
                    UserDefaults.standard.set(3, forKey: "rad")
                case 3:
                    c_radius = c_radius_3   //2km
                    UserDefaults.standard.set(4, forKey: "rad")
                case 4:
                    c_radius = c_radius_4   //3km
                    UserDefaults.standard.set(5, forKey: "rad")
                default:
                    print("存在しない番号")
                }
        mapView.removeOverlay(mkCircle)                         //現在の円を消す
        mkCircle = MKCircle(center: c_center, radius: c_radius) //中心座標と半径の更新
        mapView.addOverlay(mkCircle)                            //円の描画
    }
    
    //現在地
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        s_latitude = (locations.last?.coordinate.latitude.description)  //緯度取得
        s_longitude = (locations.last?.coordinate.longitude.description)//経度取得
        
        if let s_latitude = s_latitude {  //s_latitudeのアンラップ
            latitude = NSString(string: s_latitude).doubleValue //String型の緯度をDouble型に変換
            UserDefaults.standard.set(latitude, forKey: "lat")  //UserDefaultsに緯度を保存
        }
        
        if let s_longitude = s_longitude {  //s_longitudeのアンラップ
            longitude = NSString(string: s_longitude).doubleValue   //String型の経度をDouble型に変換
            UserDefaults.standard.set(longitude, forKey: "lon")     //UserDefaultsに経度を保存
        }
        if !isFirst {   //最初だけ呼ぶ
            mapView.setCenter((locations.last?.coordinate)!, animated: true)    //マップ中心位置の更新
            isFirst = true
        }
        mapView.removeOverlay(mkCircle)                             //現在の円を消す
        c_center = CLLocationCoordinate2DMake(latitude,longitude)   //中心座標更新
        mkCircle = MKCircle(center: c_center, radius: c_radius)     //中心座標と半径を更新
        mapView.addOverlay(mkCircle)                                //円の描画
    }
    
    //円
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

           let myCircleView: MKCircleRenderer = MKCircleRenderer(overlay: overlay)  //rendererを生成
           myCircleView.fillColor = UIColor.red                                     //円の内部を赤色で塗りつぶす
           myCircleView.strokeColor = UIColor.black                                 //円周の線の色を黒色に設定
           myCircleView.alpha = 0.3                                                 //円を透過させる
           myCircleView.lineWidth = 1.0                                             //円周の線の太さ

           return myCircleView
       }

}
