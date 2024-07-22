//
//  ContentView.swift
//  MapRoute2
//
//  Created by 洪宗燦 on 2024/7/22.
//

import SwiftUI

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var startPoint: String = ""
    @State private var endPoint: String = ""
    @State private var route: MKRoute?
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationView {
            VStack {
                TextField("輸入起點", text: $startPoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("輸入終點", text: $endPoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    getRoute(from: startPoint, to: endPoint) { route, start, end in
                        self.route = route
                        self.startCoordinate = start
                        self.endCoordinate = end
                    }
                }) {
                    Text("開始導航")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
                
                if let route = route, let startCoordinate = startCoordinate, let endCoordinate = endCoordinate {
                    MapView(route: route, startCoordinate: startCoordinate, endCoordinate: endCoordinate)
                        .edgesIgnoringSafeArea(.all)
                }
                
                Spacer()
            }
            .navigationTitle("簡單導航")
        }
    }
    
    func getRoute(from start: String, to end: String, completion: @escaping (MKRoute?, CLLocationCoordinate2D?, CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(start) { startPlacemarks, _ in
            guard let startPlacemark = startPlacemarks?.first else { return }
            geocoder.geocodeAddressString(end) { endPlacemarks, _ in
                guard let endPlacemark = endPlacemarks?.first else { return }
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(placemark: startPlacemark))
                request.destination = MKMapItem(placemark: MKPlacemark(placemark: endPlacemark))
                request.transportType = .automobile
                
                let directions = MKDirections(request: request)
                directions.calculate { response, _ in
                    completion(response?.routes.first, startPlacemark.location?.coordinate, endPlacemark.location?.coordinate)
                }
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    var route: MKRoute
    var startCoordinate: CLLocationCoordinate2D
    var endCoordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = startCoordinate
        startAnnotation.title = "起點"
        mapView.addAnnotation(startAnnotation)
        
        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = endCoordinate
        endAnnotation.title = "終點"
        mapView.addAnnotation(endAnnotation)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "marker"
            var view: MKMarkerAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
            }
            return view
        }
    }
}

//@main
struct NavigationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
