'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination, TextField, InputAdornment, IconButton, Button, MenuItem, Select } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import DownloadIcon from '@mui/icons-material/Download';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

export default function PaymentsPage() {
  const [payments, setPayments] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [platform, setPlatform] = useState('');
  const [product, setProduct] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchPayments();
  }, []);

  async function fetchPayments() {
    setLoading(true);
    let query = supabase.from('payments').select('*').order('purchase_date', { ascending: false });
    const { data, error } = await query;
    setPayments(data || []);
    setLoading(false);
  }

  function handleSearchChange(e: any) {
    setSearch(e.target.value);
    setPage(0);
  }

  function handlePlatformChange(e: any) {
    setPlatform(e.target.value);
    setPage(0);
  }

  function handleProductChange(e: any) {
    setProduct(e.target.value);
    setPage(0);
  }

  function filterPayments() {
    return payments.filter((p) => {
      const matchesSearch =
        search === '' ||
        p.device_id?.toLowerCase().includes(search.toLowerCase()) ||
        p.product_id?.toLowerCase().includes(search.toLowerCase()) ||
        p.status?.toLowerCase().includes(search.toLowerCase());
      const matchesPlatform = platform === '' || p.platform === platform;
      const matchesProduct = product === '' || p.product_id === product;
      return matchesSearch && matchesPlatform && matchesProduct;
    });
  }

  function handleChangePage(event: unknown, newPage: number) {
    setPage(newPage);
  }

  function handleChangeRowsPerPage(event: React.ChangeEvent<HTMLInputElement>) {
    setRowsPerPage(+event.target.value);
    setPage(0);
  }

  function exportCSV() {
    const rows = filterPayments();
    const header = ['Device ID', 'Produit', 'Montant', 'Date', 'Plateforme', 'Statut', 'Reçu'];
    const csv = [header.join(',')].concat(
      rows.map((p) => [
        p.device_id,
        p.product_id,
        p.amount,
        p.purchase_date,
        p.platform,
        p.status,
        p.receipt ? 'Oui' : 'Non',
      ].map(x => '"' + (x ?? '') + '"').join(','))
    ).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'paiements.csv';
    a.click();
    window.URL.revokeObjectURL(url);
  }

  // Récupère la liste unique des produits et plateformes pour les filtres
  const productList = Array.from(new Set(payments.map(p => p.product_id))).filter(Boolean);
  const platformList = Array.from(new Set(payments.map(p => p.platform))).filter(Boolean);

  const filtered = filterPayments();
  const paginated = filtered.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Paiements</Typography>
      <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
        <TextField
          label="Recherche"
          value={search}
          onChange={handleSearchChange}
          size="small"
          InputProps={{
            endAdornment: (
              <InputAdornment position="end">
                <IconButton>
                  <SearchIcon />
                </IconButton>
              </InputAdornment>
            ),
          }}
        />
        <Select
          value={platform}
          onChange={handlePlatformChange}
          displayEmpty
          size="small"
          sx={{ minWidth: 120 }}
        >
          <MenuItem value="">Plateforme</MenuItem>
          {platformList.map((plat) => (
            <MenuItem key={plat} value={plat}>{plat}</MenuItem>
          ))}
        </Select>
        <Select
          value={product}
          onChange={handleProductChange}
          displayEmpty
          size="small"
          sx={{ minWidth: 120 }}
        >
          <MenuItem value="">Produit</MenuItem>
          {productList.map((prod) => (
            <MenuItem key={prod} value={prod}>{prod}</MenuItem>
          ))}
        </Select>
        <Button variant="outlined" startIcon={<DownloadIcon />} onClick={exportCSV}>
          Export CSV
        </Button>
      </Box>
      <Paper sx={{ width: '100%', overflow: 'auto' }}>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Device ID</TableCell>
                <TableCell>Produit</TableCell>
                <TableCell>Montant</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Plateforme</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Reçu</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginated.map((p, idx) => (
                <TableRow key={p.id || idx}>
                  <TableCell>{p.device_id}</TableCell>
                  <TableCell>{p.product_id}</TableCell>
                  <TableCell>{p.amount} €</TableCell>
                  <TableCell>{p.purchase_date ? new Date(p.purchase_date).toLocaleString() : ''}</TableCell>
                  <TableCell>{p.platform}</TableCell>
                  <TableCell>{p.status}</TableCell>
                  <TableCell>{p.receipt ? 'Oui' : 'Non'}</TableCell>
                </TableRow>
              ))}
              {paginated.length === 0 && (
                <TableRow>
                  <TableCell colSpan={7} align="center">Aucun paiement trouvé</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          component="div"
          count={filtered.length}
          page={page}
          onPageChange={handleChangePage}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          rowsPerPageOptions={[5, 10, 25, 50]}
        />
      </Paper>
    </Box>
  );
} 