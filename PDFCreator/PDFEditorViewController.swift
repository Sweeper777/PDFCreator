import UIKit
import PDFKit
import PhotosUI
import SCLAlertView

enum PDFCollectionViewSection {
    case main
}
typealias DataSource = UICollectionViewDiffableDataSource<PDFCollectionViewSection, PDFPage>
typealias Snapshot = NSDiffableDataSourceSnapshot<PDFCollectionViewSection, PDFPage>

class PDFEditorViewController : UICollectionViewController {
    @IBOutlet var pagesCollectionView: UICollectionView!
    var pdfFileObject: PDFFileObject?
    var pdfDocument: PDFDocument?
    lazy var dataSource = makeDataSource()
    @IBOutlet var moreButton: UIBarButtonItem!

    override func viewDidLoad() {
        pagesCollectionView.delegate = self
        pagesCollectionView.dataSource = dataSource
        pagesCollectionView.dropDelegate = self
        pagesCollectionView.dragDelegate = self
        pagesCollectionView.dragInteractionEnabled = true
        pdfDocument = pdfFileObject?.pdfDocument
        pagesCollectionView.register(UINib(nibName: "PDFPageCell", bundle: nil), forCellWithReuseIdentifier: "cell")

        setUpMoreMenu()

        title = pdfFileObject?.fileName
        
        applySnapshot()
    }
    
    func makeDataSource() -> DataSource {
        DataSource(collectionView: pagesCollectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PDFPageCell
            cell.imageView.image = item.thumbnail(of: CGSize(width: 88, height: 88), for: .artBox)

            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            return cell
        }
    }
    
    func applySnapshot(animated: Bool = false) {
        guard let pdfDocument = pdfDocument else {
            return
        }
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems((0..<pdfDocument.pageCount).compactMap(pdfDocument.page(at:)))
        dataSource.apply(snapshot, animatingDifferences: animated)
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
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image])
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
            UIAction(title: "Edit Metadata", image: UIImage(systemName: "pencil.and.ellipsis.rectangle")!) { action in
                self.editMetadataTapped()
            },
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash")!, attributes: .destructive) { action in
                    self.deleteFileTapped()
                },
            ])
        ])
    }

    func renameTapped() {
        guard let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        
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
                try DataManager.shared.renamePDFObject(pdfFileObject, to: newName)
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
        guard let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        do {
            try DataManager.shared.deletePDFObject(pdfFileObject)
            navigationController?.popViewController(animated: true)
        } catch {
            SCLAlertView().showError("Error", subTitle: "An unknown error occurred!", closeButtonTitle: "OK")
            print(error)
        }
    }

    func exportTapped() {
        guard let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        let shareSheet = UIActivityViewController(activityItems: [pdfFileObject.fileURL], applicationActivities: nil)
        present(shareSheet, animated: true)
    }

    func editMetadataTapped() {
        performSegue(withIdentifier: "showMetadataEditor", sender: pdfFileObject)
    }

    func rotateLeftTapped(pageIndex: Int) {
        guard let pdfDocument = self.pdfDocument, let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        let page = pdfDocument.page(at: pageIndex)!
        page.rotation -= 90
        pdfDocument.write(to: pdfFileObject.fileURL)
        applySnapshot()
    }

    func rotateRightTapped(pageIndex: Int) {
        guard let pdfDocument = self.pdfDocument, let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        let page = pdfDocument.page(at: pageIndex)!
        page.rotation += 90
        pdfDocument.write(to: pdfFileObject.fileURL)
        applySnapshot()
    }

    func deletePageTapped(pageIndex: Int) {
        guard let pdfDocument = self.pdfDocument, let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        pdfDocument.removePage(at: pageIndex)
        pdfDocument.write(to: pdfFileObject.fileURL)
        applySnapshot()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PDFViewController {
            vc.document = pdfDocument
            vc.pageIndex = sender as? Int ?? 0
        } else if let vc = segue.destination as? MetadataEditorViewController {
            vc.pdfFileObject = pdfFileObject
        }
    }
}

extension PDFEditorViewController {
    public override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pdfDocument?.pageCount ?? 0
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let pdfDocument = self.pdfDocument else {
            fatalError()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PDFPageCell
        cell.imageView.image = pdfDocument.page(at: indexPath.item)?.thumbnail(of: CGSize(width: 88, height: 88), for: .artBox)

        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let pdfDocument = self.pdfDocument else {
            fatalError()
        }
        
        return UIContextMenuConfiguration(identifier: nil) {
            self.makePDFPagePreview(page: pdfDocument.page(at: indexPath.item)!)
        }
        actionProvider: { elements in
            UIMenu(children: [
                UIMenu(options: .displayInline, children: [
                    UIAction(title: "Inspect") { action in
                        self.performSegue(withIdentifier: "inspectPDF", sender: indexPath.item)
                    },
                ]),
                UIAction(title: "Rotate Left", image: UIImage(systemName: "rotate.left")!) { action in
                    self.rotateLeftTapped(pageIndex: indexPath.item)
                    self.applySnapshot()
                },
                UIAction(title: "Rotate Right", image: UIImage(systemName: "rotate.right")!) { action in
                    self.rotateRightTapped(pageIndex: indexPath.item)
                    self.applySnapshot()
                },
                UIMenu(options: .displayInline, children: [
                    UIAction(title: "Delete", image: UIImage(systemName: "trash")!, attributes: .destructive) { action in
                        self.deletePageTapped(pageIndex: indexPath.item)
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
        guard let pdfDocument = self.pdfDocument, let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        
        if let pdf = PDFDocument(url: url) {
            pdfDocument.appendDocument(pdf)
            pdfDocument.write(to: pdfFileObject.fileURL)
            applySnapshot()
        } else if let image = UIImage(contentsOfFile: url.path),
            let page = PDFPage(image: image) {
            pdfDocument.insert(page, at: pdfDocument.pageCount)
            pdfDocument.write(to: pdfFileObject.fileURL)
        } else {
            SCLAlertView().showError("Error", subTitle: "Invalid file selected!", closeButtonTitle: "OK")
        }
    }
}

extension PDFEditorViewController : PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let pdfDocument = self.pdfDocument, let pdfFileObject = self.pdfFileObject else {
            SCLAlertView().showError("Error", subTitle: "Please select a PDF file first!", closeButtonTitle: "OK")
            return
        }
        results.first?.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
            if let image = object as? UIImage,
                let page = PDFPage(image: image) {
                DispatchQueue.main.async {
                    pdfDocument.insert(page, at: pdfDocument.pageCount)
                    pdfDocument.write(to: pdfFileObject.fileURL)
                    self.applySnapshot()
                }
            }
        })
        picker.dismiss(animated: true)
    }
}

extension PDFEditorViewController : UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let pdfDocument = self.pdfDocument else {
            fatalError()
        }
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

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: pdfDocument!.pageCount - 1, section: 0)
        if coordinator.proposal.operation == .move {
            movePage(to: destinationIndexPath, with: coordinator)
        }
    }

    func movePage(to destinationIndexPath: IndexPath, with coordinator: UICollectionViewDropCoordinator) {
        guard let item = coordinator.items.first,
                let sourceIndexPath = item.sourceIndexPath,
                let pageToInsert = item.dragItem.localObject as? PDFPage else {
            return
        }
        self.pdfDocument!.removePage(at: sourceIndexPath.item)
        self.pdfDocument!.insert(pageToInsert, at: destinationIndexPath.item)
        self.pdfDocument!.write(to: self.pdfFileObject!.fileURL)

        self.applySnapshot()
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
    }
}
