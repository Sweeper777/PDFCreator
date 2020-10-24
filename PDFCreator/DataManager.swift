import Realm
import RealmSwift

class DataManager {
    let pdfs: Results<PDFFileObject>
    let realm: Realm!

    private init() {
        do {
            realm = try Realm()
            pdfs = realm.objects(PDFFileObject.self)
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
