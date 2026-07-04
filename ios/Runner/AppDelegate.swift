import Flutter
import UIKit
import Vision
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var visionChannel: FlutterMethodChannel?
  private var albumChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let didFinish = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    DispatchQueue.main.async {
      self.registerVisionChannel()
      self.registerAlbumChannel()
    }

    return didFinish
  }

  private func flutterController() -> FlutterViewController? {
    if let root = window?.rootViewController as? FlutterViewController {
      return root
    }

    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController as? FlutterViewController
  }

  private func registerVisionChannel() {
    guard let controller = flutterController() else {
      print("❌ Pomu Vision channel: FlutterViewController not found")
      return
    }

    visionChannel = FlutterMethodChannel(
      name: "pomu/vision",
      binaryMessenger: controller.binaryMessenger
    )

    visionChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }

      if call.method == "analyzeImage" {
        guard let imageData = call.arguments as? FlutterStandardTypedData else {
          result(FlutterError(
            code: "INVALID_ARGUMENT",
            message: "Image data is missing",
            details: nil
          ))
          return
        }

        self.analyzeImage(data: imageData.data, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    print("✅ Pomu Vision channel registered")
  }

  private func registerAlbumChannel() {
    guard let controller = flutterController() else {
      print("❌ Pomu Album channel: FlutterViewController not found")
      return
    }

    albumChannel = FlutterMethodChannel(
      name: "pomu/album",
      binaryMessenger: controller.binaryMessenger
    )

    albumChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }

      if call.method == "addPhotosToAlbum" {
        guard
          let args = call.arguments as? [String: Any],
          let albumName = args["albumName"] as? String,
          let assetIds = args["assetIds"] as? [String]
        else {
          result(FlutterError(
            code: "INVALID_ARGUMENT",
            message: "albumName or assetIds is missing",
            details: nil
          ))
          return
        }

        self.addPhotosToAlbum(
          albumName: albumName,
          assetIds: assetIds,
          result: result
        )
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    print("✅ Pomu Album channel registered")
  }

  private func analyzeImage(data: Data, result: @escaping FlutterResult) {
    let request = VNClassifyImageRequest { request, error in
      if let error = error {
        result(FlutterError(
          code: "VISION_ERROR",
          message: error.localizedDescription,
          details: nil
        ))
        return
      }

      guard let observations = request.results as? [VNClassificationObservation] else {
        result([])
        return
      }

      let labels = observations.prefix(5).map { observation in
        [
          "identifier": observation.identifier,
          "confidence": observation.confidence
        ] as [String: Any]
      }

      result(labels)
    }

    let requestHandler = VNImageRequestHandler(
      data: data,
      orientation: .up,
      options: [:]
    )

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try requestHandler.perform([request])
      } catch {
        result(FlutterError(
          code: "VISION_FAILED",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }

  private func addPhotosToAlbum(
    albumName: String,
    assetIds: [String],
    result: @escaping FlutterResult
  ) {
    PHPhotoLibrary.shared().performChanges({
      let album = self.findOrCreateAlbumChangeRequest(albumName: albumName)

      let fetchResult = PHAsset.fetchAssets(
        withLocalIdentifiers: assetIds,
        options: nil
      )

      album?.addAssets(fetchResult)
    }) { success, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(
            code: "ALBUM_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
          return
        }

        result(success)
      }
    }
  }

  private func findOrCreateAlbumChangeRequest(
    albumName: String
  ) -> PHAssetCollectionChangeRequest? {
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(
      format: "title = %@",
      albumName
    )

    let collections = PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .albumRegular,
      options: fetchOptions
    )

    if let existingAlbum = collections.firstObject {
      return PHAssetCollectionChangeRequest(for: existingAlbum)
    }

    return PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
      withTitle: albumName
    )
  }
}