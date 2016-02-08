//
//  CSViewController.swift
//
//
//  Created by Filip Kirschner on 19/09/15.
//
//

import UIKit
import RxSwift
import CoreLocation
import MapKit

class CSViewController: UIViewController, MKMapViewDelegate {
    
    //Services
    var apiClient: ApiClient!
    var locationManager: CSLocationManager!
    
    //Current variables
    private var userLocation = CLLocationCoordinate2D()
    private var nearestATM: ATM?
    private var selectedMarker: MKAnnotation?
    private var mapViewDefaultCornerRadius = CGFloat(140)
    private var isFullscreen = false
    
    
    //Interface
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var minimizeButton: UIButton!
    @IBOutlet weak var branchesSwitch: UISwitch!
    @IBOutlet weak var branchesText: UILabel!
    
    //Fullscreen constraints
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        startRequestingNearestATM()
        startFollowingUser()
        setupUI()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        self.setUIFullscreen(true)
    }
    
    // MARK: User interface
    func setupUI()
    {
        self.mapView.layer.masksToBounds = true
        self.view.updateConstraints()
        self.mapViewDefaultCornerRadius = self.mapView.bounds.height/2
        self.mapView.layer.cornerRadius = mapViewDefaultCornerRadius
        self.setupMapButton(self.navigateButton)
        self.setupMapButton(self.minimizeButton)
        self.setupMapButton(self.reloadButton)
        self.mapView.showsUserLocation = true
        self.mapView.userTrackingMode = MKUserTrackingMode.None
        self.mapView.delegate = self
        self.mapView.layer.borderColor = CSStyles.csBlue.CGColor
        self.mapView.layer.borderWidth = 20.0
    }
    
    func setupMapButton(button: UIView)
    {
        button.layer.cornerRadius = 22.5
        button.layer.borderWidth = 3.0
        button.layer.borderColor = CSStyles.csBlue.CGColor
    }
    
    func setUIFullscreen(fullscreen: Bool)
    {
        if self.isFullscreen == fullscreen{
            return
        }
        
        self.isFullscreen = fullscreen
        
        //Map view size manipulation
        self.topConstraint.priority = fullscreen ? 750 : 250
        self.bottomConstraint.priority = fullscreen ? 750 : 250
        self.leftConstraint.priority = fullscreen ? 750 : 250
        UIView.animateWithDuration(0.5, animations: {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        })
        
        //Animate border
        let width = CABasicAnimation(keyPath: "borderWidth")
        width.fromValue = self.mapView.layer.borderWidth
        width.toValue = fullscreen ? 0 : 20.0
        width.duration = 0.5
        width.repeatCount = 1
        self.mapView.layer.addAnimation(width, forKey: "borderWidth")
        self.mapView.layer.borderWidth = fullscreen ? 0 : 20.0
        
        //Animate corners
        let radius = CABasicAnimation(keyPath: "cornerRadius")
        radius.fromValue = self.mapView.layer.cornerRadius
        radius.toValue = fullscreen ? 0 : mapViewDefaultCornerRadius
        radius.duration = 0.5
        radius.repeatCount = 1
        self.mapView.layer.addAnimation(radius, forKey: "cornerRadius")
        self.mapView.layer.cornerRadius = fullscreen ? 0 : mapViewDefaultCornerRadius
    }
    
    // MARK: UI Interactions
    @IBAction func minimizeButtonPressed()
    {
        self.setUIFullscreen(false)
        self.requestNearestATM(userLocation, force: true)
    }
    
    @IBAction func navigateButtonPressed()
    {
        if self.selectedMarker != nil {
            CSNavigation.navigateTo(self.selectedMarker!.coordinate)
            
        } else if self.nearestATM != nil {
            
            CSNavigation.navigateTo(self.nearestATM!.location.coordinate)
        }
    }
    
    @IBAction func reloadButtonPressed()
    {
        requestNearestATM(userLocation, force: true)
    }
    
    // MARK: Map View Delegate
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        self.selectedMarker = view.annotation
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView)
    {
        self.selectedMarker = nil
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let annotation = annotation as? AtmMapAnnotation {
            let identifier = "ATM"
            var annotationView: MKAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier){
                dequeuedView.annotation = annotation
                annotationView = dequeuedView
            } else {
                
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.canShowCallout = true
                let image = UIImage(named: "markerATM")
                annotationView.image = image
            }
            return annotationView
        }
        return nil
    }
    
    // MARK: Location Management
    func startFollowingUser()
    {
        self.locationManager.currentLocation.observeOn(MainScheduler.instance).subscribeNext( { location in
            self.userLocation = location
            if !self.isFullscreen{
                self.updateMapRegion()
            }
        })
    }
    
    func startRequestingNearestATM()
    {
        let brake = Observable<Int>.interval(8, scheduler: MainScheduler.instance).observeOn(MainScheduler.instance).subscribeNext({ num in
            self.requestNearestATM(self.userLocation, force: false)
        })
    }
    
    func requestNearestATM(location: CLLocationCoordinate2D, force: Bool)
    {
        self.apiClient.getAtms(location, limit: 50, bankCode: nil).take(1).map({ (atms:[ATM]) -> [ATM] in
            if atms.count > 20{
                var reducedAtms:[ATM] = [ATM]()
                for var i = 0; i < 20; i++ {
                    reducedAtms.append(atms[i])
                }
                return reducedAtms
            }else{
                return atms
            }
        }).observeOn(MainScheduler.instance).subscribeNext({ (places: [ATM]) in
            if places.count > 0 {
                self.updateNearestATM(places, force: force)
            }
        })
    }
    
    // MARK: Marker management
    func addMarkerToMap(marker: MKAnnotation)
    {
        self.mapView.addAnnotation(marker)
    }
    
    func removeAllMarkers()
    {
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove )
    }
    
    // MARK: ATM Management
    func updateNearestATM(atms: [ATM], force: Bool)
    {
        if self.isFullscreen {
            self.removeAllMarkers()
            self.nearestATM = atms[0]
            for atm in atms{
                self.addMarkerToMap(atm.getMapAnnotation())
            }
        }else{
            if atms.count > 0 {
                if !force && nearestATM?.id == atms[0].id{
                    return
                }
                self.removeAllMarkers()
                self.nearestATM = atms[0]
                self.addMarkerToMap(atms[0].getMapAnnotation())
                self.updateMapRegion()
            }
        }
    }
    
    func updateMapRegion()
    {
        if nearestATM != nil {
            let currentUserLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let distance = currentUserLocation.distanceFromLocation(nearestATM!.location)
            let region = MKCoordinateRegionMakeWithDistance(userLocation, distance*3, distance*3)
            mapView.setRegion(region, animated: true)
        }
    }
    
}
