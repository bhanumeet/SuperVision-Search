//
//  InfoViewController.swift
//  VisionExample
//
//  Created by Luo Lab on 1/14/25.
//  © 2025 Google Inc. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    // Cancel button to dismiss info screen
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("cancel_button", comment: "Title for the Cancel button"), for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.accessibilityLabel = NSLocalizedString("cancel_button_accessibility", comment: "Accessibility label for the Cancel button")
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupScrollView()
        setupContent()
        setupCancelButton()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentView.axis = .vertical
        contentView.spacing = 16
        contentView.alignment = .leading
        contentView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    private func setupContent() {
        // Define icon names and info texts
        let items: [(icon: String, titleKey: String, descriptionKey: String)] = [
            ("camera", "camera_title", "camera_description"),
            ("scan", "scan_title", "scan_description"),
            ("zoomIn", "zoom_title", "zoom_description"),
            ("return", "return_title", "return_description"),
            ("next", "next_title", "next_description"),
            ("pre", "previous_title", "previous_description"),
            ("torch", "torch_title", "torch_description"),
            ("microphone", "speak_title", "speak_description")
        ]

        for item in items {
            let container = createInfoRow(iconName: item.icon, titleKey: item.titleKey, descriptionKey: item.descriptionKey)
            contentView.addArrangedSubview(container)
        }
    }

    private func createInfoRow(iconName: String, titleKey: String, descriptionKey: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView()
        imageView.image = UIImage(named: iconName)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.accessibilityLabel = NSLocalizedString("\(titleKey)_accessibility", comment: "Accessibility label for \(titleKey) icon")

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString(titleKey, comment: "Title for \(titleKey) feature")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descriptionLabel = UILabel()
        descriptionLabel.text = NSLocalizedString(descriptionKey, comment: "Description for \(titleKey) feature")
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 44),
            imageView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func setupCancelButton() {
        view.addSubview(cancelButton)
        cancelButton.addTarget(self, action: #selector(dismissInfo), for: .touchUpInside)

        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func dismissInfo() {
        dismiss(animated: true, completion: nil)
    }
}
