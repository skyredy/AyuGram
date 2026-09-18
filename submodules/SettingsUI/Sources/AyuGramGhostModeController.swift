import Foundation
import UIKit
import Display
import AsyncDisplayKit
import AccountContext
import TelegramPresentationData

final class AyuGramSwitchCell: UITableViewCell {
    let switchView: UISwitch
    var onChange: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.switchView = UISwitch()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.accessoryView = self.switchView
        self.switchView.addTarget(self, action: #selector(self.switchValueChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func switchValueChanged() {
        self.onChange?(self.switchView.isOn)
    }
}

private enum AyuGramGhostSubOption: Int, CaseIterable {
    case dontReadMessages
    case dontReadStories
    case dontSendOnline
    case dontSendTyping
    case goOfflineAutomatically

    var title: String {
        switch self {
        case .dontReadMessages:
            return "Не читать сообщения"
        case .dontReadStories:
            return "Не читать сторис"
        case .dontSendOnline:
            return "Не отправлять статус \"онлайн\""
        case .dontSendTyping:
            return "Не отправлять \"печатает...\""
        case .goOfflineAutomatically:
            return "Уходить в оффлайн автоматически"
        }
    }

    var isEnabled: Bool {
        switch self {
        case .dontReadMessages:
            return AyuGramSettings.dontReadMessages
        case .dontReadStories:
            return AyuGramSettings.dontReadStories
        case .dontSendOnline:
            return AyuGramSettings.dontSendOnline
        case .dontSendTyping:
            return AyuGramSettings.dontSendTyping
        case .goOfflineAutomatically:
            return AyuGramSettings.goOfflineAutomatically
        }
    }

    func setEnabled(_ value: Bool) {
        switch self {
        case .dontReadMessages:
            AyuGramSettings.dontReadMessages = value
        case .dontReadStories:
            AyuGramSettings.dontReadStories = value
        case .dontSendOnline:
            AyuGramSettings.dontSendOnline = value
        case .dontSendTyping:
            AyuGramSettings.dontSendTyping = value
        case .goOfflineAutomatically:
            AyuGramSettings.goOfflineAutomatically = value
        }
    }
}

