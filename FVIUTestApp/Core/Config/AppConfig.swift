//
//  AppConfig.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

enum AppConfig {
    static let apphudAPIKey = "app_FmCjFTwjWpcLSafxT8vCDeVffJyfFS"
    static let apphudPaywallID = "main"
    static let apiApplicationID = "com.test.test"
    static let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZW1haWwiOiJzaGFyb3ZfMTk5OUBsaXN0LnJ1Iiwicm9sZSI6IkFETUlOIiwiZXhwIjo0OTM1MjA4NjcxLCJpYXQiOjE3ODE2MDg2NzEsInR5cGUiOiJhY2Nlc3MifQ.0GRnZq1LZA__0G0tYEsPER8lQiCiX_myE6_T_nMwUmc"

    static let chatBaseURL = URL(string: "https://nebulaapps.site")!
    static let videoBaseURL = URL(string: "https://nebulaapps.site/pixverse")!
    static let privacyPolicyURL = URL(string: "https://www.apple.com/legal/privacy/")!
    static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let subscriptionManagementURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}
