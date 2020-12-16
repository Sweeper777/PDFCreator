import UIKit

class MySplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        preferredDisplayMode = .oneBesideSecondary
        self.delegate = self
    }
    
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return .primary
    }
}
