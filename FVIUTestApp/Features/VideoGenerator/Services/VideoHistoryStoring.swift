//
//  VideoHistoryStoring.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

protocol VideoHistoryStoring {
    func generations() -> [VideoGeneration]
    func save(_ generation: VideoGeneration)
    func delete(_ generation: VideoGeneration)
}
