-- Table pour les pickup lines favorites
CREATE TABLE IF NOT EXISTS favorite_pickup_lines (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  pickup_line_id TEXT NOT NULL,
  text TEXT NOT NULL,
  category TEXT NOT NULL,
  context TEXT NOT NULL,
  intensity INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activer RLS
ALTER TABLE favorite_pickup_lines ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view their own favorite pickup lines" ON favorite_pickup_lines
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own favorite pickup lines" ON favorite_pickup_lines
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorite pickup lines" ON favorite_pickup_lines
  FOR DELETE USING (auth.uid() = user_id);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_favorite_pickup_lines_user_id ON favorite_pickup_lines(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_pickup_lines_created_at ON favorite_pickup_lines(created_at);
