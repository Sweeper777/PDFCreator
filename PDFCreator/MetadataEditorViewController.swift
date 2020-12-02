import Eureka
import UIKit
import SCLAlertView
import PDFKit

class MetadataEditorViewController: FormViewController {
    var pdfFileObject: PDFFileObject!
    var pdfDocument: PDFDocument!

    override func viewDidLoad() {
        super.viewDidLoad()

        pdfDocument = pdfFileObject.pdfDocument
        isEditing = true
    }

}
