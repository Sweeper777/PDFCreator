import UIKit
import PDFKit
import PhotosUI
import SCLAlertView

class PDFEditorViewController : UICollectionViewController {
    @IBOutlet var pagesCollectionView: UICollectionView!
    var pdfFileObject: PDFFileObject!
    var pdfDocument: PDFDocument!

    override func viewDidLoad() {
        pagesCollectionView.delegate = self
        pagesCollectionView.dataSource = self
        pdfDocument = pdfFileObject.pdfDocument
        pagesCollectionView.register(UINib(nibName: "PDFPageCell", bundle: nil), forCellWithReuseIdentifier: "cell")
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