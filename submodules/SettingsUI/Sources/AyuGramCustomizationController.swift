import Foundation
import UIKit
import Display
import AsyncDisplayKit
import AccountContext
import TelegramPresentationData

private final class AyuGramPreviewCell: UITableViewCell {
    private let backdropView: UIView
    private let bubbleView: UIView
    private let messageLabel: UILabel
    private let markView: UIImageView
    private let timeLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.backdropView = UIView()
        self.bubbleView = UIView()
        self.messageLabel = UILabel()
        self.markView = UIImageView()
        self.timeLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none

        self.backdropView.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleView.layer.cornerRadius = 16.0
        self.bubbleView.translatesAutoresizingMaskIntoConstraints = false

        self.messageLabel.font = .systemFont(ofSize: 15.0)
        self.messageLabel.numberOfLines = 0
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = false

        self.markView.contentMode = .scaleAspectFit
        self.markView.image = UIImage(systemName: "trash")
        self.markView.translatesAutoresizingMaskIntoConstraints = false

        self.timeLabel.font = .systemFont(ofSize: 11.0)
        self.timeLabel.text = "21:20"
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(self.backdropView)
        self.backdropView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.messageLabel)
        self.bubbleView.addSubview(self.markView)
        self.bubbleView.addSubview(self.timeLabel)

        NSLayoutConstraint.activate([
            self.backdropView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.backdropView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.backdropView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.backdropView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),

            self.bubbleView.topAnchor.constraint(equalTo: self.backdropView.topAnchor, constant: 18.0),
            self.bubbleView.bottomAnchor.constraint(equalTo: self.backdropView.bottomAnchor, constant: -18.0),
            self.bubbleView.leadingAnchor.constraint(equalTo: self.backdropView.leadingAnchor, constant: 14.0),
            self.bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: self.backdropView.trailingAnchor, constant: -40.0),

            self.messageLabel.topAnchor.constraint(equalTo: self.bubbleView.topAnchor, constant: 10.0),
            self.messageLabel.leadingAnchor.constraint(equalTo: self.bubbleView.leadingAnchor, constant: 12.0),
            self.messageLabel.trailingAnchor.constraint(equalTo: self.bubbleView.trailingAnchor, constant: -12.0),

            self.markView.topAnchor.constraint(equalTo: self.messageLabel.bottomAnchor, constant: 6.0),
            self.markView.bottomAnchor.constraint(equalTo: self.bubbleView.bottomAnchor, constant: -8.0),
            self.markView.widthAnchor.constraint(equalToConstant: 13.0),
            self.markView.heightAnchor.constraint(equalToConstant: 13.0),
            self.markView.trailingAnchor.constraint(equalTo: self.timeLabel.leadingAnchor, constant: -4.0),

            self.timeLabel.centerYAnchor.constraint(equalTo: self.markView.centerYAnchor),
            self.timeLabel.trailingAnchor.constraint(equalTo: self.bubbleView.trailingAnchor, constant: -12.0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(theme: PresentationTheme, text: String, markColor: UIColor, isTranslucent: Bool) {
        self.backdropView.backgroundColor = theme.chatList.backgroundColor
        self.bubbleView.backgroundColor = theme.chat.message.incoming.bubble.withoutWallpaper.fill.first ?? theme.list.itemBlocksBackgroundColor
        self.bubbleView.alpha = isTranslucent ? 0.55 : 1.0
        self.messageLabel.text = text
        self.messageLabel.textColor = theme.chat.message.incoming.primaryTextColor
        self.timeLabel.textColor = theme.chat.message.incoming.secondaryTextColor
        self.markView.tintColor = markColor
    }
}

private final class AyuGramColorPickerCell: UITableViewCell {
    private let stackView: UIStackView
    var onSelect: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.stackView = UIStackView()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.stackView.axis = .horizontal
        self.stackView.distribution = .fillEqually
        self.stackView.alignment = .center
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.stackView)

        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10.0),
            self.stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10.0),
            self.stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 12.0),
            self.stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -12.0),
            self.stackView.heightAnchor.constraint(equalToConstant: 42.0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(selectedIndex: Int, ringColor: UIColor) {
        for view in self.stackView.arrangedSubviews {
            view.removeFromSuperview()
        }

        for (index, color) in AyuGramSettings.deletedMarkColors.enumerated() {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false

            let swatch = UIButton(type: .custom)
            swatch.backgroundColor = color
            swatch.layer.cornerRadius = 13.0
            swatch.tag = index
            swatch.translatesAutoresizingMaskIntoConstraints = false
            swatch.addTarget(self, action: #selector(self.swatchPressed(_:)), for: .touchUpInside)

            if index == selectedIndex {
                container.layer.cornerRadius = 19.0
                container.layer.borderWidth = 2.0
                container.layer.borderColor = ringColor.cgColor
            }

            container.addSubview(swatch)
            self.stackView.addArrangedSubview(container)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 38.0),
                container.heightAnchor.constraint(equalToConstant: 38.0),
                swatch.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                swatch.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                swatch.widthAnchor.constraint(equalToConstant: 26.0),
                swatch.heightAnchor.constraint(equalToConstant: 26.0)
            ])
        }
    }

    @objc private func swatchPressed(_ sender: UIButton) {
        self.onSelect?(sender.tag)
    }
}

