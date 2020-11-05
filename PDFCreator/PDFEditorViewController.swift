import UIKit
import PDFKit

class PDFEditorViewController : UIViewController {
    @IBOutlet var pagesCollectionView: UICollectionView!
    var pdfFileObject: PDFFileObject!
    var pdfDocument: PDFDocument!

    override func viewDidLoad() {
        pagesCollectionView.delegate = self
        pagesCollectionView.dataSource = self
        pdfDocument = pdfFileObject.pdfDocument
        pagesCollectionView.register(UINib(nibName: "PDFPageCell", bundle: nil), forCellWithReuseIdentifier: "cell")
    }
}

}