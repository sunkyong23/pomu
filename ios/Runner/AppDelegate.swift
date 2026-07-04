import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var visionChannel: FlutterMethodChannel?

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
    }

    return didFinish
  }

  private func registerVisionChannel() {
    let controller: FlutterViewController?

    if let root = window?.rootViewController as? FlutterViewController {
      controller = root
    } else {
      controller = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController as? FlutterViewController
    }

    guard let controller else {
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

  private func analyzeImage(data: Data, result: @escaping FlutterResult) {
    guard let image = UIImage(data: data),
          let cgImage = image.cgImage else {
      result(FlutterError(
        code: "INVALID_IMAGE",
        message: "Could not create image",
        details: nil
      ))
      return
    }

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
}