import { useEffect, useState, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Box, Typography, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination, TextField, InputAdornment, IconButton, Button, MenuItem, Select, Grid, Divider, Tabs, Tab } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import DownloadIcon from '@mui/icons-material/Download';
import Loader from '../../components/Loader';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Collapse from '@mui/material/Collapse';
import RefreshIcon from '@mui/icons-material/Refresh';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, LineChart, CartesianGrid, Line } from 'recharts';
import React from 'react';

const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';
const supabase = createClient(supabaseUrl, supabaseKey);

type LotteryEntry = {
  id?: string;
  device_id?: string;
  user_id?: string;
  entry_date?: string;
  [key: string]: any;
};

export default function ReferralsPage() {
  const [referrals, setReferrals] = useState<any[]>([]); // liens de parrainage enrichis
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [globalStats, setGlobalStats] = useState({ totalFilleuls: 0, totalPremium: 0 });
  const [expanded, setExpanded] = useState<string | null>(null);
  // Nouvel état pour l'onglet
  const [tab, setTab] = useState(0);
  // État pour les Smooth Coin
  const [coins, setCoins] = useState<any[]>([]);
  const [coinSearch, setCoinSearch] = useState('');
  const [coinPage, setCoinPage] = useState(0);
  const [coinRowsPerPage, setCoinRowsPerPage] = useState(10);
  const [coinLoading, setCoinLoading] = useState(false);
  const [coinError, setCoinError] = useState<string | null>(null);
  // Ajouts pour l'onglet Tirage au sort
  const [lotteryTab, setLotteryTab] = useState<{
    loading: boolean;
    error: string | null;
    entries: LotteryEntry[];
    search: string;
    page: number;
    rowsPerPage: number;
  }>({ loading: false, error: null, entries: [], search: '', page: 0, rowsPerPage: 10 });
  // Ajout d'un mode 'groupé' pour le tirage au sort
  const [lotteryGrouped, setLotteryGrouped] = useState(true);
  const [lotteryStatsTab, setLotteryStatsTab] = useState(0);
  const [drawResult, setDrawResult] = useState<LotteryEntry | string | null>(null);

  useEffect(() => {
    fetchReferralStats();
    const interval = setInterval(() => {
      fetchReferralStats();
    }, 60000); // 1 minute
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (tab === 1) fetchCoins();
  }, [tab]);

  useEffect(() => {
    if (tab === 2) fetchLotteryEntries();
  }, [tab]);

  async function fetchReferralStats() {
    setLoading(true);
    setError(null);
    try {
      // 1. Liens de parrainage
      const { data: links, error: errLinks } = await supabase.from('referral_links').select('*');
      if (errLinks) throw errLinks;
      // 2. Usages (filleuls)
      const { data: uses, error: errUses } = await supabase.from('referral_uses').select('*');
      if (errUses) throw errUses;
      // 3. Paiements
      const { data: payments, error: errPay } = await supabase.from('payments').select('user_id, product_id');
      if (errPay) throw errPay;

      // 4. Calcul des stats par parrain
      let totalFilleuls = 0;
      let totalPremium = 0;
      const enriched = links.map(link => {
        const filleuls = uses.filter(u => u.referral_code === link.code);
        const filleulsPremium = filleuls.filter(f => payments.some(p => p.user_id === f.user_id && p.product_id && p.product_id.includes('premium')));
        // Ajout du détail des filleuls avec leur statut premium
        const filleulsDetails = filleuls.map(f => ({
          ...f,
          isPremium: payments.some(p => p.user_id === f.user_id && p.product_id && p.product_id.includes('premium'))
        }));
        totalFilleuls += filleuls.length;
        totalPremium += filleulsPremium.length;
        return {
          ...link,
          totalFilleuls: filleuls.length,
          totalPremium: filleulsPremium.length,
          totalGratuits: filleuls.length - filleulsPremium.length,
          filleulsDetails,
        };
      });
      setReferrals(enriched);
      setGlobalStats({ totalFilleuls, totalPremium });
    } catch (e: any) {
      setError((e as any).message || 'Erreur lors du chargement des parrainages');
    } finally {
      setLoading(false);
    }
  }

  async function fetchCoins() {
    setCoinLoading(true);
    setCoinError(null);
    try {
      const { data, error } = await supabase.from('user_referral_points').select('*');
      if (error) throw error;
      setCoins(data || []);
    } catch (e: any) {
      setCoinError((e as any).message || 'Erreur lors du chargement des Smooth Coin');
    } finally {
      setCoinLoading(false);
    }
  }

  async function fetchLotteryEntries() {
    setLotteryTab((prev: typeof lotteryTab) => ({ ...prev, loading: true, error: null }));
    try {
      const { data, error } = await supabase.from('referral_lottery_entries').select('*');
      if (error) throw error;
      setLotteryTab((prev: typeof lotteryTab) => ({ ...prev, entries: data || [], loading: false }));
    } catch (e) {
      setLotteryTab((prev: typeof lotteryTab) => ({ ...prev, error: (e as any).message || 'Erreur lors du chargement des participations', loading: false }));
    }
  }

  function handleSearchChange(e: React.ChangeEvent<HTMLInputElement>) {
    setSearch(e.target.value);
    setPage(0);
  }

  function handleStatusChange(e: React.ChangeEvent<HTMLInputElement>) {
    setStatus(e.target.value);
    setPage(0);
  }

  function handleTabChange(event: React.SyntheticEvent, newValue: number) {
    setTab(newValue);
  }

  function handleCoinSearchChange(e: React.ChangeEvent<HTMLInputElement>) {
    setCoinSearch(e.target.value);
    setCoinPage(0);
  }

  function handleLotterySearchChange(e: React.ChangeEvent<HTMLInputElement>) {
    setLotteryTab((prev: typeof lotteryTab) => ({ ...prev, search: e.target.value, page: 0 }));
  }

  function filterReferrals() {
    return referrals.filter((r: any) => {
      const matchesSearch =
        search === '' ||
        r.user_id?.toLowerCase().includes(search.toLowerCase()) ||
        r.code?.toLowerCase().includes(search.toLowerCase());
      const matchesStatus = status === '' || r.reward_status === status;
      return matchesSearch && matchesStatus;
    });
  }

  function filterCoins() {
    return coins.filter((c: any) => {
      return (
        coinSearch === '' ||
        c.user_id?.toLowerCase().includes(coinSearch.toLowerCase()) ||
        c.device_id?.toLowerCase().includes(coinSearch.toLowerCase())
      );
    });
  }

  function filterLotteryEntries() {
    return lotteryTab.entries.filter((entry: any) =>
      lotteryTab.search === '' ||
      (entry.device_id && entry.device_id.toLowerCase().includes(lotteryTab.search.toLowerCase())) ||
      (entry.user_id && entry.user_id.toLowerCase().includes(lotteryTab.search.toLowerCase()))
    );
  }

  function groupLotteryEntries(entries: LotteryEntry[]) {
    const map = new Map();
    for (const e of entries) {
      const key = (e.user_id || '') + '|' + (e.device_id || '');
      if (!map.has(key)) {
        map.set(key, { user_id: e.user_id, device_id: e.device_id, count: 1, last_entry: e.entry_date });
      } else {
        const obj = map.get(key);
        obj.count++;
        if (e.entry_date && new Date(e.entry_date) > new Date(obj.last_entry || '')) obj.last_entry = e.entry_date;
        map.set(key, obj);
      }
    }
    return Array.from(map.values());
  }

  function handleChangePage(event: unknown, newPage: number) {
    setPage(newPage);
  }

  function handleChangeRowsPerPage(event: React.ChangeEvent<HTMLInputElement>) {
    setRowsPerPage(+event.target.value);
    setPage(0);
  }

  function handleCoinChangePage(event: unknown, newPage: number) {
    setCoinPage(newPage);
  }

  function handleCoinChangeRowsPerPage(event: React.ChangeEvent<HTMLInputElement>) {
    setCoinRowsPerPage(+event.target.value);
    setCoinPage(0);
  }

  function handleLotteryChangePage(event: unknown, newPage: number) {
    setLotteryTab((prev: typeof lotteryTab) => ({ ...prev, page: newPage }));
  }

  function handleLotteryChangeRowsPerPage(event: React.ChangeEvent<HTMLInputElement>) {
    setLotteryTab((prev: typeof lotteryTab) => ({ ...prev, rowsPerPage: +event.target.value, page: 0 }));
  }

  function exportCSV() {
    try {
      const rows = filterReferrals();
      const header = ['Utilisateur', 'Code parrainage', 'Nombre de filleuls', 'Filleuls premium', 'Filleuls gratuits', 'Statut récompense', 'Date création'];
      const csv = [header.join(',')].concat(
        rows.map((r: any) => [
          r.user_id,
          r.code,
          r.totalFilleuls ?? '',
          r.totalPremium ?? '',
          r.totalGratuits ?? '',
          r.reward_status ?? '',
          r.created_at ? new Date(r.created_at).toLocaleDateString() : ''
        ].map(x => '"' + (x ?? '') + '"').join(','))
      ).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'parrainages.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (e: any) {
      // Optionnel: afficher une notification d'erreur
    }
  }

  function exportCoinCSV() {
    try {
      const rows = filterCoins();
      const header = ['User ID', 'Device ID', 'Smooth Coin disponibles', 'Total Smooth Coin gagnés'];
      const csv = [header.join(',')].concat(
        rows.map((c: any) => [
          c.user_id,
          c.device_id,
          c.available_points,
          c.total_points_earned
        ].map(x => '"' + (x ?? '') + '"').join(','))
      ).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'smooth_coin.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (e: any) {}
  }

  function exportLotteryCSV() {
    try {
      const rows = groupLotteryEntries(lotteryTab.entries);
      const header = lotteryGrouped ? ['Device ID', 'User ID', 'Nombre de tickets', 'Dernière participation'] : ['Device ID', 'User ID', 'Date d\'entrée'];
      const csv = [header.join(',')].concat(
        rows.map((e) => lotteryGrouped ? [
          e.device_id,
          e.user_id,
          e.count,
          e.last_entry ? new Date(e.last_entry).toLocaleDateString() : ''
        ] : [
          e.device_id,
          e.user_id,
          e.entry_date ? new Date(e.entry_date).toLocaleDateString() : ''
        ]).map(arr => arr.map(x => '"' + (x ?? '') + '"').join(','))
      ).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'tirage_au_sort.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (e) {}
  }

  const filtered = filterReferrals();
  const paginated = filtered.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);

  const filteredCoins = filterCoins();
  const paginatedCoins = filteredCoins.slice(coinPage * coinRowsPerPage, coinPage * coinRowsPerPage + coinRowsPerPage);

  const filteredLottery = filterLotteryEntries();
  const groupedLottery = lotteryGrouped ? groupLotteryEntries(filteredLottery) : filteredLottery;
  const paginatedLottery = groupedLottery.slice(lotteryTab.page * lotteryTab.rowsPerPage, lotteryTab.page * lotteryTab.rowsPerPage + lotteryTab.rowsPerPage);

  // Définition temporaire pour éviter les erreurs de variables non définies
  const drawWinner = () => {};
  const topParrains: any[] = [];
  const coinsByMonth: any[] = [];

  if (loading) return <Loader />;
  if (error) return <Box p={4} color="error.main" aria-live="assertive">{error}</Box>;

  return (
    <div>
      <Typography variant="h4" gutterBottom sx={{ color: 'text.primary', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: 2 }}>
        Parrainage
        <Button onClick={fetchReferralStats} startIcon={<RefreshIcon />} size="small" variant="outlined" sx={{ ml: 2 }}>
          Rafraîchir
        </Button>
      </Typography>
      <Tabs value={tab} onChange={handleTabChange} sx={{ mb: 2 }}>
        <Tab label="Parrainage" />
        <Tab label="Smooth Coin" />
        <Tab label="Tirage au sort" />
      </Tabs>
      {tab === 0 && (
        <>
        <Grid container spacing={2} mb={2}>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 2, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
              <Typography variant="subtitle1">Total filleuls</Typography>
              <Typography variant="h5">{globalStats.totalFilleuls}</Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 2, bgcolor: 'success.main', color: 'success.contrastText' }}>
              <Typography variant="subtitle1">Filleuls premium</Typography>
              <Typography variant="h5">{globalStats.totalPremium}</Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 2, bgcolor: 'warning.main', color: 'warning.contrastText' }}>
              <Typography variant="subtitle1">Filleuls gratuits</Typography>
              <Typography variant="h5">{globalStats.totalFilleuls - globalStats.totalPremium}</Typography>
            </Paper>
          </Grid>
        </Grid>
        <Divider sx={{ mb: 2 }} />
        <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
          <TextField
            label="Recherche utilisateur/code"
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
              ) as React.ReactNode, // cast pour éviter l'erreur de type
            }}
          />
          <Select
            value={status}
            onChange={(e) => handleStatusChange(e as React.ChangeEvent<HTMLInputElement>)}
            displayEmpty
            sx={{ minWidth: 120 }}
          >
            <MenuItem value="">Statut récompense</MenuItem>
            <MenuItem value="pending">En attente</MenuItem>
            <MenuItem value="rewarded">Attribuée</MenuItem>
          </Select>
          <Button variant="outlined" startIcon={<DownloadIcon />} onClick={exportCSV}>
            Export CSV
          </Button>
        </div>
        <Paper sx={{ width: '100%', overflow: 'auto' }}>
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell />
                  <TableCell>Utilisateur</TableCell>
                  <TableCell>Code parrainage</TableCell>
                  <TableCell>Nombre de filleuls</TableCell>
                  <TableCell>Filleuls premium</TableCell>
                  <TableCell>Filleuls gratuits</TableCell>
                  <TableCell>Statut récompense</TableCell>
                  <TableCell>Date création</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginated.map((r: any, idx: number) => (
                  <React.Fragment key={r.id || idx}>
                    <TableRow>
                      <TableCell>
                        <IconButton size="small" onClick={() => setExpanded(expanded === r.code ? null : r.code)}>
                          <ExpandMoreIcon sx={{ transform: expanded === r.code ? 'rotate(180deg)' : 'rotate(0deg)' }} />
                        </IconButton>
                      </TableCell>
                      <TableCell>{r.user_id}</TableCell>
                      <TableCell>{r.code}</TableCell>
                      <TableCell>{r.totalFilleuls ?? ''}</TableCell>
                      <TableCell>{r.totalPremium ?? ''}</TableCell>
                      <TableCell>{r.totalGratuits ?? ''}</TableCell>
                      <TableCell>{r.reward_status ?? ''}</TableCell>
                      <TableCell>{r.created_at ? new Date(r.created_at).toLocaleDateString() : ''}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell {...{ colSpan: 8 } as any} sx={{ p: 0, border: 0 }}>
                        <Collapse in={expanded === r.code} timeout="auto">
                          <div style={{ background: '#F4F6FA', padding: 16 }}>
                            <Typography variant="subtitle2" gutterBottom>Filleuls</Typography>
                            <Table size="small">
                              <TableHead>
                                <TableRow>
                                  <TableCell>Utilisateur</TableCell>
                                  <TableCell>Date d'inscription</TableCell>
                                  <TableCell>Statut</TableCell>
                                </TableRow>
                              </TableHead>
                              <TableBody>
                                {(r.filleulsDetails ?? []).map((f: any, i: number) => (
                                  <TableRow key={f.id || i}>
                                    <TableCell>{f.user_id}</TableCell>
                                    <TableCell>{f.created_at ? new Date(f.created_at).toLocaleDateString() : ''}</TableCell>
                                    <TableCell>{f.isPremium ? 'Premium' : 'Gratuit'}</TableCell>
                                  </TableRow>
                                ))}
                                {(r.filleulsDetails?.length === 0) && (
                                  <TableRow>
                                    <TableCell {...{ colSpan: 3 } as any} align="center">Aucun filleul</TableCell>
                                  </TableRow>
                                )}
                              </TableBody>
                            </Table>
                          </div>
                        </Collapse>
                      </TableCell>
                    </TableRow>
                  </React.Fragment>
                ))}
                {paginated.length === 0 && (
                  <TableRow>
                    <TableCell {...{ colSpan: 8 } as any} align="center">Aucun parrainage trouvé</TableCell>
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
        </>
      )}
      {tab === 1 && (
        <div>
          <Typography variant="h5" gutterBottom>Smooth Coin par utilisateur</Typography>
          <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
            <TextField
              label="Recherche user/device ID"
              value={coinSearch}
              onChange={handleCoinSearchChange}
              size="small"
            />
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={exportCoinCSV}>
              Export CSV
            </Button>
          </div>
          {coinLoading ? <Loader /> : coinError ? <div style={{ color: 'red' }}>{coinError}</div> : (
            <Paper sx={{ width: '100%', overflow: 'auto' }}>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>User ID</TableCell>
                      <TableCell>Device ID</TableCell>
                      <TableCell>Smooth Coin disponibles</TableCell>
                      <TableCell>Total Smooth Coin gagnés</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {paginatedCoins.map((c: any) => (
                      <TableRow key={c.user_id || c.device_id}>
                        <TableCell>{c.user_id}</TableCell>
                        <TableCell>{c.device_id}</TableCell>
                        <TableCell>{c.available_points}</TableCell>
                        <TableCell>{c.total_points_earned}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
              <TablePagination
                component="div"
                count={filteredCoins.length}
                page={coinPage}
                onPageChange={handleCoinChangePage}
                rowsPerPage={coinRowsPerPage}
                onRowsPerPageChange={handleCoinChangeRowsPerPage}
                rowsPerPageOptions={[10, 25, 50]}
              />
            </Paper>
          )}
        </div>
      )}
      {tab === 2 && (
        <div>
          <Typography variant="h5" gutterBottom>Participations au tirage au sort</Typography>
          <Tabs value={lotteryStatsTab} onChange={(_: React.SyntheticEvent, v: number) => setLotteryStatsTab(v)} sx={{ mb: 2 }}>
            <Tab label="Liste" />
            <Tab label="Statistiques" />
          </Tabs>
          {lotteryStatsTab === 0 && (
            <div>
              <div style={{ display: 'flex', gap: 8, marginBottom: 16, alignItems: 'center' }}>
                <TextField
                  label="Recherche device/user ID"
                  value={lotteryTab.search}
                  onChange={handleLotterySearchChange}
                  size="small"
                />
                <Button variant="outlined" startIcon={<DownloadIcon />} onClick={exportLotteryCSV}>
                  Export CSV
                </Button>
                <Button variant="outlined" onClick={() => setLotteryGrouped((g: boolean) => !g)}>
                  {lotteryGrouped ? 'Voir participations individuelles' : 'Voir tickets par utilisateur'}
                </Button>
                <Button variant="contained" color="primary" onClick={drawWinner} disabled={lotteryGrouped}>
                  Tirer au sort un gagnant
                </Button>
              </div>
              {drawResult && (
                <div style={{ marginBottom: 16, padding: 16, background: '#e3f2fd', borderRadius: 8 }}>
                  <Typography variant="subtitle1">Gagnant :</Typography>
                  {typeof drawResult === 'string' ? drawResult : (
                    <div>
                      <Typography>User ID : {drawResult.user_id || '-'}</Typography>
                      <Typography>Device ID : {drawResult.device_id || '-'}</Typography>
                      <Typography>Date d'entrée : {drawResult.entry_date ? new Date(drawResult.entry_date).toLocaleDateString() : '-'}</Typography>
                    </div>
                  )}
                </div>
              )}
              {lotteryTab.loading ? <Loader /> : lotteryTab.error ? <div style={{ color: 'red' }}>{lotteryTab.error}</div> : (
                <Paper sx={{ width: '100%', overflow: 'auto' }}>
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Device ID</TableCell>
                          <TableCell>User ID</TableCell>
                          {lotteryGrouped ? <TableCell>Nombre de tickets</TableCell> : <TableCell>Date d'entrée</TableCell>}
                          {lotteryGrouped && <TableCell>Dernière participation</TableCell>}
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {paginatedLottery.map((e: any) => (
                          <TableRow key={String(e.user_id || '') + String(e.device_id || '') + String(e.entry_date || e.last_entry || '')}>
                            <TableCell>{e.device_id}</TableCell>
                            <TableCell>{e.user_id}</TableCell>
                            {lotteryGrouped ? <TableCell>{e.count}</TableCell> : <TableCell>{e.entry_date ? new Date(e.entry_date).toLocaleDateString() : ''}</TableCell>}
                            {lotteryGrouped && <TableCell>{e.last_entry ? new Date(e.last_entry).toLocaleDateString() : ''}</TableCell>}
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                  <TablePagination
                    component="div"
                    count={groupedLottery.length}
                    page={lotteryTab.page}
                    onPageChange={handleLotteryChangePage}
                    rowsPerPage={lotteryTab.rowsPerPage}
                    onRowsPerPageChange={handleLotteryChangeRowsPerPage}
                    rowsPerPageOptions={[10, 25, 50]}
                  />
                </Paper>
              )}
            </div>
          )}
          {lotteryStatsTab === 1 && (
            <Grid container spacing={4}>
              <Grid item xs={12} md={6}>
                <Paper sx={{ p: 3 }}>
                  <Typography variant="h6" gutterBottom>Top parrains (Smooth Coin gagnés)</Typography>
                  <ResponsiveContainer width="100%" height={250}>
                    <BarChart data={topParrains} layout="vertical">
                      <XAxis type="number" dataKey="coins" />
                      <YAxis type="category" dataKey="user" width={120} />
                      <Tooltip />
                      <Bar dataKey="coins" fill="#2196F3" />
                    </BarChart>
                  </ResponsiveContainer>
                </Paper>
              </Grid>
              <Grid item xs={12} md={6}>
                <Paper sx={{ p: 3 }}>
                  <Typography variant="h6" gutterBottom>Évolution des Smooth Coin par mois</Typography>
                  <ResponsiveContainer width="100%" height={250}>
                    <LineChart data={coinsByMonth}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <Tooltip />
                      <Line type="monotone" dataKey="coins" stroke="#4CAF50" />
                    </LineChart>
                  </ResponsiveContainer>
                </Paper>
              </Grid>
            </Grid>
          )}
        </div>
      )}
    </div>
  );
} 