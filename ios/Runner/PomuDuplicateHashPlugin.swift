import Flutter
import UIKit
import Photos
import Vision

final class PomuDuplicateHashPlugin: NSObject {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "pomu/duplicate_hash",
            binaryMessenger: registrar.messenger()
        )

        let instance = PomuDuplicateHashPlugin()
        channel.setMethodCallHandler(instance.handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "findSimilarGroups":
            findSimilarGroups(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func findSimilarGroups(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? [String: Any],
            let assetIds = args["assetIds"] as? [String]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "assetIds is required", details: nil))
            return
        }

     let threshold = (args["threshold"] as? NSNumber)?.floatValue ?? 8.0

        DispatchQueue.global(qos: .userInitiated).async {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
            var assetMap: [String: PHAsset] = [:]

            fetchResult.enumerateObjects { asset, _, _ in
                assetMap[asset.localIdentifier] = asset
            }

            var prints: [(id: String, feature: VNFeaturePrintObservation)] = []

            for assetId in assetIds {
                guard let asset = assetMap[assetId],
                      let feature = self.featurePrint(for: asset)
                else { continue }

                prints.append((id: assetId, feature: feature))
            }

            let groups = self.clusterSimilarFeatures(prints, threshold: threshold)

            DispatchQueue.main.async {
                result(groups)
            }
        }
    }

    private func featurePrint(for asset: PHAsset) -> VNFeaturePrintObservation? {
        let manager = PHImageManager.default()

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isSynchronous = true
        options.isNetworkAccessAllowed = false

        var resultImage: UIImage?

        manager.requestImage(
            for: asset,
           targetSize: CGSize(width: 160, height: 160),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            resultImage = image
        }

        guard let cgImage = resultImage?.cgImage else { return nil }

        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }

    private func clusterSimilarFeatures(
    _ prints: [(id: String, feature: VNFeaturePrintObservation)],
    threshold: Float
) -> [[String]] {
    //print("🧪 Vision threshold:", threshold, "prints:", prints.count)

    var logCount = 0
    var groups: [[(id: String, feature: VNFeaturePrintObservation)]] = []

    for item in prints {
        var added = false

        for index in groups.indices {
            guard let first = groups[index].first else { continue }

            var distance: Float = 0

            do {
                try item.feature.computeDistance(&distance, to: first.feature)

                if logCount < 20 {
                    //print("🧪 Vision distance:", distance, "threshold:", threshold)
                    logCount += 1
                }

                if distance <= threshold {
                    groups[index].append(item)
                    added = true
                    break
                }
            } catch {
                //print("⚠️ Vision distance failed:", error.localizedDescription)
                continue
            }
        }

        if !added {
            groups.append([item])
        }
    }

    let result = groups
        .filter { $0.count > 1 }
        .map { group in group.map { $0.id } }

    //print("✅ Vision similar groups:", result.count)

    return result
}
}