//
//  CompletionPopupView.swift
//  minip
//

import Runestone
import UIKit

protocol CompletionPopupDelegate: AnyObject {
    func completionPopup(_ popup: CompletionPopupView, didSelectItem item: LSPCompletionItem)
}

class CompletionPopupView: UIView {
    weak var delegate: CompletionPopupDelegate?

    private let tableView = UITableView()
    private var allItems: [LSPCompletionItem] = []
    private var filteredItems: [LSPCompletionItem] = []
    private var selectedIndex: Int = 0
    private var filterText: String = ""

    private static let maxVisibleRows = 6
    private static let rowHeight: CGFloat = 32
    private static let popupWidth: CGFloat = 280

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
        clipsToBounds = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = Self.rowHeight
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(CompletionCell.self, forCellReuseIdentifier: "CompletionCell")
        tableView.layer.cornerRadius = 8
        tableView.clipsToBounds = true
        tableView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private var currentKeyboardHeight: CGFloat = 0

    func show(items: [LSPCompletionItem], in parentView: UIView, at cursorRect: CGRect, keyboardHeight: CGFloat = 0, initialFilter: String = "") {
        guard !items.isEmpty else {
            hide()
            return
        }

        allItems = items
        filterText = initialFilter
        currentKeyboardHeight = keyboardHeight
        applyFilter()

        guard !filteredItems.isEmpty else {
            hide()
            return
        }

        if superview == nil {
            parentView.addSubview(self)
        }

        tableView.contentOffset = .zero
        positionPopup(relativeTo: cursorRect, in: parentView)
        isHidden = false
    }

    func reposition(relativeTo cursorRect: CGRect, in parentView: UIView, keyboardHeight: CGFloat = 0) {
        currentKeyboardHeight = keyboardHeight
        positionPopup(relativeTo: cursorRect, in: parentView)
    }

    func updateFilter(_ text: String) {
        filterText = text
        applyFilter()

        if filteredItems.isEmpty {
            hide()
        } else {
            tableView.reloadData()
            selectRow(at: 0)
            // Don't call updateHeight here — let repositionCompletionPopup handle it
        }
    }

    func hide() {
        isHidden = true
        removeFromSuperview()
        allItems = []
        filteredItems = []
        selectedIndex = 0
    }

    var isVisible: Bool { !isHidden && superview != nil }

    // MARK: - Keyboard Navigation

    func selectPrevious() {
        guard !filteredItems.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + filteredItems.count) % filteredItems.count
        selectRow(at: selectedIndex)
    }

    func selectNext() {
        guard !filteredItems.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % filteredItems.count
        selectRow(at: selectedIndex)
    }

    func confirmSelection() -> LSPCompletionItem? {
        guard !filteredItems.isEmpty, selectedIndex < filteredItems.count else { return nil }
        return filteredItems[selectedIndex]
    }

    // MARK: - Private

    private func applyFilter() {
        if filterText.isEmpty {
            // Respect LS sortText order
            filteredItems = allItems.sorted { a, b in
                let aSort = a.sortText ?? a.label
                let bSort = b.sortText ?? b.label
                return aSort < bSort
            }
        } else {
            let lower = filterText.lowercased()
            filteredItems = allItems
                .filter { item in
                    let label = (item.filterText ?? item.label).lowercased()
                    return label.contains(lower)
                }
                .sorted { a, b in
                    let aLabel = (a.filterText ?? a.label).lowercased()
                    let bLabel = (b.filterText ?? b.label).lowercased()
                    let aExact = aLabel == lower
                    let bExact = bLabel == lower
                    if aExact != bExact { return aExact }
                    let aPrefix = aLabel.hasPrefix(lower)
                    let bPrefix = bLabel.hasPrefix(lower)
                    if aPrefix != bPrefix { return aPrefix }
                    return aLabel.count < bLabel.count
                }
        }
        selectedIndex = 0
        tableView.reloadData()
        updateHeight()
        if !filteredItems.isEmpty {
            selectRow(at: 0)
        }
    }

    private func selectRow(at index: Int) {
        guard index < filteredItems.count else { return }
        selectedIndex = index
        let indexPath = IndexPath(row: index, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView.scrollToRow(at: indexPath, at: .none, animated: false)
    }

    private func positionPopup(relativeTo cursorRect: CGRect, in parentView: UIView) {
        let visibleRows = min(filteredItems.count, Self.maxVisibleRows)
        let height = CGFloat(visibleRows) * Self.rowHeight
        let width = Self.popupWidth

        // Visible bottom = parent height minus keyboard
        let visibleBottom = parentView.bounds.maxY - currentKeyboardHeight

        var x = cursorRect.origin.x
        var y = cursorRect.maxY + 4

        // Keep within parent bounds horizontally
        if x + width > parentView.bounds.maxX - 8 {
            x = parentView.bounds.maxX - width - 8
        }
        x = max(8, x)

        // If not enough space below keyboard, try above cursor
        if y + height > visibleBottom - 8 {
            let aboveY = cursorRect.origin.y - height - 4
            if aboveY >= parentView.safeAreaInsets.top {
                y = aboveY
            }
            // Otherwise keep below — better to overlap keyboard than cover cursor
        }

        frame = CGRect(x: x, y: y, width: width, height: height)
    }

    private func updateHeight() {
        let visibleRows = min(filteredItems.count, Self.maxVisibleRows)
        let height = CGFloat(visibleRows) * Self.rowHeight
        frame.size.height = height
    }
}

