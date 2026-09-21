import Foundation
import UIKit
import PhotosUI

// AIR: "просто фото из галереи" — a single-image picker, nothing more.
//
// `PHPickerViewController` on iOS 14+: it runs out-of-process, so iOS hands
// the app only the one photo actually chosen, with no photo-library
// permission prompt at all — the right privacy shape for "pick one picture",
// and it needs no Info.plist usage-description entry to carry. Below iOS 14
// (this app's floor is 13) it does not exist, so that version falls back to
// the classic `UIImagePickerController`, which does prompt for photo-library
// access — the app already carries `NSPhotoLibraryUsageDescription` for its
// other photo pickers, so nothing new to add there.
public final class AIRImagePickerPresenter: NSObject {
    private var completion: ((UIImage?) -> Void)?
    /// Holds itself alive for the duration of the pick — nothing else keeps
    /// a reference to a presenter that exists only to answer one delegate
    /// callback.
    private static var active: AIRImagePickerPresenter?

    public static func present(from controller: UIViewController, completion: @escaping (UIImage?) -> Void) {
        let presenter = AIRImagePickerPresenter()
        presenter.completion = completion
        Self.active = presenter

        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = presenter
            controller.present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = presenter
            controller.present(picker, animated: true)
        }
    }

    private func finish(with image: UIImage?) {
        self.completion?(image)
        self.completion = nil
        Self.active = nil
    }
}

@available(iOS 14.0, *)
extension AIRImagePickerPresenter: PHPickerViewControllerDelegate {
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
}

extension AIRImagePickerPresenter: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        self.finish(with: info[.originalImage] as? UIImage)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        self.finish(with: nil)
    }
}
