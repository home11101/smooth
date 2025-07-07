import CircularProgress from '@mui/material/CircularProgress';
import Box from '@mui/material/Box';

export default function Loader() {
  return (
    <Box display="flex" alignItems="center" justifyContent="center" minHeight="200px" aria-busy="true" aria-label="Chargement">
      <CircularProgress color="primary" />
    </Box>
  );
} 