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