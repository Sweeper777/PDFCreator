import UIKit
import PDFKit
import PhotosUI
import SCLAlertView

class PDFEditorViewController : UICollectionViewController {
    @IBOutlet var pagesCollectionView: UICollectionView!
    var pdfFileObject: PDFFileObject!
    var pdfDocument: PDFDocument!
    @IBOutlet var moreButton: UIBarButtonItem!

    override func viewDidLoad() {
        pagesCollectionView.delegate = self
        pagesCollectionView.dataSource = self
        pdfDocument = pdfFileObject.pdfDocument
        pagesCollectionView.register(UINib(nibName: "PDFPageCell", bundle: nil), forCellWithReuseIdentifier: "cell")

        setUpMoreMenu()

        title = pdfFileObject.fileName
    }

    @IBAction func addPage() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "From Photo Library", style: .default) { _ in
            self.importFromPhotoLibrary()
        })
        actionSheet.addAction(UIAlertAction(title: "From Files", style: .default) { _ in
            self.importFromFiles()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(actionSheet, animated: true)
    }

    func importFromFiles() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf", "public.image"], in: .import)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }

    func importFromPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }

    func setUpMoreMenu() {
        moreButton.menu = UIMenu(children: [
            UIAction(title: "Export", image: UIImage(systemName: "square.and.arrow.up")!) { action in
                self.exportTapped()
            },
            UIAction(title: "Rename", image: UIImage(systemName: "pencil")!) { action in
                self.renameTapped()
            },
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash")!, attributes: .destructive) { action in
                    self.deleteFileTapped()
                },
            ])
        ])
    }

    func renameTapped() {
        func showNamePrompt(completion: @escaping (String) -> Void) {
            let nameInput = SCLAlertView()
            let textField = nameInput.addTextField()
            nameInput.addButton("OK") {
                if textField.text.isNotNilNotEmpty {
                    completion(textField.text!)
                }
            }
            nameInput.showEdit("", subTitle: "Please enter a new name for the PDF:", closeButtonTitle: "Cancel")
        }

        showNamePrompt { newName in
            do {
                try DataManager.shared.renamePDFObject(self.pdfFileObject, to: newName)
                self.title = newName
            } catch ImportError.fileAlreadyExists {
                SCLAlertView().showError("Error", subTitle: "This name has already been used!", closeButtonTitle: "OK")
            } catch {
                SCLAlertView().showError("Error", subTitle: "An unknown error occurred!", closeButtonTitle: "OK")
                print(error)
            }
        }
    }

    func deleteFileTapped() {
        do {
            try DataManager.shared.deletePDFObject(pdfFileObject)
            navigationController?.popViewController(animated: true)
        } catch {
            SCLAlertView().showError("Error", subTitle: "An unknown error occurred!", closeButtonTitle: "OK")
            print(error)
        }
    }

    func exportTapped() {
        let shareSheet = UIActivityViewController(activityItems: [pdfFileObject.fileURL], applicationActivities: nil)
        present(shareSheet, animated: true)
    }

    func rotateLeftTapped(pageIndex: Int) {
        let page = pdfDocument.page(at: pageIndex)!
        page.rotation -= 90
        pdfDocument.write(to: pdfFileObject.fileURL)
        collectionView.reloadItems(at: [IndexPath(item: pageIndex, section: 0)])
    }

    func rotateRightTapped(pageIndex: Int) {
        let page = pdfDocument.page(at: pageIndex)!
        page.rotation += 90
        pdfDocument.write(to: pdfFileObject.fileURL)
        collectionView.reloadItems(at: [IndexPath(item: pageIndex, section: 0)])
    }

    func deletePageTapped(pageIndex: Int) {
        pdfDocument.removePage(at: pageIndex)
        pdfDocument.write(to: pdfFileObject.fileURL)
        collectionView.deleteItems(at: [IndexPath(item: pageIndex, section: 0)])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PDFViewController {
            vc.document = pdfDocument
            vc.pageIndex = sender as? Int ?? 0
        }
    }
}

extension PDFEditorViewController {
    public override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pdfDocument.pageCount
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PDFPageCell
        cell.imageView.image = pdfDocument.page(at: indexPath.item)?.thumbnail(of: CGSize(width: 88, height: 88), for: .artBox)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil) {
            self.makePDFPagePreview(page: self.pdfDocument.page(at: indexPath.row)!)
        }
        actionProvider: { elements in
            UIMenu(children: [
                UIMenu(options: .displayInline, children: [
                    UIAction(title: "Inspect") { action in
                        self.performSegue(withIdentifier: "inspectPDF", sender: indexPath.row)
                    },
                ]),
                UIAction(title: "Rotate Left", image: UIImage(systemName: "rotate.left")!) { action in
                    self.rotateLeftTapped(pageIndex: indexPath.row)
                    collectionView.reloadItems(at: [indexPath])
                },
                UIAction(title: "Rotate Right", image: UIImage(systemName: "rotate.right")!) { action in
                    self.rotateRightTapped(pageIndex: indexPath.row)
                    collectionView.reloadItems(at: [indexPath])
                },
                UIMenu(options: .displayInline, children: [
                    UIAction(title: "Delete", image: UIImage(systemName: "trash")!, attributes: .destructive) { action in
                        self.deletePageTapped(pageIndex: indexPath.row)
                    },
                ]),
            ])
        }
    }

    func makePDFPagePreview(page: PDFPage) -> UIViewController {
        let viewController = UIViewController()
        let pageSize = page.bounds(for: .artBox).size
        let imageView = UIImageView(image: page.thumbnail(of: pageSize, for: .artBox))
        imageView.contentMode = .scaleAspectFit
        viewController.view = imageView
        viewController.preferredContentSize = pageSize

        return viewController
    }

}

extension PDFEditorViewController : UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if let pdf = PDFDocument(url: url) {
            self.pdfDocument.appendDocument(pdf)
            self.pdfDocument.write(to: pdfFileObject.fileURL)
            let originalPageCount = pdfDocument.pageCount - pdf.pageCount
            pagesCollectionView.insertItems(at: (originalPageCount..<pdfDocument.pageCount).map { IndexPath(item: $0, section: 0) })
        } else if let image = UIImage(contentsOfFile: url.path),
            let page = PDFPage(image: image) {
            self.pdfDocument.insert(page, at: self.pdfDocument.pageCount)
            self.pdfDocument.write(to: pdfFileObject.fileURL)
        } else {
            SCLAlertView().showError("Error", subTitle: "Invalid file selected!", closeButtonTitle: "OK")
        }
    }
}

extension PDFEditorViewController : PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        results.first?.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
            if let image = object as? UIImage,
                let page = PDFPage(image: image) {
                DispatchQueue.main.async {
                    self.pdfDocument.insert(page, at: self.pdfDocument.pageCount)
                    self.pdfDocument.write(to: self.pdfFileObject.fileURL)
                    self.pagesCollectionView.insertItems(at: [IndexPath(item: self.pdfDocument.pageCount - 1, section: 0)])
                }
            }
        })
        picker.dismiss(animated: true)
    }
}

extension PDFEditorViewController : UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let page = pdfDocument.page(at: indexPath.item)
        let itemProvider = NSItemProvider(item: nil, typeIdentifier: nil)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = page
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }

}