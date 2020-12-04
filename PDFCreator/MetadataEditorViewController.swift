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

        form +++ Section()
        <<< TextRow(tagAuthor) { row in
            row.title = "Author"
            row.value = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        }
        <<< TextRow(tagCreationDate) { row in
            row.title = "Creation Date"
            row.value = pdfDocument.documentAttributes?[PDFDocumentAttribute.creationDateAttribute] as? String
        }
        <<< TextRow(tagCreator) { row in
            row.title = "Creator"
            row.value = pdfDocument.documentAttributes?[PDFDocumentAttribute.creatorAttribute] as? String
        }
        <<< TextRow(tagModificationDate) { row in
            row.title = "Modification Date"
            row.value = pdfDocument.documentAttributes?[PDFDocumentAttribute.modificationDateAttribute] as? String
        }
        <<< TextRow(tagProducer) { row in
            row.title = "Producer"
            row.value = pdfDocument.documentAttributes?[PDFDocumentAttribute.producerAttribute] as? String
        }
        <<< TextRow(tagSubject) { row in
            row.title = "Subject"
            row.value = pdfDocument.documentAttributes?[PDFDocumentAttribute.subjectAttribute] as? String
        }
        <<< TextRow(tagTitle) { row in
            row.title = "Title"
            row.value = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        }

        form +++ MultivaluedSection(multivaluedOptions: [.Reorder, .Insert, .Delete], header: "keywords") { section in
            section.multivaluedRowToInsertAt = { _ in
                TextRow { row in
                    row.placeholder = "Keyword"
                }
            }
            section.tag = tagKeywords
            if let keywords = pdfDocument.documentAttributes?[PDFDocumentAttribute.keywordsAttribute] as? [String] {
                for keyword in keywords {
                    section <<< TextRow { row in
                        row.value= keyword
                        row.placeholder = "Keyword"
                    }
                }
            }
        }
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