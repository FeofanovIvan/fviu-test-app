//
//  Paywall.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

struct Paywall: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let products: [PaywallProduct]
}
