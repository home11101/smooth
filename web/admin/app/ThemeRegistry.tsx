'use client';
import * as React from 'react';
import { ThemeProvider, CssBaseline } from '@mui/material';
import { lightTheme, darkTheme } from '../theme';

const ThemeContext = React.createContext({
  darkMode: false,
  toggleDarkMode: () => {},
});

export function useThemeMode() {
  return React.useContext(ThemeContext);
}

export default function ThemeRegistry({ children }: { children: React.ReactNode }) {
  const [darkMode, setDarkMode] = React.useState(false);

  React.useEffect(() => {
    const stored = localStorage.getItem('darkMode');
    if (stored) setDarkMode(stored === 'true');
  }, []);

  const toggleDarkMode = () => {
    setDarkMode((prev) => {
      localStorage.setItem('darkMode', String(!prev));
      return !prev;
    });
  };

  return (
    <ThemeContext.Provider value={{ darkMode, toggleDarkMode }}>
      <ThemeProvider theme={darkMode ? darkTheme : lightTheme}>
        <CssBaseline />
        {children}
      </ThemeProvider>
    </ThemeContext.Provider>
  );
} 