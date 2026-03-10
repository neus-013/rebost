-- ============================================
-- Migració: Suport per a verificació d'email
-- Executa això al SQL Editor de Supabase
-- ============================================

-- Trigger que crea automàticament el perfil quan un usuari es registra.
-- Això és necessari perquè amb "Confirm email" activat, l'usuari no té
-- sessió fins que verifica el correu, i per tant no pot inserir el perfil
-- directament (RLS ho bloqueja). El trigger s'executa com a SECURITY DEFINER
-- i bypassa RLS.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Crear perfil a partir de les metadades del registre
  INSERT INTO public.profiles (id, name, username, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Usuari'),
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.id::text),
    NEW.email
  );

  -- Notificació de benvinguda
  INSERT INTO public.notifications (user_id, title, message, type)
  VALUES (
    NEW.id,
    'Benvingut/da!',
    'Hola ' || COALESCE(NEW.raw_user_meta_data->>'name', 'Usuari') ||
      '! Benvingut/da a Rebost. Comença afegint productes al teu rebost.',
    'info'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger que s'executa quan es crea un usuari a auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
