//
//  CoordinateMapPreview.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import MapKit

struct CoordinateMapPreview: View {
    let latitude: Double
    let longitude: Double

    @State private var position: MapCameraPosition

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude

        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _position = State(initialValue: .region(region))
    }

    var body: some View {
        Map(position: $position) {
            Marker("Photo Location", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        .id("\(latitude),\(longitude)")
        .onChange(of: latitude) { _, _ in recenter() }
        .onChange(of: longitude) { _, _ in recenter() }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .accessibilityLabel("Map preview of the photo location.")
    }

    private func recenter() {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        position = .region(region)
    }
}
