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

let tagAuthor = PDFDocumentAttribute.authorAttribute.rawValue
let tagCreationDate = PDFDocumentAttribute.creationDateAttribute.rawValue
let tagCreator = PDFDocumentAttribute.creatorAttribute.rawValue
let tagKeywords = PDFDocumentAttribute.keywordsAttribute.rawValue
let tagModificationDate = PDFDocumentAttribute.modificationDateAttribute.rawValue
let tagProducer = PDFDocumentAttribute.producerAttribute.rawValue
let tagSubject = PDFDocumentAttribute.subjectAttribute.rawValue
let tagTitle = PDFDocumentAttribute.titleAttribute.rawValue