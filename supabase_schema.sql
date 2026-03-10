-- ============================================================
-- REBOST - Supabase Database Schema
-- ============================================================
-- IMPORTANT: Abans d'executar aquest SQL, ves a:
--   Supabase Dashboard → Authentication → Providers → Email
--   i DESACTIVA "Confirm email" perquè els usuaris puguin
--   entrar immediatament sense verificar el correu.
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============ TAULES ============

-- Perfils d'usuari (extensió d'auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tipus de producte
CREATE TABLE item_types (
  id TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT NOT NULL DEFAULT '🏷️',
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id, owner_id)
);

-- Ubicacions de producte
CREATE TABLE item_locations (
  id TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT NOT NULL DEFAULT '📍',
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id, owner_id)
);

-- Productes del rebost
CREATE TABLE pantry_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'unitats',
  type_id TEXT NOT NULL,
  location_id TEXT NOT NULL,
  expiry_date TIMESTAMPTZ,
  purchase_date TIMESTAMPTZ,
  opened_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'tancat',
  parent_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Llista de la compra
CREATE TABLE shopping_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'unitats',
  type_id TEXT NOT NULL,
  location_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notificacions
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  type TEXT NOT NULL DEFAULT 'info',
  related_item_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE
);

-- Invitacions de rebost compartit
CREATE TABLE invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Rebosts compartits (relació propietari-membre)
CREATE TABLE pantry_shares (
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (owner_id, member_id)
);

-- Registre de notificacions de caducitat enviades
CREATE TABLE expiry_notified (
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  item_id UUID NOT NULL,
  notification_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, item_id, notification_type)
);

-- ============ ROW LEVEL SECURITY ============

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pantry_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pantry_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE expiry_notified ENABLE ROW LEVEL SECURITY;

-- Funció auxiliar: l'usuari pot accedir al rebost d'un propietari?
CREATE OR REPLACE FUNCTION can_access_pantry(p_owner_id UUID) RETURNS BOOLEAN AS $$
BEGIN
  RETURN p_owner_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pantry_shares
      WHERE owner_id = p_owner_id AND member_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles: tothom pot llegir, només el propi pot modificar
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "profiles_delete" ON profiles FOR DELETE USING (id = auth.uid());

-- Pantry items
CREATE POLICY "pantry_items_select" ON pantry_items FOR SELECT USING (can_access_pantry(owner_id));
CREATE POLICY "pantry_items_insert" ON pantry_items FOR INSERT WITH CHECK (can_access_pantry(owner_id));
CREATE POLICY "pantry_items_update" ON pantry_items FOR UPDATE USING (can_access_pantry(owner_id));
CREATE POLICY "pantry_items_delete" ON pantry_items FOR DELETE USING (can_access_pantry(owner_id));

-- Item types
CREATE POLICY "item_types_select" ON item_types FOR SELECT USING (can_access_pantry(owner_id));
CREATE POLICY "item_types_insert" ON item_types FOR INSERT WITH CHECK (can_access_pantry(owner_id));
CREATE POLICY "item_types_update" ON item_types FOR UPDATE USING (can_access_pantry(owner_id));
CREATE POLICY "item_types_delete" ON item_types FOR DELETE USING (can_access_pantry(owner_id));

-- Item locations
CREATE POLICY "item_locations_select" ON item_locations FOR SELECT USING (can_access_pantry(owner_id));
CREATE POLICY "item_locations_insert" ON item_locations FOR INSERT WITH CHECK (can_access_pantry(owner_id));
CREATE POLICY "item_locations_update" ON item_locations FOR UPDATE USING (can_access_pantry(owner_id));
CREATE POLICY "item_locations_delete" ON item_locations FOR DELETE USING (can_access_pantry(owner_id));

-- Shopping items
CREATE POLICY "shopping_items_select" ON shopping_items FOR SELECT USING (can_access_pantry(owner_id));
CREATE POLICY "shopping_items_insert" ON shopping_items FOR INSERT WITH CHECK (can_access_pantry(owner_id));
CREATE POLICY "shopping_items_update" ON shopping_items FOR UPDATE USING (can_access_pantry(owner_id));
CREATE POLICY "shopping_items_delete" ON shopping_items FOR DELETE USING (can_access_pantry(owner_id));

-- Notifications: només les pròpies
CREATE POLICY "notifications_select" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notifications_insert" ON notifications FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "notifications_update" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "notifications_delete" ON notifications FOR DELETE USING (user_id = auth.uid());

