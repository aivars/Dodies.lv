//
//  Feature.swift
//  Dodies.lv
//
//  Created by Kristaps Grinbergs on 30/01/16.
//  Copyright © 2016 fassko. All rights reserved.
//

import Foundation
import RealmSwift

class DodiesPoint: Object {

  dynamic var latitude:Double = 0
  dynamic var longitude:Double = 0
  
  dynamic var apraksts:String = ""
  dynamic var datums:String = ""
  dynamic var desc:String = ""
  dynamic var garums:String = ""
  dynamic var id:String = ""
  dynamic var name:String = ""
  dynamic var statuss:String = ""
  dynamic var tips:String = ""
  dynamic var vertejums:String = ""
  dynamic var whatjson:String = ""
}
