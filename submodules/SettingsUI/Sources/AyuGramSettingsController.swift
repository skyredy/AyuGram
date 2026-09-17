import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import ItemListUI
import AccountContext
import TelegramPresentationData
import PresentationDataUtils

private final class AyuGramFeatureRow {
    let title: String
    let icon: UIImage?
    let action: () -> Void

    init(title: String, icon: UIImage?, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
}

private final class AyuGramFeaturesHeaderView: UIView {
    let logoView: UIImageView
    let titleLabel: UILabel
    let versionLabel: UILabel

    override init(frame: CGRect) {
        self.logoView = UIImageView()
        self.titleLabel = UILabel()
        self.versionLabel = UILabel()

        super.init(frame: frame)

        self.logoView.contentMode = .scaleAspectFit
        self.logoView.layer.cornerRadius = 22.0
        self.logoView.layer.masksToBounds = true
        self.logoView.translatesAutoresizingMaskIntoConstraints = false

        self.titleLabel.font = .systemFont(ofSize: 22.0, weight: .bold)
        self.titleLabel.textAlignment = .center
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false

        self.versionLabel.font = .systemFont(ofSize: 13.0, weight: .regular)
        self.versionLabel.textAlignment = .center
        self.versionLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.logoView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.versionLabel)

        NSLayoutConstraint.activate([
            self.logoView.topAnchor.constraint(equalTo: self.topAnchor, constant: 24.0),
            self.logoView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.logoView.widthAnchor.constraint(equalToConstant: 96.0),
            self.logoView.heightAnchor.constraint(equalToConstant: 96.0),

            self.titleLabel.topAnchor.constraint(equalTo: self.logoView.bottomAnchor, constant: 14.0),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20.0),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20.0),

            self.versionLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 4.0),
            self.versionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20.0),
            self.versionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20.0),
            self.versionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20.0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class AyuGramFeaturesTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let rows: [AyuGramFeatureRow]

    init(rows: [AyuGramFeatureRow]) {
        self.rows = rows
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "CATEGORIES"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AyuGramFeatureRow") ?? UITableViewCell(style: .default, reuseIdentifier: "AyuGramFeatureRow")
        let row = self.rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.imageView?.image = row.icon
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.rows[indexPath.row].action()
    }
}

private final class AyuGramFeaturesControllerNode: ASDisplayNode {
    let tableView: UITableView
    private let tableNode: ASDisplayNode
    private let headerView: AyuGramFeaturesHeaderView
    private let dataSource: AyuGramFeaturesTableDataSource

    init(theme: PresentationTheme, logo: UIImage?, rows: [AyuGramFeatureRow]) {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.dataSource = AyuGramFeaturesTableDataSource(rows: rows)
        self.headerView = AyuGramFeaturesHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 210.0))

        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)

        super.init()

        self.backgroundColor = theme.list.plainBackgroundColor
        self.addSubnode(self.tableNode)

        self.tableView.dataSource = self.dataSource
        self.tableView.delegate = self.dataSource
        self.tableView.backgroundColor = theme.list.plainBackgroundColor
        self.tableView.separatorColor = theme.list.itemPlainSeparatorColor

        self.headerView.logoView.image = logo
        self.headerView.titleLabel.text = "AyuGram"
        self.headerView.titleLabel.textColor = theme.list.itemPrimaryTextColor
        self.headerView.versionLabel.textColor = theme.list.itemSecondaryTextColor

        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        self.headerView.versionLabel.text = "\(shortVersion) (\(buildNumber))"

        self.tableView.tableHeaderView = self.headerView
    }

    func containerLayoutUpdated(layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.tableNode, frame: CGRect(origin: CGPoint(), size: layout.size))

        self.tableView.contentInset = UIEdgeInsets(top: navigationBarHeight, left: 0.0, bottom: layout.intrinsicInsets.bottom, right: 0.0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset

        self.headerView.frame = CGRect(x: 0.0, y: 0.0, width: layout.size.width, height: 210.0)
        self.tableView.tableHeaderView = self.headerView
    }
}

public final class AyuGramSettingsController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData

    private var controllerNode: AyuGramFeaturesControllerNode {
        return self.displayNode as! AyuGramFeaturesControllerNode
    }

    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = "AyuGram"
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func pushController(_ controller: ViewController) {
        (self.navigationController as? NavigationController)?.pushViewController(controller)
    }

    public override func loadDisplayNode() {
        let rows: [AyuGramFeatureRow] = [
            AyuGramFeatureRow(title: "Ghost Mode", icon: PresentationResourcesSettings.ayuGramGhost, action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramGhostModeController(context: self.context))
            }),
            AyuGramFeatureRow(title: "Spy", icon: UIImage(systemName: "eye.fill"), action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramEmptyController(context: self.context, title: "Spy"))
            }),
            AyuGramFeatureRow(title: "Filters", icon: UIImage(systemName: "line.3.horizontal.decrease.circle.fill"), action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramEmptyController(context: self.context, title: "Filters"))
            }),
            AyuGramFeatureRow(title: "Customization", icon: UIImage(systemName: "paintbrush.pointed.fill"), action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramEmptyController(context: self.context, title: "Customization"))
            })
        ]

        self.displayNode = AyuGramFeaturesControllerNode(theme: self.presentationData.theme, logo: PresentationResourcesSettings.ayuGramSettings, rows: rows)
        self.displayNodeDidLoad()
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.controllerNode.containerLayoutUpdated(layout: layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }
}

private enum AyuGramEmptyEntry: ItemListNodeEntry {
    case placeholder

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        return 0
    }

    static func ==(lhs: AyuGramEmptyEntry, rhs: AyuGramEmptyEntry) -> Bool {
        return true
    }

    static func <(lhs: AyuGramEmptyEntry, rhs: AyuGramEmptyEntry) -> Bool {
        return false
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        preconditionFailure("AyuGramEmptyEntry.placeholder is never inserted into the entries list")
    }
}

public func ayuGramEmptyController(context: AccountContext, title: String) -> ViewController {
    let signal = context.sharedContext.presentationData
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: [AyuGramEmptyEntry](), style: .blocks)
        return (controllerState, (listState, Void()))
    }

    return ItemListController(context: context, state: signal)
}

public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    return AyuGramSettingsController(context: context)
}
