import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import ItemListUI
import AccountContext
import TelegramPresentationData
import PresentationDataUtils

private enum AyuGramRowAccessory {
    case disclosure
    case value(String)
}

private final class AyuGramRow {
    let title: String
    let icon: UIImage?
    let accessory: AyuGramRowAccessory
    let action: () -> Void

    init(title: String, icon: UIImage?, accessory: AyuGramRowAccessory, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.accessory = accessory
        self.action = action
    }
}

private final class AyuGramSection {
    let header: String?
    let rows: [AyuGramRow]

    init(header: String?, rows: [AyuGramRow]) {
        self.header = header
        self.rows = rows
    }
}

private final class AyuGramHeaderView: UIView {
    let logoView: UIImageView
    let titleLabel: UILabel
    let versionLabel: UILabel

    override init(frame: CGRect) {
        self.logoView = UIImageView()
        self.titleLabel = UILabel()
        self.versionLabel = UILabel()

        super.init(frame: frame)

        self.logoView.contentMode = .scaleAspectFit
        self.logoView.translatesAutoresizingMaskIntoConstraints = false

        self.titleLabel.font = .systemFont(ofSize: 24.0, weight: .bold)
        self.titleLabel.textAlignment = .center
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false

        self.versionLabel.font = .systemFont(ofSize: 14.0, weight: .regular)
        self.versionLabel.textAlignment = .center
        self.versionLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.logoView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.versionLabel)

        NSLayoutConstraint.activate([
            self.logoView.topAnchor.constraint(equalTo: self.topAnchor, constant: 28.0),
            self.logoView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.logoView.widthAnchor.constraint(equalToConstant: 96.0),
            self.logoView.heightAnchor.constraint(equalToConstant: 96.0),

            self.titleLabel.topAnchor.constraint(equalTo: self.logoView.bottomAnchor, constant: 16.0),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20.0),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20.0),

            self.versionLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 4.0),
            self.versionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20.0),
            self.versionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20.0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class AyuGramTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let sections: [AyuGramSection]
    let theme: PresentationTheme

    init(sections: [AyuGramSection], theme: PresentationTheme) {
        self.sections = sections
        self.theme = theme
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].header
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = self.theme.list.sectionHeaderTextColor
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = self.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "AyuGramRow") ?? UITableViewCell(style: .value1, reuseIdentifier: "AyuGramRow")

        cell.textLabel?.text = row.title
        cell.textLabel?.textColor = self.theme.list.itemPrimaryTextColor
        cell.imageView?.image = row.icon
        cell.backgroundColor = self.theme.list.itemBlocksBackgroundColor

        let selectedBackground = UIView()
        selectedBackground.backgroundColor = self.theme.list.itemHighlightedBackgroundColor
        cell.selectedBackgroundView = selectedBackground

        switch row.accessory {
        case .disclosure:
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        case let .value(value):
            cell.detailTextLabel?.text = value
            cell.detailTextLabel?.textColor = self.theme.list.itemAccentColor
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.sections[indexPath.section].rows[indexPath.row].action()
    }
}

private final class AyuGramSettingsControllerNode: ASDisplayNode {
    let tableView: UITableView
    private let tableNode: ASDisplayNode
    private let headerView: AyuGramHeaderView
    private let dataSource: AyuGramTableDataSource

    init(theme: PresentationTheme, sections: [AyuGramSection]) {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.dataSource = AyuGramTableDataSource(sections: sections, theme: theme)
        self.headerView = AyuGramHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 220.0))

        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)

        super.init()

        self.backgroundColor = theme.list.blocksBackgroundColor
        self.addSubnode(self.tableNode)

        self.tableView.dataSource = self.dataSource
        self.tableView.delegate = self.dataSource
        self.tableView.backgroundColor = theme.list.blocksBackgroundColor
        self.tableView.separatorColor = theme.list.itemBlocksSeparatorColor

        self.headerView.logoView.image = UIImage(bundleImageName: "AyuGram/LogoLarge")
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

        self.headerView.frame = CGRect(x: 0.0, y: 0.0, width: layout.size.width, height: 220.0)
        self.tableView.tableHeaderView = self.headerView
    }
}

public final class AyuGramSettingsController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData

    private var controllerNode: AyuGramSettingsControllerNode {
        return self.displayNode as! AyuGramSettingsControllerNode
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

    private func openLink(_ url: String) {
        self.context.sharedContext.applicationBindings.openUrl(url)
    }

    public override func loadDisplayNode() {
        let categories = AyuGramSection(header: "CATEGORIES", rows: [
            AyuGramRow(title: "Ghost Mode", icon: PresentationResourcesSettings.ayuGramGhost, accessory: .disclosure, action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramGhostModeController(context: self.context))
            }),
            AyuGramRow(title: "Spy", icon: PresentationResourcesSettings.ayuGramSpy, accessory: .disclosure, action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramEmptyController(context: self.context, title: "Spy"))
            }),
            AyuGramRow(title: "Filters", icon: PresentationResourcesSettings.ayuGramFilters, accessory: .disclosure, action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramEmptyController(context: self.context, title: "Filters"))
            }),
            AyuGramRow(title: "Customization", icon: PresentationResourcesSettings.ayuGramCustomization, accessory: .disclosure, action: { [weak self] in
                guard let self else {
                    return
                }
                self.pushController(ayuGramCustomizationController(context: self.context))
            })
        ])

        let links = AyuGramSection(header: "LINKS", rows: [
            AyuGramRow(title: "Channel", icon: nil, accessory: .value("@ayugram"), action: { [weak self] in
                self?.openLink("https://t.me/ayugram")
            }),
            AyuGramRow(title: "Chats", icon: nil, accessory: .value("@ayugramchat"), action: { [weak self] in
                self?.openLink("https://t.me/ayugramchat")
            }),
            AyuGramRow(title: "Documentation", icon: nil, accessory: .value("ayugram.one"), action: { [weak self] in
                self?.openLink("https://ayugram.one")
            })
        ])

        self.displayNode = AyuGramSettingsControllerNode(theme: self.presentationData.theme, sections: [categories, links])
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
