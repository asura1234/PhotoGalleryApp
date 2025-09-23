import React, { useState, useEffect } from 'react';
import {
    View,
    Image,
    TouchableOpacity,
    Text,
    ActivityIndicator,
} from 'react-native';
import { observer } from 'mobx-react-lite';
import { CardViewConfig, CardViewProps, DEFAULT_CONFIG, getHeartPositionStyle } from './PhotoCardView';
import { styles } from './PhotoCardView.styles';
import { photoGalleryStore } from '../../stores/PhotoGalleryStore';

export const createPhotoCardView = (config: CardViewConfig = DEFAULT_CONFIG) => {
    const {
        showFavoriteButton = DEFAULT_CONFIG.showFavoriteButton,
        showLoadingSpinner = DEFAULT_CONFIG.showLoadingSpinner,
        heartSize = DEFAULT_CONFIG.heartSize,
        heartPosition = DEFAULT_CONFIG.heartPosition,
    } = config;

    return observer((props: CardViewProps) => {
        const { photo, isFavorite, isLoading = false, onPress, onToggleFavorite } = props;

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
            <TouchableOpacity style={styles.container} onPress={onPress}>
                <View style={styles.imageContainer}>
                    <Image
                        source={{ uri: photo.thumbnail_url }}
                        style={styles.thumbnail}
                        resizeMode="cover"
                        onLoad={handleImageLoad}
                        onError={handleImageError}
                    />

                    {/* Loading spinner for individual card */}
                    {(isLoading || imageLoading) && showLoadingSpinner && (
                        <View style={styles.loadingContainer}>
                            <ActivityIndicator size="small" color="#007AFF" />
                        </View>
                    )}

                    {/* Error state */}
                    {imageError && (
                        <View style={styles.errorContainer}>
                            <Text style={styles.errorText}>!</Text>
                        </View>
                    )}

                    {/* Favorite button */}
                    {showFavoriteButton && (
                        <TouchableOpacity
                            style={getHeartPositionStyle(heartPosition)}
                            onPress={onToggleFavorite}
                            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                        >
                            <Text style={[styles.heartIcon, { fontSize: heartSize }, isFavorite && styles.heartActive]}>
                                {isFavorite ? '♥' : '♡'}
                            </Text>
                        </TouchableOpacity>
                    )}
                </View>
            </TouchableOpacity>
        );
    };
};


// Create the default PhotoCardView component
const PhotoCardViewComponent = createPhotoCardView({
    showFavoriteButton: true,
    showLoadingSpinner: true,
    heartSize: 16,
    heartPosition: 'top-right',
});

export const PhotoCardView: React.FC<CardViewProps> = (props) => {
    return <PhotoCardViewComponent {...props} />;
};