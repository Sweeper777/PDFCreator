import Realm
import RealmSwift
import PDFKit

class DataManager {
    let pdfs: Results<PDFFileObject>
    let realm: Realm!
    let baseURL: URL

    private init() {
        do {
            realm = try Realm()
            pdfs = realm.objects(PDFFileObject.self)
            baseURL = try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true).appendingPathComponent("PDFs")
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            print(baseURL)
        } catch let error {
            print(error)
            fatalError()
        }
    }

    private static var _shared: DataManager?

    public static var shared: DataManager {
        _shared = _shared ?? DataManager()
        return _shared!
    }

    func importPDF(document: PDFDocument, name: String) throws {
        let existingFiles = pdfs.filter("fileName == %@", name)
        if existingFiles.count > 0 {
            throw ImportError.fileAlreadyExists
        }
        try realm.write {
            let pdfObj = PDFFileObject()
            pdfObj.fileName = name
            realm.add(pdfObj)
            document.write(to: baseURL.appendingPathComponent(name).appendingPathExtension("pdf"))
        }
    }

}

enum ImportError : Error {
    case unableToCreatePage
    case fileAlreadyExists
}

extension PDFFileObject {
    var pdfDocument: PDFDocument? {
        PDFDocument(url: DataManager.shared.baseURL.appendingPathComponent(fileName).appendingPathExtension("pdf"))
    }
}