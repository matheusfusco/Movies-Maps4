//
//  Theater.swift
//  MoviesLib
//
//  Created by Eric Brito on 27/03/17.
//  Copyright © 2017 EricBrito. All rights reserved.
//

import Foundation

class Theater {
    
    var name: String = ""           //Nome do cinema
    var address: String = ""        //Endereço
    var latitude: Double = 0.0      //Latitude
    var longitude: Double = 0.0     //Longitude
    var url: String = ""            //URL do site do cinema
    
    //Construtor com parâmetros
    init(name: String, address: String, latitude: Double, longitude: Double, url: String) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.url = url
    }

    init() {
        
    }
}
