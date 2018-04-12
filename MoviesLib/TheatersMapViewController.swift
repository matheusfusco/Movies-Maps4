//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Eric Brito on 27/03/17.
//  Copyright © 2017 EricBrito. All rights reserved.
//

import UIKit
import MapKit

class TheatersMapViewController: UIViewController {

    @IBOutlet weak var mapview: MKMapView!
    
    //Array que irá conter nossos pontos de interesse
    var poiAnnotations: [MKPointAnnotation] = []
    
    //CLLocationManager é a classe que nos dá acesso aos dados de localização
    lazy var locationManager: CLLocationManager = CLLocationManager()
    
    var currentElement: String!     //Amazenará o elemento atual que está sendo analisado pelo XMLParser
    var theater: Theater!           //Objeto Theater que será alimentado pelo XMLParser
    var theaters: [Theater] = []    //Lista final de todos os cinemas após o XMLParser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Definindo a nossa classe como delegate do mapview
        mapview.delegate = self
        
        //Iniciando leitura e parse do XML
        loadXML()
        
        //Solicitando autorização do usuário para acesso à sua locaização
        requestUserLocationAuthorization()
    }
    
    func requestUserLocationAuthorization() {
        
        //Primeiro avaliamos se o device possui os serviços de localização habilitados
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager.delegate = self     //Definindo o deleate
            
            //Ajustando o nível de precisão. Dentre os possíveis valores temos:
            //kCLLocationAccuracyBestForNavigation, kCLLocationAccuracyNearestTenMeters,
            //kCLLocationAccuracyKilometer, kCLLocationAccuracyHundredMeters
            //kCLLocationAccuracyThreeKilometers
            //Quanto maior a precisão, mais uso é feito da bateria do device
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            
            locationManager.allowsBackgroundLocationUpdates = true
            
            //A linha abaixo ajuda na performance da bateria, pois os updates de localização são
            //pausados conforme o sistema ache necessário
            locationManager.pausesLocationUpdatesAutomatically = true
            
            //Analisamos o status da autorização. Caso ainda não tenha autorizado, solicitamos
            switch CLLocationManager.authorizationStatus() {
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Usuário já autorizou o acesso à sua localização")
                case .denied:
                    print("Usuário negou o acesso à localização")
                case .notDetermined:
                    locationManager.requestAlwaysAuthorization()    //Solicitando autorização
                case .restricted:
                    print("Este device não está habilitado a usar geolocalização")
                }
        } else {
            print("Você não possui os serviços de localização habilitados nesse device")
        }
    }

    //Método que fará a leitura e parse do XML
    func loadXML() {
        //Recuperando URL de acesso ao arquivo theaters.xml e criando XMLParser
        if let xmlURL = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser = XMLParser(contentsOf: xmlURL) {
            xmlParser.delegate = self   //Precisamos definir o delegate do Parser
            xmlParser.parse()           //Iniciando processo de parse
        }
    }
    
    //Método que adiciona as annotations no mapa
    func addTheaters() {
        for theater in theaters {
            
            //Recuperando as informações de localização a partir do Theater
            let coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            
            //Criando uma annotation personalizada
            let annotation = TheaterAnnotation(coordinate: coordinate)
            annotation.coordinate = coordinate
            annotation.title = theater.name
            annotation.subtitle = theater.url
            
            //Adicionando a annotation no mapa
            mapview.addAnnotation(annotation)
        }
        
        //Mostrando a região so mapa que engloba as annotations inseridas
        mapview.showAnnotations(mapview.annotations, animated: true)
    }
    
    func getRoute(destination: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()     //Criando requisição
        
        //Definindo o ponto de origem e destino da rota
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location!.coordinate))    //O ponto de origem é a localização do usuário
        
        let directions = MKDirections(request: request) //Objeto que fará a solicitação
        directions.calculate { (response: MKDirectionsResponse?, error: Error?) in
            if error == nil {
                guard let response = response else {return}
                let route = response.routes.first!  //Obtendo a primeira rota da lista de rotas
                print("Nome:", route.name)
                print("Distância:", route.distance)
                print("Duração:", route.expectedTravelTime)
                
                for step in route.steps {
                    print("Em \(step.distance) metros, \(step.instructions)")
                }

                //Adicionando a rota acima das ruas (abaixo dos nomes de rua)
                //Uma rota é um objeto Overlay. Recuperamos este overlay através da polylina da rota,
                //que é um vetor contendo todo o traçado da mesma.
                self.mapview.add(route.polyline, level: MKOverlayLevel.aboveRoads)
                
                //Mostrando todas as annotations do mapa
                self.mapview.showAnnotations(self.mapview.annotations, animated: true)
            }
        }
    }
}