-- Invitations: veure les pròpies, crear com a emissor, actualitzar com a receptor
CREATE POLICY "invitations_select" ON invitations FOR SELECT USING (from_user_id = auth.uid() OR to_user_id = auth.uid());
CREATE POLICY "invitations_insert" ON invitations FOR INSERT WITH CHECK (from_user_id = auth.uid());
CREATE POLICY "invitations_update" ON invitations FOR UPDATE USING (to_user_id = auth.uid());

-- Pantry shares
CREATE POLICY "pantry_shares_select" ON pantry_shares FOR SELECT USING (owner_id = auth.uid() OR member_id = auth.uid());
CREATE POLICY "pantry_shares_insert" ON pantry_shares FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "pantry_shares_delete" ON pantry_shares FOR DELETE USING (owner_id = auth.uid() OR member_id = auth.uid());

-- Expiry notified
CREATE POLICY "expiry_notified_all" ON expiry_notified FOR ALL USING (user_id = auth.uid());

-- ============ FUNCIONS ============

-- Funció per acceptar una invitació (necessita SECURITY DEFINER per inserir a pantry_shares)
CREATE OR REPLACE FUNCTION accept_invitation(p_invitation_id UUID) RETURNS VOID AS $$
DECLARE
  v_inv invitations;
BEGIN
  SELECT * INTO v_inv FROM invitations
  WHERE id = p_invitation_id AND to_user_id = auth.uid() AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invitació no trobada o no autoritzada';
  END IF;

  UPDATE invitations SET status = 'accepted' WHERE id = p_invitation_id;
  INSERT INTO pantry_shares (owner_id, member_id)
  VALUES (v_inv.from_user_id, v_inv.to_user_id)
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funció per inicialitzar tipus per defecte
CREATE OR REPLACE FUNCTION init_default_types(p_owner_id UUID) RETURNS VOID AS $$
BEGIN
  INSERT INTO item_types (id, owner_id, name, icon, is_default) VALUES
    ('type_verdures', p_owner_id, 'Verdures', '🥬', true),
    ('type_fruita', p_owner_id, 'Fruita', '🍎', true),
    ('type_carn', p_owner_id, 'Carn', '🥩', true),
    ('type_peix', p_owner_id, 'Peix', '🐟', true),
    ('type_dolcos', p_owner_id, 'Dolços i aperitius', '🍪', true),
    ('type_conserves', p_owner_id, 'Conserves', '🥫', true),
    ('type_llegums', p_owner_id, 'Llegums', '🫘', true),
    ('type_arros', p_owner_id, 'Arròs', '🍚', true),
    ('type_pasta', p_owner_id, 'Pasta', '🍝', true),
    ('type_condiments', p_owner_id, 'Condiments', '🧂', true),
    ('type_begudes', p_owner_id, 'Begudes', '🥤', true),
    ('type_cafe', p_owner_id, 'Cafè, te i infusions', '☕', true),
    ('type_farines', p_owner_id, 'Farines', '🌾', true),
    ('type_cereals', p_owner_id, 'Cereals i derivats', '🥣', true),
    ('type_lactics', p_owner_id, 'Làctics', '🧀', true),
    ('type_ous', p_owner_id, 'Ous', '🥚', true),
    ('type_fruits_secs', p_owner_id, 'Fruits secs i llavors', '🥜', true),
    ('type_congelats', p_owner_id, 'Congelats', '🧊', true),
    ('type_pa', p_owner_id, 'Pa i brioxeria', '🍞', true),
    ('type_salses', p_owner_id, 'Salses', '🫙', true)
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funció per inicialitzar ubicacions per defecte
CREATE OR REPLACE FUNCTION init_default_locations(p_owner_id UUID) RETURNS VOID AS $$
BEGIN
  INSERT INTO item_locations (id, owner_id, name, icon, is_default) VALUES
    ('loc_nevera', p_owner_id, 'Nevera', '🧊', true),
    ('loc_armari', p_owner_id, 'Armari', '🚪', true),
    ('loc_calaix', p_owner_id, 'Calaix', '🗄️', true),
    ('loc_congelador', p_owner_id, 'Congelador', '❄️', true),
    ('loc_rebost', p_owner_id, 'Rebost', '🏠', true)
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: quan es crea un perfil, inicialitzar tipus i ubicacions per defecte
CREATE OR REPLACE FUNCTION on_profile_created() RETURNS TRIGGER AS $$
BEGIN
  PERFORM init_default_types(NEW.id);
  PERFORM init_default_locations(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER profile_created_trigger
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION on_profile_created();
