import React, { useEffect } from 'react';
import { observer } from 'mobx-react-lite';
import { photoGalleryStore, PhotoItem } from '../../stores/PhotoGalleryStore';
import { favoritingStore } from '../../stores/FavoritingStore';
import { useNavigation } from '@react-navigation/native';
import { createPhotoGalleryPage } from './createPhotoGalleryPage';

const PhotoGalleryComponent = createPhotoGalleryPage({
  numColumns: 3,
  onEndReachedThreshold: 0.5,
});

const PhotoGalleryPage = observer(() => {
  const navigation = useNavigation();

  const handlePhotoPress = (photo: PhotoItem) => {
    navigation.navigate('PhotoDetails' as never, { photo } as never);
  };

  const handleLoadMore = () => {
    photoGalleryStore.loadMorePhotos();
  };

  const handleRequestPermission = () => {
    photoGalleryStore.requestPermission();
  };

  const handleRetry = () => {
    photoGalleryStore.retry();
  };

  const handleToggleFavorite = (photo: PhotoItem) => {
    favoritingStore.toggleFavorite(photo.assetId);
  };

  const isFavorite = (assetId: string) => {
    return favoritingStore.isFavorite(assetId);
  };

  const isPhotoLoading = (assetId: string) => {
    return photoGalleryStore.isPhotoLoading(assetId);
  };

  return (
    <PhotoGalleryComponent
      photos= { photoGalleryStore.photos }
  isLoading = { photoGalleryStore.isLoading }
  loadingStatus = { photoGalleryStore.loadingStatus }
  hasError = { photoGalleryStore.hasError }
  errorMessage = { photoGalleryStore.errorMessage }
  hasPermission = { photoGalleryStore.hasPermission }
  onPhotoPress = { handlePhotoPress }
  onToggleFavorite = { handleToggleFavorite }
  onLoadMore = { handleLoadMore }
  onRequestPermission = { handleRequestPermission }
  onRetry = { handleRetry }
  isFavorite = { isFavorite }
  isPhotoLoading = { isPhotoLoading }
    />
  );
});

export default PhotoGalleryPage;