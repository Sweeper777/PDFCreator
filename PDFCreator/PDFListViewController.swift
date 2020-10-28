import UIKit
import RealmSwift

class PDFListViewController: UITableViewController {

    var pdfs: Results<PDFFileObject>!
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfs = DataManager.shared.pdfs
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pdfs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = pdfs[indexPath.row].fileName
        return cell
    }

    @IBAction func newTapped() {
    }

    @IBAction func importTapped() {
    }
}

