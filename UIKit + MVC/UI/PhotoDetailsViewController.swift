import Photos
import UIKit

final class PhotoDetailsViewController: UIViewController {

  static let favoritingService = FavoritingService.shared
  static let photosService = PhotosService.shared

  private let photo: PhotoItem

  private let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .systemBackground
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private let favoriteButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "heart"), for: .normal)
    button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
    button.tintColor = .systemRed
    button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
    button.layer.cornerRadius = 25
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowRadius = 4
    button.layer.shadowOpacity = 0.3
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = true
    return indicator
  }()

  private let errorLabel: UILabel = {
    let label = UILabel()
    label.text = "Failed to load photo"
    label.textAlignment = .center
    label.textColor = .systemRed
    label.font = UIFont.systemFont(ofSize: 16)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isHidden = true
    return label
  }()

  init(photo: PhotoItem) {
    self.photo = photo
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupNavigationBar()
    loadFullImage()
    updateFavoriteButton()
  }

  private func setupUI() {
    view.backgroundColor = .systemBackground

    view.addSubview(scrollView)
    scrollView.addSubview(imageView)
    view.addSubview(favoriteButton)
    view.addSubview(loadingIndicator)
    view.addSubview(errorLabel)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

      favoriteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      favoriteButton.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      favoriteButton.widthAnchor.constraint(equalToConstant: 50),
      favoriteButton.heightAnchor.constraint(equalToConstant: 50),

      loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

      errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])

    favoriteButton.addAction(
      UIAction { [weak self] _ in
        self?.handleFavoriteButtonTap()
      }, for: .touchUpInside)
  }

  private func setupNavigationBar() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      primaryAction: UIAction { [weak self] _ in
        self?.handleCloseButtonTap()
      }
    )
  }

  private func loadFullImage() {
    loadingIndicator.startAnimating()

    Self.photosService.fetchFullImage(for: photo.asset) { [weak self] result in
      self?.loadingIndicator.stopAnimating()

      switch result {
      case .success(let image):
        self?.imageView.image = image
      case .failure(_):
        self?.showErrorUI()
      }
    }
  }

  private func updateFavoriteButton() {
    favoriteButton.isSelected = photo.isFavorite
  }

  private func showErrorUI() {
    errorLabel.isHidden = false
    imageView.isHidden = true
    favoriteButton.isHidden = true
  }

  private func handleFavoriteButtonTap() {
    updateFavoriteButton()
    photo.toggleFavorite()
  }

  private func handleCloseButtonTap() {
    dismiss(animated: true)
  }
}
