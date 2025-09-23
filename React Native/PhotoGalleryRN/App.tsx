import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import PhotoGalleryPage from './src/pages/PhotoGalleryPage';
import PhotoDetailsPage from './src/pages/PhotoDetailsPage';

const Stack = createStackNavigator();

function App(): React.JSX.Element {
  return (
    <NavigationContainer>
      <Stack.Navigator 
        initialRouteName="PhotoGallery"
        screenOptions={{
          headerShown: false,
        }}
      >
        <Stack.Screen 
          name="PhotoGallery" 
          component={PhotoGalleryPage} 
        />
        <Stack.Screen 
          name="PhotoDetails" 
          component={PhotoDetailsPage}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default App;