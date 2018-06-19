//
//  AboutViewController.swift
//  Dodies.lv
//
//  Created by Kristaps Grinbergs on 28/02/16.
//  Copyright © 2016 fassko. All rights reserved.
//

import UIKit

import Localize_Swift

class AboutViewController: UIViewController, Storyboarded {
  
  @IBOutlet var aboutText: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.titleView = UIImageView(image: UIImage(named: "dodies_nav_logo"))
    
    //swiftlint:disable line_length
    aboutText.text = "Dodies.lv is a collection of free nature trails, hiking paths, birdwatching towers and picnic places in Latvia. \nWould you like to spend some time in Latvian nature, make a fire, stay in a tent? Our map contains freely accessible places closer to nature, available at any time for anyone.\n\nThe green icons represent places which we have verified ourselves, they have photos and longer descriptions.\nThe grey icons show places we have not yet given our approval.\n\nHiking in Latvia is now made simple, select a point of interest and use Google Maps, Waze or Apple Maps to navigate there.".localized()

    self.automaticallyAdjustsScrollViewInsets = false
  }
  
}