//Implementando o protocolo XMLParserDelegate em nossa classe
extension TheatersMapViewController: XMLParserDelegate {
    
    //Analisando qual elemento está sendo iniciado
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        //Atribuindo o nome do elemento atual para análise nos demais métodos
        currentElement = elementName
        
        //Caso o elemento seja Data, podemos recuperar os atributos dele, como date e time
        if currentElement == "Data" {
            if let date = attributeDict["date"] {
                print("Este documento foi criado no dia \(date)")
            }
            if let time = attributeDict["time"] {
                print("Este documento foi criado às \(time)")
            }
        }
        
        //Se o elemento for Theater, isso indica que estamos olhando para um novo cinema
        //e nesse caso, instanciaremos uma nova classe Theater
        if currentElement == "Theater" {
            theater = Theater()
        }
    }
    
    //Neste método analisamos o conteúdo de um elemento
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        //Limpando o XML de espaços em branco e ENTERs
        let content = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if !content.isEmpty {
            
            //Dependendo de qual seja o elemento atual, inserimos seu conteúdo nas respectivas
            //propriedades do Theater
            switch currentElement {
                case "name":
                    theater.name = content
                case "address":
                    theater.address = content
                case "latitude":
                    theater.latitude = Double(content)!
                case "longitude":
                    theater.longitude = Double(content)!
                case "url":
                    theater.url = content
                default:
                    break
            }
        }
    }
    
    //Quando encontrar o fim do elemento, verificamos se é Theater. Caso seja, adicionamos o cinema
    //criado no nosso Array de Theaters
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Theater" { theaters.append(theater) }
    }

    //Método que é chamado ao término do parse do XML
    func parserDidEndDocument(_ parser: XMLParser) {
        
        //Adicionando os cinemas no mapa
        addTheaters()
    }
}

extension TheatersMapViewController: MKMapViewDelegate {
    
