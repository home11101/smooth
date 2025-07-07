'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination, TextField, InputAdornment, IconButton, Button, MenuItem, Select, Collapse, Dialog, DialogTitle, DialogContent, DialogActions, FormControl, InputLabel } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import DownloadIcon from '@mui/icons-material/Download';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import AddIcon from '@mui/icons-material/Add';
import ToggleOnIcon from '@mui/icons-material/ToggleOn';
import ToggleOffIcon from '@mui/icons-material/ToggleOff';
import PrintIcon from '@mui/icons-material/Print';
import Loader from '../../components/Loader';
import Notification from '../../components/Notification';
import FadeTransition from '../../components/FadeTransition';
import { useRef } from 'react';
import { Snackbar } from '@mui/material';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

const defaultNewCode = {
  code: '',
  description: '',
  discount_type: 'percentage',
  discount_value: 10,
  max_uses: 1,
  valid_until: '',
  is_active: true,
};

export default function PromoCodesPage() {
  const [codes, setCodes] = useState<any[]>([]);
  const [usages, setUsages] = useState<{[codeId: string]: any[]}>({});
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [type, setType] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [newCode, setNewCode] = useState({ ...defaultNewCode });
  const [creating, setCreating] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notif, setNotif] = useState<{open: boolean, message: string, severity?: 'success'|'info'|'warning'|'error'}>({open: false, message: ''});
  const [confirmDialog, setConfirmDialog] = useState<{open: boolean, code: any | null, action: 'toggle'|'delete'|null}>({open: false, code: null, action: null});
  const [undoStack, setUndoStack] = useState<any[]>([]);
  const [sortBy, setSortBy] = useState<string>('created_at');
  const [sortOrder, setSortOrder] = useState<'asc'|'desc'>('desc');

  useEffect(() => {
    fetchCodes();
  }, []);

  async function fetchCodes() {
    setLoading(true);
    setError(null);
    try {
      const { data, error } = await supabase.from('promo_codes').select('*').order('created_at', { ascending: false });
      if (error) throw error;
      setCodes(data || []);
    } catch (e: any) {
      setError(e.message || 'Erreur lors du chargement des codes promo');
      setNotif({open: true, message: e.message || 'Erreur lors du chargement', severity: 'error'});
    } finally {
      setLoading(false);
    }
  }

  async function fetchUsages(codeId: string) {
    if (usages[codeId]) return; // déjà chargé
    const { data, error } = await supabase.from('promo_code_usage').select('*').eq('promo_code_id', codeId).order('used_at', { ascending: false });
    setUsages(u => ({ ...u, [codeId]: data || [] }));
  }

  function handleSearchChange(e: any) {
    setSearch(e.target.value);
    setPage(0);
  }

  function handleStatusChange(e: any) {
    setStatus(e.target.value);
    setPage(0);
  }

  function handleTypeChange(e: any) {
    setType(e.target.value);
    setPage(0);
  }

  function filterCodes() {
    return codes.filter((c) => {
      const matchesSearch =
        search === '' ||
        c.code?.toLowerCase().includes(search.toLowerCase()) ||
        c.description?.toLowerCase().includes(search.toLowerCase());
      const matchesStatus = status === '' || (status === 'active' ? c.is_active : !c.is_active);
      const matchesType = type === '' || c.discount_type === type;
      return matchesSearch && matchesStatus && matchesType;
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
    try {
      const rows = filterCodes();
      const header = ['Code', 'Description', 'Type', 'Valeur', 'Utilisations', 'Statut', 'Valide jusqu\'à'];
      const csv = [header.join(',')].concat(
        rows.map((c) => [
          c.code,
          c.description,
          c.discount_type,
          c.discount_value,
          c.current_uses,
          c.is_active ? 'Actif' : 'Inactif',
          c.valid_until,
        ].map(x => '"' + (x ?? '') + '"').join(','))
      ).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'codes_promo.csv';
      a.click();
      window.URL.revokeObjectURL(url);
      setNotif({open: true, message: 'Export CSV effectué', severity: 'success'});
    } catch (e: any) {
      setNotif({open: true, message: e.message || 'Erreur export CSV', severity: 'error'});
    }
  }

  async function handleCreateCode() {
    setCreating(true);
    const { error } = await supabase.from('promo_codes').insert([
      {
        ...newCode,
        valid_until: newCode.valid_until ? new Date(newCode.valid_until).toISOString() : null,
      },
    ]);
    setCreating(false);
    setOpenDialog(false);
    setNewCode({ ...defaultNewCode });
    await fetchCodes();
  }

  async function handleToggleActive(code: any) {
    // Sauvegarder l'état précédent pour undo
    const previousState = { ...code };
    setUndoStack(prev => [...prev, { action: 'toggle', code: previousState }]);
    
    await supabase.from('promo_codes').update({ is_active: !code.is_active }).eq('id', code.id);
    await fetchCodes();
    setNotif({ open: true, message: `Code ${code.is_active ? 'désactivé' : 'activé'}`, severity: 'success' });
  }

  async function handleConfirmAction() {
    if (confirmDialog.code && confirmDialog.action) {
      if (confirmDialog.action === 'toggle') {
        await handleToggleActive(confirmDialog.code);
      }
      // Ajouter d'autres actions si nécessaire
    }
    setConfirmDialog({ open: false, code: null, action: null });
  }

  async function handleUndo() {
    if (undoStack.length > 0) {
      const lastAction = undoStack[undoStack.length - 1];
      if (lastAction.action === 'toggle') {
        await supabase.from('promo_codes').update({ is_active: lastAction.code.is_active }).eq('id', lastAction.code.id);
        await fetchCodes();
        setNotif({ open: true, message: 'Action annulée', severity: 'info' });
      }
      setUndoStack(prev => prev.slice(0, -1));
    }
  }

  function handleUndoClose() {
    setUndoStack([]);
  }

  const typeList = Array.from(new Set(codes.map(c => c.discount_type))).filter(Boolean);
  const filtered = getSortedCodes();
  const paginated = filtered.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);

  function handleSort(col: string) {
    if (sortBy === col) setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    else { setSortBy(col); setSortOrder('asc'); }
  }

  function getSortedCodes() {
    return [...filterCodes()].sort((a, b) => {
      if (a[sortBy] < b[sortBy]) return sortOrder === 'asc' ? -1 : 1;
      if (a[sortBy] > b[sortBy]) return sortOrder === 'asc' ? 1 : -1;
      return 0;
    });
  }

  function handlePrint() {
    window.print();
  }

  if (loading) return <Loader />;
  if (error) return <Box p={4} color="error.main" aria-live="assertive">{error}</Box>;

  return (
    <Box>
      <FadeTransition in={notif.open}>
        <Notification open={notif.open} message={notif.message} severity={notif.severity} onClose={() => setNotif({...notif, open: false})} aria-live="polite" />
      </FadeTransition>
      <Typography variant="h4" gutterBottom>Codes Promo</Typography>
      <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>
          Nouveau code promo
        </Button>
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
          value={status}
          onChange={handleStatusChange}
          displayEmpty
          size="small"
          sx={{ minWidth: 120 }}
        >
          <MenuItem value="">Statut</MenuItem>
          <MenuItem value="active">Actif</MenuItem>
          <MenuItem value="inactive">Inactif</MenuItem>
        </Select>
        <Select
          value={type}
          onChange={handleTypeChange}
          displayEmpty
          size="small"
          sx={{ minWidth: 120 }}
        >
          <MenuItem value="">Type</MenuItem>
          {typeList.map((t) => (
            <MenuItem key={t} value={t}>{t}</MenuItem>
          ))}
        </Select>
        <Button variant="outlined" startIcon={<DownloadIcon />} onClick={exportCSV}>
          Export CSV
        </Button>
        <Button variant="outlined" onClick={handlePrint} startIcon={<PrintIcon />} tabIndex={0}>Imprimer</Button>
      </Box>
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)}>
        <DialogTitle>Nouveau code promo</DialogTitle>
        <DialogContent sx={{ display: 'flex', flexDirection: 'column', gap: 2, minWidth: 350 }}>
          <TextField label="Code" value={newCode.code} onChange={e => setNewCode(n => ({ ...n, code: e.target.value }))} fullWidth />
          <TextField label="Description" value={newCode.description} onChange={e => setNewCode(n => ({ ...n, description: e.target.value }))} fullWidth />
          <FormControl fullWidth>
            <InputLabel>Type</InputLabel>
            <Select value={newCode.discount_type} label="Type" onChange={e => setNewCode(n => ({ ...n, discount_type: e.target.value }))}>
              <MenuItem value="percentage">Pourcentage</MenuItem>
              <MenuItem value="fixed_amount">Montant fixe</MenuItem>
              <MenuItem value="trial_extension">Extension d'essai</MenuItem>
            </Select>
          </FormControl>
          <TextField label="Valeur" type="number" value={newCode.discount_value} onChange={e => setNewCode(n => ({ ...n, discount_value: Number(e.target.value) }))} fullWidth />
          <TextField label="Nombre d'utilisations max" type="number" value={newCode.max_uses} onChange={e => setNewCode(n => ({ ...n, max_uses: Number(e.target.value) }))} fullWidth />
          <TextField label="Valide jusqu'au" type="date" value={newCode.valid_until} onChange={e => setNewCode(n => ({ ...n, valid_until: e.target.value }))} InputLabelProps={{ shrink: true }} fullWidth />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Annuler</Button>
          <Button onClick={handleCreateCode} disabled={creating} variant="contained">Créer</Button>
        </DialogActions>
      </Dialog>
      <Paper sx={{ width: '100%', overflow: 'auto' }}>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell
                  onClick={() => handleSort('code')}
                  aria-sort={sortBy === 'code' ? (sortOrder === 'asc' ? 'ascending' : 'descending') : 'none'}
                  tabIndex={0}
                  style={{ cursor: 'pointer', outline: 'none' }}
                  onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleSort('code'); }}
                >
                  Code {sortBy === 'code' ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </TableCell>
                <TableCell
                  onClick={() => handleSort('description')}
                  aria-sort={sortBy === 'description' ? (sortOrder === 'asc' ? 'ascending' : 'descending') : 'none'}
                  tabIndex={0}
                  style={{ cursor: 'pointer', outline: 'none' }}
                  onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleSort('description'); }}
                >
                  Description {sortBy === 'description' ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </TableCell>
                <TableCell
                  onClick={() => handleSort('discount_type')}
                  aria-sort={sortBy === 'discount_type' ? (sortOrder === 'asc' ? 'ascending' : 'descending') : 'none'}
                  tabIndex={0}
                  style={{ cursor: 'pointer', outline: 'none' }}
                  onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleSort('discount_type'); }}
                >
                  Type {sortBy === 'discount_type' ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </TableCell>
                <TableCell
                  onClick={() => handleSort('discount_value')}
                  aria-sort={sortBy === 'discount_value' ? (sortOrder === 'asc' ? 'ascending' : 'descending') : 'none'}
                  tabIndex={0}
                  style={{ cursor: 'pointer', outline: 'none' }}
                  onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleSort('discount_value'); }}
                >
                  Valeur {sortBy === 'discount_value' ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </TableCell>
                <TableCell
                  onClick={() => handleSort('current_uses')}
                  aria-sort={sortBy === 'current_uses' ? (sortOrder === 'asc' ? 'ascending' : 'descending') : 'none'}
                  tabIndex={0}
                  style={{ cursor: 'pointer', outline: 'none' }}
                  onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleSort('current_uses'); }}
                >
                  Utilisations {sortBy === 'current_uses' ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </TableCell>
                <TableCell
                  onClick={() => handleSort('is_active')}
                  aria-sort={sortBy === 'is_active' ? (sortOrder === 'asc' ? 'ascending' : 'descending') : 'none'}
                  tabIndex={0}
                  style={{ cursor: 'pointer', outline: 'none' }}
                  onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleSort('is_active'); }}
                >
                  Statut {sortBy === 'is_active' ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </TableCell>
                <TableCell
                  onClick={() => handleSort('valid_until')}
                  aria-sort={sortBy === 'valid_until' ? (sortOrder === 'asc' ? 'ascending' : 'descending') : 'none'}
                  tabIndex={0}
                  style={{ cursor: 'pointer', outline: 'none' }}
                  onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleSort('valid_until'); }}
                >
                  Valide jusqu'à {sortBy === 'valid_until' ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </TableCell>
                <TableCell>Usages</TableCell>
                <TableCell>Action</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginated.map((c, idx) => (
                <>
                  <TableRow key={c.id || idx}>
                    <TableCell>{c.code}</TableCell>
                    <TableCell>{c.description}</TableCell>
                    <TableCell>{c.discount_type}</TableCell>
                    <TableCell>{c.discount_value}</TableCell>
                    <TableCell>{c.current_uses} / {c.max_uses ?? '∞'}</TableCell>
                    <TableCell>{c.is_active ? 'Actif' : 'Inactif'}</TableCell>
                    <TableCell>{c.valid_until ? new Date(c.valid_until).toLocaleDateString() : ''}</TableCell>
                    <TableCell>
                      <IconButton size="small" onClick={async () => {
                        setExpanded(expanded === c.id ? null : c.id);
                        if (!usages[c.id]) await fetchUsages(c.id);
                      }}>
                        <ExpandMoreIcon sx={{ transform: expanded === c.id ? 'rotate(180deg)' : 'rotate(0deg)' }} />
                      </IconButton>
                    </TableCell>
                    <TableCell>
                      <IconButton
                        onClick={() => setConfirmDialog({ open: true, code: c, action: 'toggle' })}
                        tabIndex={0}
                        aria-label={`${c.is_active ? 'Désactiver' : 'Activer'} le code ${c.code}`}
                      >
                        {c.is_active ? <ToggleOnIcon /> : <ToggleOffIcon />}
                      </IconButton>
                    </TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell colSpan={10} sx={{ p: 0, border: 0 }}>
                      <Collapse in={expanded === c.id} timeout="auto" unmountOnExit>
                        <Box sx={{ bgcolor: '#F4F6FA', p: 2 }}>
                          <Typography variant="subtitle2" gutterBottom>Utilisations</Typography>
                          <Table size="small">
                            <TableHead>
                              <TableRow>
                                <TableCell>Device ID</TableCell>
                                <TableCell>Date</TableCell>
                                <TableCell>Discount appliqué</TableCell>
                                <TableCell>Type abonnement</TableCell>
                              </TableRow>
                            </TableHead>
                            <TableBody>
                              {(usages[c.id] ?? []).map((u, i) => (
                                <TableRow key={u.id || i}>
                                  <TableCell>{u.device_id}</TableCell>
                                  <TableCell>{u.used_at ? new Date(u.used_at).toLocaleString() : ''}</TableCell>
                                  <TableCell>{u.discount_applied}</TableCell>
                                  <TableCell>{u.subscription_type}</TableCell>
                                </TableRow>
                              ))}
                              {(usages[c.id]?.length === 0) && (
                                <TableRow>
                                  <TableCell colSpan={4} align="center">Aucune utilisation</TableCell>
                                </TableRow>
                              )}
                            </TableBody>
                          </Table>
                        </Box>
                      </Collapse>
                    </TableCell>
                  </TableRow>
                </>
              ))}
              {paginated.length === 0 && (
                <TableRow>
                  <TableCell colSpan={10} align="center">Aucun code promo trouvé</TableCell>
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
      <Dialog open={confirmDialog.open} onClose={() => setConfirmDialog({open:false,code:null,action:null})}>
        <DialogTitle>Confirmer l'action</DialogTitle>
        <DialogContent>
          Voulez-vous vraiment {confirmDialog.action === 'delete' ? 'supprimer' : confirmDialog.action === 'toggle' ? (confirmDialog.code?.is_active ? 'désactiver' : 'activer') : 'modifier'} ce code promo ?
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmDialog({open:false,code:null,action:null})} tabIndex={0}>Annuler</Button>
          <Button onClick={handleConfirmAction} color="error" tabIndex={0}>Confirmer</Button>
        </DialogActions>
      </Dialog>
      <Snackbar open={undoStack.length > 0} autoHideDuration={5000} onClose={handleUndoClose} message="Action annulable">
        <Button onClick={handleUndo} color="secondary" tabIndex={0}>Annuler</Button>
      </Snackbar>
    </Box>
  );
} 