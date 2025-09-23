import React, { useEffect } from 'react';
import {
  FlatList,
  View,
  TouchableOpacity,
  Text,
  SafeAreaView,
  ActivityIndicator,
} from 'react-native';
import { observer } from 'mobx-react-lite';
import { PhotoItem } from '../../stores/PhotoGalleryStore';
import { PhotoCardView } from './components';
import { styles } from './PhotoGalleryPage.styles';

interface PhotoGalleryConfig {
  numColumns?: number;
  onEndReachedThreshold?: number;
}

interface PhotoGalleryProps {
  photos: PhotoItem[];
  isLoading: boolean;
  loadingStatus: string;
  hasError: boolean;
  errorMessage: string;
  hasPermission: boolean;
  onPhotoPress: (photo: PhotoItem) => void;
  onToggleFavorite: (photo: PhotoItem) => void;
  onLoadMore: () => void;
  onRequestPermission?: () => void;
  onRetry?: () => void;
  isFavorite: (assetId: string) => boolean;
  isPhotoLoading: (assetId: string) => boolean;
}

const DEFAULT_CONFIG: PhotoGalleryConfig = {
  numColumns: 3,
  onEndReachedThreshold: 0.5,
};

export const createPhotoGalleryPage = (config: PhotoGalleryConfig = DEFAULT_CONFIG) => {
  const {
    numColumns = DEFAULT_CONFIG.numColumns,
    onEndReachedThreshold = DEFAULT_CONFIG.onEndReachedThreshold,
  } = config;

  return observer((props: PhotoGalleryProps) => {
    const {
      photos,
      isLoading,
      loadingStatus,
      hasError,
      errorMessage,
      hasPermission,
      onPhotoPress,
      onToggleFavorite,
      onLoadMore,
      onRequestPermission,
      onRetry,
      isFavorite,
      isPhotoLoading,
    } = props;

    // Call loadMorePhotos when component appears
    useEffect(() => {
      onLoadMore();
    }, []);

    // Handle scroll events to load more photos - aggressive loading
    const handleScroll = () => {
      onLoadMore();
    };

    const renderCardView = ({ item: photo }: { item: PhotoItem }) => (
      <PhotoCardView
        photo={photo}
        isFavorite={isFavorite(photo.assetId)}
        isLoading={isPhotoLoading(photo.assetId)}
        onPress={() => onPhotoPress(photo)}
        onToggleFavorite={() => onToggleFavorite(photo)}
      />
    );

    const renderFooter = () => {
      if (!isLoading || photos.length === 0) {
        return null;
      }
      return (
        <View style={styles.footer}>
          <Text style={styles.loadingText}>Loading more photos...</Text>
        </View>
      );
    };

    const renderEmptyState = () => {
      if (!hasPermission) {
        return (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>Photo access is required to view your gallery</Text>
            <TouchableOpacity style={styles.permissionButton} onPress={onRequestPermission}>
              <Text style={styles.buttonText}>Grant Permission</Text>
            </TouchableOpacity>
          </View>
        );
      }

      if (hasError) {
        return (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>Failed to load photos: {errorMessage}</Text>
            <TouchableOpacity style={styles.retryButton} onPress={onRetry}>
              <Text style={styles.buttonText}>Retry</Text>
            </TouchableOpacity>
          </View>
        );
      }

      return (
        <View style={styles.emptyState}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.emptyText}>{loadingStatus}</Text>
        </View>
      );
    };

    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.title}>Photo Gallery</Text>
          <Text style={styles.subtitle}>{loadingStatus}</Text>
        </View>

        {photos.length === 0 ? (
          renderEmptyState()
        ) : (
          <FlatList
            data={photos}
            renderItem={renderCardView}
            numColumns={numColumns}
            onEndReached={onLoadMore}
            onEndReachedThreshold={onEndReachedThreshold}
            onScroll={handleScroll}
            scrollEventThrottle={16}
            keyExtractor={(item) => item.assetId}
            ListFooterComponent={renderFooter}
            contentContainerStyle={styles.listContent}
          />
        )}
      </SafeAreaView>
    );
  };
};