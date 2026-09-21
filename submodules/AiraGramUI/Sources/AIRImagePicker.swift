import Foundation
import UIKit
import PhotosUI

// AIR: "просто фото из галереи" — a single-image `PHPickerViewController`,
// nothing more. PHPicker rather than the classic `UIImagePickerController`
// because it runs out-of-process: iOS hands the app only the one photo
// actually chosen, with no photo-library permission prompt at all, which is
// the right privacy shape for "pick one picture" and needs no Info.plist
// usage-description entry to carry.
final class AIRImagePickerPresenter: NSObject, PHPickerViewControllerDelegate {
    private var completion: ((UIImage?) -> Void)?
    /// Holds itself alive for the duration of the pick — nothing else keeps
    /// a reference to a presenter that exists only to answer one delegate
    /// callback.
    private static var active: AIRImagePickerPresenter?

    static func present(from controller: UIViewController, completion: @escaping (UIImage?) -> Void) {
        let presenter = AIRImagePickerPresenter()
        presenter.completion = completion
        Self.active = presenter

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = presenter
        controller.present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            self.finish(with: nil)
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                self?.finish(with: object as? UIImage)
            }
        }
    }

    private func finish(with image: UIImage?) {
        self.completion?(image)
        self.completion = nil
        Self.active = nil
    }
}