private final class AyuGramCustomizationDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let theme: PresentationTheme
    let previewText: String

    init(theme: PresentationTheme, previewText: String) {
        self.theme = theme
        self.previewText = previewText
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 4 : 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "CUSTOMIZATION" : "USEFUL FEATURES"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = self.theme.list.sectionHeaderTextColor
        }
    }

    private func configure(_ cell: UITableViewCell) {
        cell.backgroundColor = self.theme.list.itemBlocksBackgroundColor
        cell.textLabel?.textColor = self.theme.list.itemPrimaryTextColor
    }

    private func switchCell(_ tableView: UITableView, identifier: String, title: String, value: Bool, onChange: @escaping (Bool) -> Void) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? AyuGramSwitchCell ?? AyuGramSwitchCell(style: .default, reuseIdentifier: identifier)
        cell.textLabel?.text = title
        cell.switchView.isOn = value
        cell.onChange = onChange
        self.configure(cell)
        return cell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Preview") as? AyuGramPreviewCell ?? AyuGramPreviewCell(style: .default, reuseIdentifier: "Preview")
                cell.update(theme: self.theme, text: self.previewText, markColor: AyuGramSettings.deletedMarkColor, isTranslucent: AyuGramSettings.translucentDeletedMessages)
                return cell
            case 1:
                return self.switchCell(tableView, identifier: "Translucent", title: "Translucent Deleted Messages", value: AyuGramSettings.translucentDeletedMessages, onChange: { [weak tableView] isOn in
                    AyuGramSettings.translucentDeletedMessages = isOn
                    tableView?.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                })
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "DeletedMark") ?? UITableViewCell(style: .default, reuseIdentifier: "DeletedMark")
                cell.textLabel?.text = "Deleted Mark"
                cell.selectionStyle = .none
                let markView = UIImageView(image: UIImage(systemName: "trash"))
                markView.tintColor = AyuGramSettings.deletedMarkColor
                markView.frame = CGRect(x: 0.0, y: 0.0, width: 22.0, height: 22.0)
                cell.accessoryView = markView
                self.configure(cell)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Colors") as? AyuGramColorPickerCell ?? AyuGramColorPickerCell(style: .default, reuseIdentifier: "Colors")
                cell.update(selectedIndex: AyuGramSettings.deletedMarkColorIndex, ringColor: self.theme.list.itemAccentColor)
                cell.onSelect = { [weak tableView] index in
                    AyuGramSettings.deletedMarkColorIndex = index
                    tableView?.reloadSections(IndexSet(integer: 0), with: .none)
                }
                cell.backgroundColor = self.theme.list.itemBlocksBackgroundColor
                return cell
            }
        }

        switch indexPath.row {
        case 0:
            return self.switchCell(tableView, identifier: "LocalPremium", title: "Local Telegram Premium", value: AyuGramSettings.localPremium, onChange: { isOn in
                AyuGramSettings.localPremium = isOn
            })
        case 1:
            return self.switchCell(tableView, identifier: "DisableAds", title: "Disable Ads", value: AyuGramSettings.disableAds, onChange: { isOn in
                AyuGramSettings.disableAds = isOn
            })
        default:
            return self.switchCell(tableView, identifier: "GhostStatus", title: "Display Ghost Mode Status", value: AyuGramSettings.displayGhostModeStatus, onChange: { isOn in
                AyuGramSettings.displayGhostModeStatus = isOn
            })
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 120.0
        }
        if indexPath.section == 0 && indexPath.row == 3 {
            return 62.0
        }
        return 48.0
    }
}

private final class AyuGramCustomizationControllerNode: ASDisplayNode {
    let tableView: UITableView
    private let tableNode: ASDisplayNode
    private let dataSource: AyuGramCustomizationDataSource

    init(theme: PresentationTheme, previewText: String) {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.dataSource = AyuGramCustomizationDataSource(theme: theme, previewText: previewText)

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
    }

    func containerLayoutUpdated(layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.tableNode, frame: CGRect(origin: CGPoint(), size: layout.size))

        self.tableView.contentInset = UIEdgeInsets(top: navigationBarHeight, left: 0.0, bottom: layout.intrinsicInsets.bottom, right: 0.0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
    }
}

public final class AyuGramCustomizationController: ViewController {
    private var presentationData: PresentationData

    private var controllerNode: AyuGramCustomizationControllerNode {
        return self.displayNode as! AyuGramCustomizationControllerNode
    }

    public init(context: AccountContext) {
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = "Customization"
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadDisplayNode() {
        self.displayNode = AyuGramCustomizationControllerNode(theme: self.presentationData.theme, previewText: "Это сообщение было удалено, но всё ещё видно.")
        self.displayNodeDidLoad()
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.controllerNode.containerLayoutUpdated(layout: layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }
}

public func ayuGramCustomizationController(context: AccountContext) -> ViewController {
    return AyuGramCustomizationController(context: context)
}
