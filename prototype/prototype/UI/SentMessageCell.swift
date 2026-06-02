// 仕様: docs/spec/timeline-screen.md#タイムライン表示
import UIKit

final class SentMessageCell: UITableViewCell {
    static let reuseIdentifier = "SentMessageCell"

    private let containerView = UIView()
    private let bubbleView = UIView()
    let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String) {
        messageLabel.text = text
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.backgroundColor = .white
        bubbleView.layer.cornerRadius = 12
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = UIColor.separator.cgColor

        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .black

        containerView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(containerView)
        containerView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        let padding = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 64),

            bubbleView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bubbleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bubbleView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: padding.top),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -padding.bottom),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: padding.left),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -padding.right),
        ])
    }
}
