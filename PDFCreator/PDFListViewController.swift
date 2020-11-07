import UIKit
import RealmSwift
import SCLAlertView
import SwiftyUtils
import PDFKit
import PhotosUI

class PDFListViewController: UITableViewController {
    var pdfs: Results<PDFFileObject>!
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfs = DataManager.shared.pdfs
        navigationController?.navigationBar.tintColor = .white
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pdfs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = pdfs[indexPath.row].fileName
        cell.imageView?.image = pdfs[indexPath.row].pdfDocument?.page(at: 0)?.thumbnail(of: CGSize(width: 44, height: 44), for: .artBox)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    @IBAction func newTapped() {
        showNamePrompt { name in
            do {
                try DataManager.shared.importPDF(document: PDFDocument(), name: name)
                self.tableView.reloadData()
            } catch ImportError.fileAlreadyExists {
                SCLAlertView().showError("Error", subTitle: "Another PDF file with this name already exists!", closeButtonTitle: "OK")
            } catch {
                print(error)
            }
        }
    }

    @IBAction func importTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Import From Photo Library", style: .default) { _ in
            self.importFromPhotoLibrary()
        })
        actionSheet.addAction(UIAlertAction(title: "Import From Files", style: .default) { _ in
            self.importFromFiles()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(actionSheet, animated: true)
    }

    func importFromFiles() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf", "public.image"], in: .import)
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }

    func importFromPhotoLibrary() {
//        let imagePicker = UIImagePickerController(rootViewController: self)
//        imagePicker.delegate = self
//        imagePicker.sourceType = .photoLibrary
//        imagePicker.allowsEditing = false
//        imagePicker.modalPresentationStyle = .popover
//        imagePicker.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
//        present(imagePicker, animated: true)
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }

    func showNamePrompt(completion: @escaping (String) -> Void) {
        let nameInput = SCLAlertView()
        let textField = nameInput.addTextField()
        nameInput.addButton("OK") {
            if textField.text.isNotNilNotEmpty {
                completion(textField.text!)
            }
        }
        nameInput.showEdit("", subTitle: "Please enter a name for the combined PDF:", closeButtonTitle: "Cancel")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showPDFEditor", sender: pdfs[indexPath.row])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PDFEditorViewController,
            let pdfFileObject = sender as? PDFFileObject {
            vc.pdfFileObject = pdfFileObject
        }
    }
}

extension PDFListViewController : UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if urls.count == 1 {
            do {
                try DataManager.shared.importFile(url: urls.first!)
                tableView.reloadData()
            } catch ImportError.fileAlreadyExists {
                SCLAlertView().showError("Error", subTitle: "Another PDF file with this name already exists!", closeButtonTitle: "OK")
            } catch {
                print(error)
            }
        } else {
            showNamePrompt { name in
                do {
                    try DataManager.shared.importFiles(urls: urls, name: name)
                    self.tableView.reloadData()
                } catch ImportError.fileAlreadyExists {
                    SCLAlertView().showError("Error", subTitle: "Another PDF file with this name already exists!", closeButtonTitle: "OK")
                } catch {
                    print(error)
                }
            }
        }
    }
}

//extension PDFListViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//        picker.dismiss(animated: true)
//        if let url = info[.imageURL] as? URL {
//            showNamePrompt { name in
//                do {
//                    try DataManager.shared.importFiles(urls: [url], name: name)
//                } catch ImportError.fileAlreadyExists {
//                    SCLAlertView().showError("Error", subTitle: "Another PDF file with this name already exists!", closeButtonTitle: "OK")
//                } catch {
//                    print(error)
//                }
//            }
//        }
//    }
//}

