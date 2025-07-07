import { createTheme } from '@mui/material/styles';

const lightTheme = createTheme({
  palette: {
    mode: 'light',
    primary: { 
      main: '#0A192F',
      contrastText: '#ffffff'
    },
    secondary: { 
      main: '#2196F3',
      contrastText: '#ffffff'
    },
    background: { default: '#fff', paper: '#f5f5f5' },
    text: { primary: '#171717', secondary: '#2196F3' },
  },
  typography: {
    fontFamily: 'SF Pro Display, Arial, Helvetica, sans-serif',
  },
});

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
    primary: { 
      main: '#2196F3',
      contrastText: '#ffffff'
    },
    secondary: { 
      main: '#FFC107',
      contrastText: '#000000'
    },
    background: { default: '#0A192F', paper: '#171717' },
    text: { primary: '#ededed', secondary: '#FFC107' },
  },
  typography: {
    fontFamily: 'SF Pro Display, Arial, Helvetica, sans-serif',
  },
});

export { lightTheme, darkTheme }; 