-- Table pour stocker les paramètres admin (message d'accueil, etc.)
create table if not exists admin_settings (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  value text,
  updated_at timestamp with time zone default now()
);

-- Insérer un message d'accueil par défaut
insert into admin_settings (key, value) values ('welcome_message', 'Bienvenue sur le dashboard admin Smooth AI !') on conflict (key) do nothing; 