private final class AyuGramGhostModeTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    weak var tableView: UITableView?
    var isEssentialsExpanded: Bool = false
    var presentAlert: ((UIAlertController) -> Void)?

    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.isEssentialsExpanded ? 1 + AyuGramGhostSubOption.allCases.count : 1
        default:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "GHOST ESSENTIALS"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Долгое нажатие на любой пункт закрепляет его значение при переключении режима призрака."
        case 1:
            return "Автоматически читает сообщение при отправке нового или при реакции на сообщение."
        case 2:
            return "Автоматически ставит задержку в ~12 секунд (дольше для сообщений с вложениями) при отправке сообщений. При использовании этой функции вы не будете появляться в сети.\nНе рекомендуется использовать на слабом интернете."
        case 3:
            return "Отправляет сообщения по умолчанию без звука."
        case 4:
            return "Показывает предупреждение перед открытием сторис, предлагая включить режим призрака."
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MasterToggle") as? AyuGramSwitchCell ?? AyuGramSwitchCell(style: .value1, reuseIdentifier: "MasterToggle")
                cell.textLabel?.text = "Режим призрака"
                cell.detailTextLabel?.text = "\(AyuGramSettings.enabledSubOptionsCount)/\(AyuGramGhostSubOption.allCases.count) \(self.isEssentialsExpanded ? "⌃" : "⌄")"
                cell.switchView.isOn = AyuGramSettings.ghostModeEnabled
                cell.onChange = { isOn in
                    AyuGramSettings.ghostModeEnabled = isOn
                }
                return cell
            } else {
                let option = AyuGramGhostSubOption.allCases[indexPath.row - 1]
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubOption") ?? UITableViewCell(style: .default, reuseIdentifier: "SubOption")
                cell.textLabel?.text = option.title
                cell.accessoryType = option.isEnabled ? .checkmark : .none
                return cell
            }
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReadOnInteract") as? AyuGramSwitchCell ?? AyuGramSwitchCell(style: .default, reuseIdentifier: "ReadOnInteract")
            cell.textLabel?.text = "Читать при действиях"
            cell.switchView.isOn = AyuGramSettings.readOnInteract
            cell.onChange = { isOn in
                AyuGramSettings.readOnInteract = isOn
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleMessages") as? AyuGramSwitchCell ?? AyuGramSwitchCell(style: .default, reuseIdentifier: "ScheduleMessages")
            cell.textLabel?.text = "Использовать отложку"
            cell.switchView.isOn = AyuGramSettings.scheduleMessages
            cell.onChange = { isOn in
                AyuGramSettings.scheduleMessages = isOn
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SendWithoutSound") ?? UITableViewCell(style: .value1, reuseIdentifier: "SendWithoutSound")
            cell.textLabel?.text = "Отправлять без звука"
            cell.detailTextLabel?.text = AyuGramSettings.sendWithoutSound.title
            cell.accessoryType = .disclosureIndicator
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestGhostForStories") as? AyuGramSwitchCell ?? AyuGramSwitchCell(style: .default, reuseIdentifier: "SuggestGhostForStories")
            cell.textLabel?.text = "Предлагать призрака для сторис"
            cell.switchView.isOn = AyuGramSettings.suggestGhostForStories
            cell.onChange = { isOn in
                AyuGramSettings.suggestGhostForStories = isOn
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.isEssentialsExpanded.toggle()
                tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            } else {
                let option = AyuGramGhostSubOption.allCases[indexPath.row - 1]
                option.setEnabled(!option.isEnabled)
                tableView.reloadSections(IndexSet(integer: 0), with: .none)
            }
        } else if indexPath.section == 3 {
            self.presentSendWithoutSoundOptions(tableView: tableView, indexPath: indexPath)
        }
    }

    private func presentSendWithoutSoundOptions(tableView: UITableView, indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Отправлять без звука", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: AyuGramSendWithoutSound.never.title, style: .default, handler: { _ in
            AyuGramSettings.sendWithoutSound = .never
            tableView.reloadRows(at: [indexPath], with: .none)
        }))
        alertController.addAction(UIAlertAction(title: AyuGramSendWithoutSound.always.title, style: .default, handler: { _ in
            AyuGramSettings.sendWithoutSound = .always
            tableView.reloadRows(at: [indexPath], with: .none)
        }))
        alertController.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        if let popover = alertController.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }

        self.presentAlert?(alertController)
    }
}

private final class AyuGramGhostModeControllerNode: ASDisplayNode {
    let tableView: UITableView
    private let tableNode: ASDisplayNode
    private let dataSource: AyuGramGhostModeTableDataSource

    init(theme: PresentationTheme, presentAlert: @escaping (UIAlertController) -> Void) {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.dataSource = AyuGramGhostModeTableDataSource()
        self.dataSource.presentAlert = presentAlert

        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)

        super.init()

        self.backgroundColor = theme.list.plainBackgroundColor
        self.addSubnode(self.tableNode)

        self.dataSource.tableView = tableView
        self.tableView.dataSource = self.dataSource
        self.tableView.delegate = self.dataSource
        self.tableView.backgroundColor = theme.list.plainBackgroundColor
        self.tableView.separatorColor = theme.list.itemPlainSeparatorColor
    }

    func containerLayoutUpdated(layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.tableNode, frame: CGRect(origin: CGPoint(), size: layout.size))

        self.tableView.contentInset = UIEdgeInsets(top: navigationBarHeight, left: 0.0, bottom: layout.intrinsicInsets.bottom, right: 0.0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
    }
}

public final class AyuGramGhostModeController: ViewController {
    private var presentationData: PresentationData

    private var controllerNode: AyuGramGhostModeControllerNode {
        return self.displayNode as! AyuGramGhostModeControllerNode
    }

    public init(context: AccountContext) {
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = "Ghost Mode"
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadDisplayNode() {
        self.displayNode = AyuGramGhostModeControllerNode(theme: self.presentationData.theme, presentAlert: { [weak self] alertController in
            self?.present(alertController, animated: true)
        })
        self.displayNodeDidLoad()
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.controllerNode.containerLayoutUpdated(layout: layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }
}

public func ayuGramGhostModeController(context: AccountContext) -> ViewController {
    return AyuGramGhostModeController(context: context)
}
