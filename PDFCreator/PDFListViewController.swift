import UIKit
import RealmSwift

class PDFListViewController: UITableViewController {

    var pdfs: Results<PDFFileObject>!
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfs = DataManager.shared.pdfs
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
        return cell
    }

    @IBAction func newTapped() {
    }

    @IBAction func importTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Import From Photo Library", style: .default) { _ in

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

