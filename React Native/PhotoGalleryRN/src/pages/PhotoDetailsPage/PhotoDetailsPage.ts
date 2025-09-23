import React from 'react';
import { observer } from 'mobx-react-lite';
import { useNavigation, useRoute } from '@react-navigation/native';
import { favoritingStore } from '../../stores/FavoritingStore';
import { PhotoItem } from '../../stores/PhotoGalleryStore';
import { createPhotoDetailsPage } from './createPhotoDetailsPage';

interface PhotoDetailsRouteParams {
  photo: PhotoItem;
}

const PhotoDetailsComponent = createPhotoDetailsPage({
  showMetadata: true,
  showFavoriteButton: true,
  showBackButton: true,
  imageResizeMode: 'contain',
});

const PhotoDetailsPage = observer(() => {
  const navigation = useNavigation();
  const route = useRoute();
  const { photo } = route.params as PhotoDetailsRouteParams;

  const isFavorite = favoritingStore.isFavorite(photo.assetId);

  const handleToggleFavorite = () => {
    favoritingStore.toggleFavorite(photo.assetId);
  };

  const handleGoBack = () => {
    navigation.goBack();
  };

  return (
    <PhotoDetailsComponent
      photo= { photo }
  isFavorite = { isFavorite }
  onToggleFavorite = { handleToggleFavorite }
  onGoBack = { handleGoBack }
    />
  );
});

export default PhotoDetailsPage;