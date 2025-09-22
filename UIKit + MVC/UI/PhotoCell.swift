import UIKit

final class PhotoCell: UICollectionViewCell {
  static let identifier = "PhotoCell"

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.backgroundColor = .systemGray5
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private let favoriteIcon: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "heart.fill")
    imageView.tintColor = .systemRed
    imageView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    imageView.layer.cornerRadius = 12
    imageView.contentMode = .center
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.isHidden = true
    return imageView
  }()

  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = true
    return indicator
  }()

  private let errorPlaceholder: UILabel = {
    let label = UILabel()
    label.text = "⚠️"
    label.font = UIFont.systemFont(ofSize: 32)
    label.textAlignment = .center
    label.backgroundColor = .systemGray5
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isHidden = true
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    contentView.addSubview(imageView)
    contentView.addSubview(favoriteIcon)
    contentView.addSubview(loadingIndicator)
    contentView.addSubview(errorPlaceholder)

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      favoriteIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
      favoriteIcon.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
      favoriteIcon.widthAnchor.constraint(equalToConstant: 24),
      favoriteIcon.heightAnchor.constraint(equalToConstant: 24),

      loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

      errorPlaceholder.topAnchor.constraint(equalTo: contentView.topAnchor),
      errorPlaceholder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      errorPlaceholder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      errorPlaceholder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  func configure(with photo: PhotoItem) {
    if photo.loadFailed {
      imageView.isHidden = true
      errorPlaceholder.isHidden = false
      loadingIndicator.stopAnimating()
    } else if let thumbnail = photo.thumbnail {
      imageView.isHidden = false
      imageView.image = thumbnail
      errorPlaceholder.isHidden = true
      loadingIndicator.stopAnimating()
    } else {
      imageView.isHidden = false
      imageView.image = nil
      errorPlaceholder.isHidden = true
      loadingIndicator.startAnimating()
    }

    favoriteIcon.isHidden = !photo.isFavorite
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    imageView.isHidden = false
    favoriteIcon.isHidden = true
    errorPlaceholder.isHidden = true
    loadingIndicator.stopAnimating()
  }
}
