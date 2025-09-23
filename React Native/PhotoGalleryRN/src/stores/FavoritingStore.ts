import { makeAutoObservable } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';

class FavoritingStore {
  private favorites = new Set<string>();
  private readonly STORAGE_KEY = 'photo_favorites';

  constructor() {
    makeAutoObservable(this);
    this.loadFavorites();
  }

  private async loadFavorites() {
    try {
      const storedFavorites = await AsyncStorage.getItem(this.STORAGE_KEY);
      if (storedFavorites) {
        const favoritesArray = JSON.parse(storedFavorites);
        this.favorites = new Set(favoritesArray);
      }
    } catch (error) {
      console.error('Failed to load favorites:', error);
    }
  }

  private async saveFavorites() {
    try {
      const favoritesArray = Array.from(this.favorites);
      await AsyncStorage.setItem(this.STORAGE_KEY, JSON.stringify(favoritesArray));
    } catch (error) {
      console.error('Failed to save favorites:', error);
    }
  }

  isFavorite(assetId: string): boolean {
    return this.favorites.has(assetId);
  }

  async toggleFavorite(assetId: string) {
    if (this.favorites.has(assetId)) {
      this.favorites.delete(assetId);
    } else {
      this.favorites.add(assetId);
    }
    await this.saveFavorites();
  }

  async addFavorite(assetId: string) {
    this.favorites.add(assetId);
    await this.saveFavorites();
  }

  async removeFavorite(assetId: string) {
    this.favorites.delete(assetId);
    await this.saveFavorites();
  }

  get favoriteIds(): string[] {
    return Array.from(this.favorites);
  }

  get favoriteCount(): number {
    return this.favorites.size;
  }
}

export const favoritingStore = new FavoritingStore();