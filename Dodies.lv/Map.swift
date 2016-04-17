//
//  Map.swift
//  Dodies.lv
//
//  Created by Kristaps Grinbergs on 13/09/15.
//  Copyright © 2015 fassko. All rights reserved.
//

import Foundation
import UIKit

import Mapbox
import CoreLocation
import SwiftyJSON
import Alamofire
import RealmSwift
import SwiftyUserDefaults
import Async
import SDCAlertView
import Fabric
import Crashlytics
import FontAwesome_swift

class Map: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {

  var mapView: MGLMapView!
  let manager = CLLocationManager()
  var selectedPoint : DodiesAnnotation!
  
  var realm = try! Realm()
  
  let LastChangedTimestampKey = "LastChangedTimestamp"
  
  @IBOutlet weak var aboutButton: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Karte"
    
    navigationItem.titleView = UIImageView(image: UIImage(named: "dodies_nav_logo"))
    
    let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(20)] as Dictionary!
    aboutButton.setTitleTextAttributes(attributes, forState: .Normal)
    aboutButton.title = String.fontAwesomeIconWithName(.Question)
    
    // ask user to allow location access
    if CLLocationManager.authorizationStatus() == .NotDetermined {
      manager.requestWhenInUseAuthorization()
    }
    
    // initialize the map view
    let styleURL = NSURL(string: "mapbox://styles/normis/cilzp6g1h00grbjlwwsh52vig")
    mapView = MGLMapView(frame: view.bounds, styleURL: styleURL)
    mapView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    
    mapView.setVisibleCoordinateBounds(MGLCoordinateBounds(sw: CLLocationCoordinate2D(latitude: 55.500, longitude: 20.500), ne: CLLocationCoordinate2D(latitude: 58.500, longitude: 28.500)), animated: false)

    mapView.delegate = self
    mapView.showsUserLocation = true
    mapView.rotateEnabled = false
    
    mapView.attributionButton.hidden = true
    
    view.addSubview(mapView)
    
    // print Realm database path
