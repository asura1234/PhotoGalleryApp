import { StyleSheet } from 'react-native';

export const styles = StyleSheet.create({
    container: {
        flex: 1,
        margin: 1,
        maxWidth: '33.33%',
    },
    imageContainer: {
        position: 'relative',
        aspectRatio: 1,
    },
    thumbnail: {
        width: '100%',
        height: '100%',
        borderRadius: 4,
    },
    loadingContainer: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: 'rgba(0, 0, 0, 0.3)',
        borderRadius: 4,
    },
    errorContainer: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: 'rgba(255, 0, 0, 0.3)',
        borderRadius: 4,
    },
    errorText: {
        color: '#fff',
        fontSize: 20,
        fontWeight: 'bold',
    },
    heartIcon: {
        color: '#fff',
        fontWeight: 'bold',
    },
    heartActive: {
        color: '#ff4444',
    },
});