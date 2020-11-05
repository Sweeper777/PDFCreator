import UIKit
import PDFKit

class PDFEditorViewController : UIViewController {
    @IBOutlet var pagesCollectionView: UICollectionView!
    var pdfFileObject: PDFFileObject!
    var pdfDocument: PDFDocument!

}