// MARK: - UITableViewDataSource & Delegate

extension CompletionPopupView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletionCell", for: indexPath) as! CompletionCell
        let item = filteredItems[indexPath.row]
        cell.configure(with: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = filteredItems[indexPath.row]
        delegate?.completionPopup(self, didSelectItem: item)
    }
}

// MARK: - CompletionCell

private class CompletionCell: UITableViewCell {
    private let kindBadge = KindBadgeView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .clear
        let selView = UIView()
        selView.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        selectedBackgroundView = selView

        kindBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(kindBadge)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .tertiaryLabel
        detailLabel.textAlignment = .right
        contentView.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            kindBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            kindBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            kindBadge.widthAnchor.constraint(equalToConstant: 18),
            kindBadge.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(equalTo: kindBadge.trailingAnchor, constant: 6),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -4),

            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
        ])
    }

    func configure(with item: LSPCompletionItem) {
        titleLabel.text = item.displayLabel
        detailLabel.text = item.detail
        let info = KindBadgeView.kindInfo(for: item.kind)
        kindBadge.configure(letter: info.letter, color: info.color)
    }
}

// MARK: - VS Code Style Kind Badge

private class KindBadgeView: UIView {
    private let letterLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 3
        clipsToBounds = true

        letterLabel.translatesAutoresizingMaskIntoConstraints = false
        letterLabel.font = .systemFont(ofSize: 10, weight: .bold)
        letterLabel.textColor = .white
        letterLabel.textAlignment = .center
        addSubview(letterLabel)

        NSLayoutConstraint.activate([
            letterLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            letterLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(letter: String, color: UIColor) {
        letterLabel.text = letter
        backgroundColor = color
    }

    /// VS Code completion item kind → (letter, color)
    static func kindInfo(for kind: Int?) -> (letter: String, color: UIColor) {
        guard let kind else { return ("T", .systemGray) }
        switch kind {
        case 1:  return ("W", .systemGray)             // Text
        case 2:  return ("M", UIColor(red: 0.51, green: 0.37, blue: 0.80, alpha: 1)) // Method - purple
        case 3:  return ("F", UIColor(red: 0.51, green: 0.37, blue: 0.80, alpha: 1)) // Function - purple
        case 4:  return ("C", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Constructor - orange
        case 5:  return ("F", UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)) // Field - blue
        case 6:  return ("V", UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)) // Variable - blue
        case 7:  return ("C", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Class - orange
        case 8:  return ("I", UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)) // Interface - blue
        case 9:  return ("M", .systemGray)             // Module
        case 10: return ("P", UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)) // Property - blue
        case 11: return ("U", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Unit - orange
        case 12: return ("V", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Value - orange
        case 13: return ("E", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Enum - orange
        case 14: return ("K", UIColor(red: 0.51, green: 0.37, blue: 0.80, alpha: 1)) // Keyword - purple
        case 15: return ("S", .systemGray)             // Snippet
        case 16: return ("C", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Color - orange
        case 17: return ("F", .systemGray)             // File
        case 18: return ("R", .systemGray)             // Reference
        case 19: return ("D", .systemGray)             // Folder
        case 20: return ("E", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // EnumMember - orange
        case 21: return ("C", UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)) // Constant - blue
        case 22: return ("S", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Struct - orange
        case 23: return ("E", UIColor(red: 0.86, green: 0.56, blue: 0.20, alpha: 1)) // Event - orange
        case 24: return ("O", .systemGray)             // Operator
        case 25: return ("T", UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)) // TypeParameter - blue
        default: return ("T", .systemGray)
        }
    }
}
