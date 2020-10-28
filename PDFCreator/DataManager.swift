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