    //Método que desenha os overlays sobre o mapa
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        //Analisando se o Overlay é do tipo MKPolyline, que é o tipo enviado pela rota
        if overlay is MKPolyline {
            let renderer  = MKPolylineRenderer(overlay: overlay)    //Criando o renderer para o Overlay
            renderer.strokeColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)      //Definindo sua cor
            renderer.lineWidth = 6.0       //Espessura da linha
            return renderer
        } else {
            //Se não for uma Polylina, retornamos um Overlay padrão
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    //Método responsável por definir a view que será usada na annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        //Criamos uma MKAnnotationView
        var annotationView: MKAnnotationView!
        
        //Validamos se a annotation é uma TheaterAnnotation antes de definir sua view
        if annotation is TheaterAnnotation {
            
            //Este método recupera uma annotation que já foi utilizada caso esteja disponível
            //Para isso, usamos um identificador, que no nosso caso será "Theater"
            annotationView = mapview.dequeueReusableAnnotationView(withIdentifier: "Theater")
            
            //Se não tiver, criamos uma
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Theater")
                
                //Propriedade que indica se iremos mostrar o balão ao clicar na annotation
                annotationView.canShowCallout = true
                
                //Definimos a imagem que representará essa annotation
                annotationView.image = UIImage(named: "theaterIcon")
                
                //Criamos um botão para o lado direito e outro para o lado esquerdo do balão
                let btLeft = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                btLeft.setImage(UIImage(named: "car"), for: .normal)
                annotationView.leftCalloutAccessoryView = btLeft
                let btRight = UIButton(type: UIButtonType.detailDisclosure)
                annotationView.rightCalloutAccessoryView = btRight
            } else {
                
                //Caso a view já exista, atualizamos a sua propriedade annotation
                annotationView.annotation = annotation
            }
            return annotationView
            
        //Caso a annotation seja do tipo MKPointAnnotation, trabalhamos seu visual
        }  else if annotation is MKPointAnnotation {
            
            //Tentando recuperar uma reutilizável através do identificador "POI"
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "POI")
            if annotationView == nil {
                
                //Se não existir, criarmos uma nova. A view de uma PointAnnotation é MKPinAnnotationView
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "POI")
                (annotationView as! MKPinAnnotationView).canShowCallout = true
                (annotationView as! MKPinAnnotationView).pinTintColor = .blue   //Mudando a cor
                (annotationView as! MKPinAnnotationView).animatesDrop = true    //Mostrando com animação
            } else {
                annotationView?.annotation = annotation
            }
        }
        return annotationView
    }

    //Método chamado quando usuário toca em um callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        //Checamos se ele tocou no botão do lado esquerdo (botão que irá traçar a rota)
        if control == view.leftCalloutAccessoryView {
            
            //Método que traça a rota
            getRoute(destination: view.annotation!.coordinate)
            
        } else {
            
            //Instanciando a ViewController "WebViewController" pelo seu identificador no Storyboard
            let vc = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
            
            //Passando a URL que iremos abrir na WebView
            vc.url = view.annotation!.subtitle!
            
            //Mostrando a WebViewController
            present(vc, animated: true, completion: nil)
        }
        
        //Removemos quaisquer rotas que haviam sido traçadas antes
        mapView.removeOverlays(mapView.overlays)
        
        //Tiramos a seleção da annotation para que ele saia da tela
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
}

extension TheatersMapViewController: CLLocationManagerDelegate {
    
    //Este método é chamado sempre que é recebido ou alterado o status de autorização
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    
        //Caso o usuário tenha autorizado, mostramos a sua lozalização no mapa
        switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                mapview.showsUserLocation = true
            default:
                break
        }
    }
    
    //Método chamado sempre que o usuário altera a sua localização
    //e o mapa está definido para mostrar a localização so usuário
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        //Podemos recuperar várias informações. Dente elas, a velocidade atual do usuário
        print("Velocidade do usuário:", userLocation.location!.speed)
        
        //Se quisermos mudar a região do mapa para mostrar onde o usuário se encontra,
        //usamos o código abaixo, que cria uma região com a localização do usuário no centro
        //e distâncias latituniais e longitudinais de 500 metros
        
        //let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)
        //mapView.setRegion(region, animated: true)
    }
}

extension TheatersMapViewController: UISearchBarDelegate {
    
    //Método chamado sempre que o botão Search é tocado
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //Criamos a requisição com as informações que serão passadas à Apple sobre o que queremos buscar
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text   //Definindo o que estamos procurando
        request.region = mapview.region                 //E em qual região do mapa
        
        let search = MKLocalSearch(request: request)    //Objeto que fará a pesquisa junto à Apple
        search.start { (response: MKLocalSearchResponse?, error: Error?) in
            if error == nil {
                guard let response = response else {return} //Resposta da pesquisa
                DispatchQueue.main.async {                  //Retornando na thread principal
                    
                    //Antes de adicionar os pontos, removemos os que adicionados em pesquisas anteriores
                    self.mapview.removeAnnotations(self.poiAnnotations)
                    self.poiAnnotations.removeAll()
                    
                    for item in response.mapItems { //Percorrendo todos os itens da resposta
                        
                        //Criando as annotations. Neste caso, criamos como MKPointAnnotation
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = item.placemark.coordinate
                        annotation.title = item.name
                        annotation.subtitle = item.phoneNumber
                        self.poiAnnotations.append(annotation)
                    }
                    self.mapview.addAnnotations(self.poiAnnotations)
                }
            }
            searchBar.resignFirstResponder()    //Escondendo o teclado
        }
    }
}




