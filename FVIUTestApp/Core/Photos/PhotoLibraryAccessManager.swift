//
//  PhotoLibraryAccessManager.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Photos

protocol PhotoLibraryAccessManaging {
    var isAuthorized: Bool { get }

    func requestAccess() async -> Bool
}

final class PhotoLibraryAccessManager: PhotoLibraryAccessManaging {
    var isAuthorized: Bool {
        Self.isGranted(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return Self.isGranted(status)
    }

    private static func isGranted(_ status: PHAuthorizationStatus) -> Bool {
        status == .authorized || status == .limited
    }
}
