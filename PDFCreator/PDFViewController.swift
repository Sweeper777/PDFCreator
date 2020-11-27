import UIKit
import PDFKit

class PDFViewController : UIViewController {
    var document: PDFDocument!
    var pageIndex: Int!

    override func viewDidLoad() {
        let pdfView = PDFView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        self.view = pdfView
        pdfView.document = document
        pdfView.displayMode = .singlePage
        pdfView.go(to: document.page(at: pageIndex)!)

        title = "Page \(pageIndex + 1)"
    }
}
