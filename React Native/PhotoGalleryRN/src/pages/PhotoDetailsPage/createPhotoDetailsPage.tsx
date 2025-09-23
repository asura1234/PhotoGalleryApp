import React, { useState, useEffect } from 'react';
import {
  View,
  Image,
  TouchableOpacity,
  SafeAreaView,
  Text,
  ActivityIndicator,
} from 'react-native';
import { observer } from 'mobx-react-lite';
import { PhotoItem, photoGalleryStore } from '../../stores/PhotoGalleryStore';
import { styles } from './PhotoDetailsPage.styles';

interface PhotoDetailsConfig {
  showMetadata?: boolean;
  showFavoriteButton?: boolean;
  showBackButton?: boolean;
  imageResizeMode?: 'contain' | 'cover' | 'stretch' | 'center';
}

interface PhotoDetailsProps {
  photo: PhotoItem;
  isFavorite: boolean;
  onToggleFavorite: () => void;
  onGoBack: () => void;
}

const DEFAULT_CONFIG: PhotoDetailsConfig = {
  showMetadata: true,
  showFavoriteButton: true,
  showBackButton: true,
  imageResizeMode: 'contain',
};

export const createPhotoDetailsPage = (config: PhotoDetailsConfig = DEFAULT_CONFIG) => {
  const {
    showMetadata = DEFAULT_CONFIG.showMetadata,
    showFavoriteButton = DEFAULT_CONFIG.showFavoriteButton,
    showBackButton = DEFAULT_CONFIG.showBackButton,
    imageResizeMode = DEFAULT_CONFIG.imageResizeMode,
  } = config;

  return observer((props: PhotoDetailsProps) => {
    const { photo, isFavorite, onToggleFavorite, onGoBack } = props;

    // Use centralized error and loading state from store
    const imageLoading = photoGalleryStore.isPhotoLoading(photo.assetId);
    const imageError = photoGalleryStore.hasImageError(photo.assetId);

    const handleImageLoad = () => {
      photoGalleryStore.setImageLoading(photo.assetId, false);
    };

    const handleImageError = () => {
      photoGalleryStore.setImageError(photo.assetId, true);
      photoGalleryStore.setImageLoading(photo.assetId, false);
    };

    // Set initial loading state when component mounts
    useEffect(() => {
      if (!imageLoading && !imageError) {
        photoGalleryStore.setImageLoading(photo.assetId, true);
      }
    }, [photo.assetId]);

    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          {showBackButton && (
            <TouchableOpacity style={styles.backButton} onPress={onGoBack}>
              <Text style={styles.buttonText}>←</Text>
            </TouchableOpacity>
          )}

          {showFavoriteButton && (
            <TouchableOpacity style={styles.favoriteButton} onPress={onToggleFavorite}>
              <Text style={[styles.buttonText, isFavorite && styles.favoriteActive]}>
                {isFavorite ? '♥' : '♡'}
              </Text>
            </TouchableOpacity>
          )}
        </View>

        <View style={styles.imageContainer}>
          {imageLoading && (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color="#007AFF" />
              <Text style={styles.loadingText}>Loading image...</Text>
            </View>
          )}

          {imageError ? (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>Failed to load image</Text>
            </View>
          ) : (
            <Image
              source={{ uri: photo.image_url }}
              style={styles.fullImage}
              resizeMode={imageResizeMode}
              onLoad={handleImageLoad}
              onError={handleImageError}
            />
          )}
        </View>

        {showMetadata && (
          <View style={styles.metadata}>
            <Text style={styles.metadataTitle}>Photo Details</Text>
            <Text style={styles.metadataText}>
              Size: {photo.metadata.width} × {photo.metadata.height}
            </Text>
            <Text style={styles.metadataText}>
              Created: {new Date(photo.metadata.created_date).toLocaleDateString()}
            </Text>
            {photo.metadata.file_size && (
              <Text style={styles.metadataText}>
                File Size: {photo.metadata.file_size}
              </Text>
            )}
            {photo.metadata.location && (
              <Text style={styles.metadataText}>
                Location: {photo.metadata.location}
              </Text>
            )}
          </View>
        )}
      </SafeAreaView>
    );
  };
};