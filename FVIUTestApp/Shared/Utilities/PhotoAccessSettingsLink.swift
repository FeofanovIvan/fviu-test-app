//
//  PhotoAccessSettingsLink.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import UIKit

enum PhotoAccessSettingsLink {
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
