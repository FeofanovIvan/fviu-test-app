//
//  LoadableState.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

enum LoadableState<Value> {
    case idle
    case loading
    case success(Value)
    case error(AppError)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
