import { makeAutoObservable, runInAction } from 'mobx';
import { NativeModules, Image } from 'react-native';

const { PhotosServiceNativeModule, PhotoPermissionsService } = NativeModules;

export interface PhotoMetadata {
  width: number;
  height: number;
  created_date: string;
  file_size?: string;
  location?: string;
}

export interface PhotoItem {
  assetId: string;
  thumbnail_url: string;
  image_url: string;
  metadata: PhotoMetadata;
}

interface PhotosResponse {
  photos: PhotoItem[];
  total_count: number;
  has_more: boolean;
}

class PhotoGalleryStore {
  photos: PhotoItem[] = [];
  isLoading = false;
  loadingStatus = 'Loading photos...';
  hasMore = true;
  hasError = false;
  errorMessage = '';
  hasPermission = false;
  private loadingPhotos = new Set<string>(); // Track which photos are currently loading
  private imageErrors = new Map<string, boolean>(); // Track image loading errors
  private currentOffset = 0;
  private readonly pageSize = 50;
  private readonly maxPhotos = 200; // Sliding window limit

  constructor() {
    makeAutoObservable(this);
    this.checkPermission();
  }

  async checkPermission() {
    try {
      const hasPermission = await PhotoPermissionsService.checkOrRequestPermissionWhenNeeded();
      runInAction(() => {
        this.hasPermission = hasPermission;
        if (hasPermission) {
          this.loadInitialPhotos();
        } else {
          this.loadingStatus = 'Photo access is required';
        }
      });
    } catch (error) {
      runInAction(() => {
        this.hasPermission = false;
        this.hasError = true;
        this.errorMessage = 'Failed to check permissions';
      });
    }
  }

  async requestPermission() {
    await this.checkPermission();
  }

  async loadPhotos() {
    if (this.isLoading || !this.hasPermission) return;

    // Check if we have more photos to load
    if (!this.hasMore || this.photos.length === 0) return;

    runInAction(() => {
      this.isLoading = true;
      this.hasError = false;
      this.errorMessage = '';
    });

    try {
      const response = await this.fetchPhotos(this.currentOffset, this.pageSize);

      runInAction(() => {
        // Load more - append to existing photos
        const newPhotos = [...this.photos, ...response.photos];

        // Implement sliding window - keep only the most recent photos
        if (newPhotos.length > this.maxPhotos) {
          const excess = newPhotos.length - this.maxPhotos;
          this.photos = newPhotos.slice(excess);
        } else {
          this.photos = newPhotos;
        }

        this.currentOffset = this.photos.length;
        this.hasMore = response.has_more;
        this.loadingStatus = `Loaded ${this.photos.length} of ${response.total_count} photos`;
        this.isLoading = false;
      });

      // Preload next batch of images for better performance
      this.preloadImages(response.photos, this.photos.length - response.photos.length);
    } catch (error) {
      runInAction(() => {
        this.hasError = true;
        this.errorMessage = error instanceof Error ? error.message : 'Failed to load photos';
        this.loadingStatus = 'Failed to load photos';
        this.isLoading = false;
      });
      console.error('Failed to load photos:', error);
    }
  }

  async loadInitialPhotos() {
    // Reset state for initial load
    runInAction(() => {
      this.photos = [];
      this.currentOffset = 0;
      this.hasMore = true;
      this.loadingStatus = 'Loading photos...';
    });
    await this.loadPhotos();
  }

  async loadMorePhotos() {
    await this.loadPhotos();
  }

  async retry() {
    await this.loadPhotos();
  }

  private async fetchPhotos(offset: number, limit: number): Promise<PhotosResponse> {
    return await PhotosServiceNativeModule.getPhotos(offset, limit);
  }

  private preloadImages(photos: PhotoItem[], startIndex: number) {
    // Preload thumbnails for the next 10 photos to improve perceived performance
    const nextBatch = photos.slice(0, 10);
    nextBatch.forEach((photo, index) => {
      // Mark photo as loading
      runInAction(() => {
        this.loadingPhotos.add(photo.assetId);
      });

      Image.prefetch(photo.thumbnail_url)
        .then(() => {
          // Mark photo as loaded
          runInAction(() => {
            this.loadingPhotos.delete(photo.assetId);
          });
        })
        .catch(error => {
          console.warn(`Failed to preload image at index ${startIndex + index}:`, error);
          // Mark photo as loaded even if failed
          runInAction(() => {
            this.loadingPhotos.delete(photo.assetId);
          });
        });
    });
  }

  isPhotoLoading(assetId: string): boolean {
    return this.loadingPhotos.has(assetId);
  }

  hasImageError(assetId: string): boolean {
    return this.imageErrors.get(assetId) || false;
  }

  setImageError(assetId: string, hasError: boolean) {
    runInAction(() => {
      this.imageErrors.set(assetId, hasError);
    });
  }

  setImageLoading(assetId: string, isLoading: boolean) {
    runInAction(() => {
      if (isLoading) {
        this.loadingPhotos.add(assetId);
        this.imageErrors.delete(assetId); // Clear error when starting to load
      } else {
        this.loadingPhotos.delete(assetId);
      }
    });
  }
}

export const photoGalleryStore = new PhotoGalleryStore();