//    print(Realm.Configuration.defaultConfiguration.path!)
    
    // show loading view
    Helper.showGlobalProgressHUD()
    
    // check if need to update data
    if (realm.objects(DodiesPoint).count == 0) {
      downloadData()
    } else {
      Async.background {
        self.loadPoints(checkForUpdatedData: true)
      }
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    let tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "Map")
    
    let builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
    
    Answers.logContentViewWithName("Map", contentType: "Map", contentId: nil, customAttributes: nil)
  }
  
  
  // MARK: - Mapbox implementation
  
  func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
  
    do {
  
      selectedPoint = annotation as! DodiesAnnotation

      var annotation = selectedPoint.tips
      
      if selectedPoint.statuss == "parbaudits" {
        annotation = "\(annotation)-active"
      } else {
        annotation = "\(annotation)-disabled"
      }
      
      var annotationImage = mapView.dequeueReusableAnnotationImageWithIdentifier(annotation)
          
      if annotationImage == nil {
        let image = UIImage(named: annotation)
        annotationImage = MGLAnnotationImage(image: image!, reuseIdentifier: annotation)
      }
      
      return annotationImage
    } catch {
      return nil
    }
  }
  
  func mapView(mapView: MGLMapView, rightCalloutAccessoryViewForAnnotation annotation: MGLAnnotation) -> UIView? {
    return UIButton.init(type: UIButtonType.InfoLight)
  }
  
  func mapView(mapView: MGLMapView, annotation: MGLAnnotation, calloutAccessoryControlTapped control: UIControl) {
    if let point = annotation as? DodiesAnnotation {
      selectedPoint = point
      
      if point.apraksts == "true" {
        performSegueWithIdentifier("detailsWithPicture", sender: self)
      } else {
        performSegueWithIdentifier("details", sender: self)
      }
      
      mapView.deselectAnnotation(annotation, animated: true)
    }
  }
  
  func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
    if annotation.isKindOfClass(DodiesAnnotation) {
      return true
    }
    
    return false
  }
  
  
  // MARK: - Additonal methods
  
  // download data from server
  func downloadData() {
    Alamofire.request(.GET, "http://dodies.lv/apraksti/dati.geojson").responseJSON(completionHandler: {
      response in
      
        Helper.dismissGlobalHUD()
      
        if response.result.isFailure {
          self.showError()
        }
      
        if response.result.isSuccess {
        
          if let value = response.result.value {
            let json = JSON(value)
            
            if let features = json["features"].array {
          
              try! self.realm.write {
                self.realm.deleteAll()
              }
              
              for feature in features {
                
                let coordinates:Array<Double> = feature["geometry"].dictionaryValue["coordinates"]?.arrayObject as! Array<Double>
                let properties = feature["properties"].dictionaryValue
                
                
                let dodiesPoint = DodiesPoint()
                dodiesPoint.latitude = coordinates[0]
                dodiesPoint.longitude = coordinates[1]
                
                dodiesPoint.apraksts = properties["apraksts"]!.stringValue
                dodiesPoint.datums = properties["datums"]!.stringValue
                dodiesPoint.desc = properties["desc"]!.stringValue
                dodiesPoint.garums = properties["garums"]!.stringValue
                dodiesPoint.id = properties["id"]!.stringValue
                dodiesPoint.name = properties["name"]!.stringValue
                dodiesPoint.statuss = properties["statuss"]!.stringValue
                dodiesPoint.tips = properties["tips"]!.stringValue

                // write in realm database
                try! self.realm.write {
                  self.realm.add(dodiesPoint)
                }
              }
              
              self.updateLastChangedTimestamp()
              self.loadPoints(self.realm)
            }
          }
        }
    })
  }
  
  // load points from realm database
  func loadPoints(var realm:Realm? = nil, checkForUpdatedData:Bool = false) {
  
    if realm == nil {
      realm = try! Realm()
    }
    
    let points = realm!.objects(DodiesPoint).filter("statuss in {'parbaudits', 'neparbaudits'}")
    
    for p:DodiesPoint in points {
      let point = DodiesAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake(p.longitude, p.latitude)

        point.title = p.name
        point.desc = p.desc
        point.statuss = p.statuss
        point.apraksts = p.apraksts
        point.id = p.id
        point.garums = p.garums
        point.datums = p.datums
        point.tips = p.tips
      
      self.mapView.addAnnotation(point)
    }
    
    Async.main {
      Helper.dismissGlobalHUD()
      
      if checkForUpdatedData {
        self.checkIfNeedToUpdate()
      }
    }
  }
  
  // update last changed timestamp from server
  func updateLastChangedTimestamp() {
    Alamofire.request(.GET, "http://dodies.lv/apraksti/lastchanged.txt").responseString(completionHandler: {
      response in
        if response.result.isSuccess {
          if let timestamp = Int(response.result.value!.stringByReplacingOccurrencesOfString("\n", withString: "")) {
            Defaults[self.LastChangedTimestampKey] = timestamp
          }
        }
    })
  }
  
  // check if need to update
  func checkIfNeedToUpdate() {
    Alamofire.request(.GET, "http://dodies.lv/apraksti/lastchanged.txt").responseString(completionHandler: {
  response in
      if response.result.isSuccess {
        if let timestamp = Int(response.result.value!.stringByReplacingOccurrencesOfString("\n", withString: "")) {
          if timestamp > Defaults[self.LastChangedTimestampKey].intValue {
            self.downloadData()
          }
        }
      }
    })
  }
  
  // show error
  func showError() {
    let alert = AlertController(title: "Kļūda", message: "Neizdevās lejuplādēt datus, lūdzu pārbaudiet savus iestatījumus un mēģiniet vēlreiz!", preferredStyle: .Alert)
          alert.addAction(AlertAction(title: "OK", style: .Preferred))
          alert.present()
  }
  
  // pass object to details view
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "details" || segue.identifier == "detailsWithPicture" {
    
      if let details: Details = segue.destinationViewController as? Details {
        details.point = selectedPoint
        
        selectedPoint = nil
      }
    }
  }

}
