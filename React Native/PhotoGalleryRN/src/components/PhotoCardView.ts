import { PhotoItem } from '../stores/PhotoGalleryStore';

export interface CardViewConfig {
    showFavoriteButton?: boolean;
    showLoadingSpinner?: boolean;
    heartSize?: number;
    heartPosition?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left';
}

export interface CardViewProps {
    photo: PhotoItem;
    isFavorite: boolean;
    isLoading?: boolean;
    onPress: () => void;
    onToggleFavorite: () => void;
}

export const DEFAULT_CONFIG: CardViewConfig = {
    showFavoriteButton: true,
    showLoadingSpinner: true,
    heartSize: 16,
    heartPosition: 'top-right',
};

export const getHeartPositionStyle = (heartPosition: CardViewConfig['heartPosition']) => {
    const baseStyle = {
        position: 'absolute' as const,
        width: 32,
        height: 32,
        backgroundColor: 'rgba(0, 0, 0, 0.6)',
        borderRadius: 16,
        justifyContent: 'center' as const,
        alignItems: 'center' as const,
        shadowColor: '#000',
        shadowOffset: {
            width: 0,
            height: 2,
        },
        shadowOpacity: 0.25,
        shadowRadius: 3.84,
        elevation: 5,
    };

    switch (heartPosition) {
        case 'top-left':
            return { ...baseStyle, top: 8, left: 8 };
        case 'bottom-right':
            return { ...baseStyle, bottom: 8, right: 8 };
        case 'bottom-left':
            return { ...baseStyle, bottom: 8, left: 8 };
        case 'top-right':
        default:
            return { ...baseStyle, top: 8, right: 8 };
    }
};