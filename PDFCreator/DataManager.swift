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
            document.write(to: pdfObj.fileURL)
        }
    }

    func importFiles(urls: [URL], name: String) throws {
        func urlToPages(url: URL) throws -> [PDFPage] {
            if let document = PDFDocument(url: url) {
                var pages = [PDFPage]()
                pages.reserveCapacity(document.pageCount)
                (0..<document.pageCount).forEach { pages.append(document.page(at: $0)!) }
                return pages
            } else if let image = UIImage(contentsOfFile: url.path),
                      let page = PDFPage(image: image) {
                return [page]
            } else {
                throw ImportError.unableToCreatePage
            }
        }
        let pages = try urls.flatMap(urlToPages(url:))
        var i = 0
        let document = PDFDocument()
        for page in pages {
            document.insert(page, at: i)
            i += 1
        }
        try importPDF(document: document, name: name)
    }

    func importFile(url: URL) throws {
        let pdf: PDFDocument
        if let document = PDFDocument(url: url) {
            pdf = document
        } else if let image = UIImage(contentsOfFile: url.path),
            let page = PDFPage(image: image) {
            pdf = PDFDocument()
            pdf.insert(page, at: 0)
        } else {
            throw ImportError.unableToCreatePage
        }
        try importPDF(document: pdf, name: url.deletingPathExtension().lastPathComponent)
    }

    func deletePDFObject(_ pdfObj: PDFFileObject) throws {
        let url = pdfObj.fileURL
        try realm.write {
            realm.delete(pdfObj)
        }
        try FileManager.default.removeItem(at: url)
    }

    func renamePDFObject(_ pdfObj: PDFFileObject, to newName: String) throws {
        let existingFiles = pdfs.filter("fileName == %@", newName)
        if existingFiles.count > 0 {
            throw ImportError.fileAlreadyExists
        }

        try realm.write {
            let oldURL = pdfObj.fileURL
            pdfObj.fileName = newName
            let newURL = pdfObj.fileURL
            try FileManager.default.moveItem(at: oldURL, to: newURL)
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

    var fileURL: URL {
        DataManager.shared.baseURL.appendingPathComponent(fileName).appendingPathExtension("pdf")
    }
}

extension PDFDocument {
    func appendDocument(_ other: PDFDocument) {
        for i in 0..<other.pageCount {
            insert(other.page(at: i)!, at: pageCount)
        }
    }
}