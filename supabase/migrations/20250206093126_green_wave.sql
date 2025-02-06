/*
  # Fix admin user schema and authentication

  1. Changes
    - Drop and recreate admin user with proper schema
    - Ensure all required fields are present
    - Fix schema querying issues
  
  2. Security
    - Maintains proper authentication setup
    - Preserves data integrity
*/

-- First, clean up any existing admin data
DO $$ 
BEGIN
  -- Clean up existing data
  DELETE FROM auth.users WHERE email = 'admin@gifting.system';
  DELETE FROM public.users WHERE email = 'admin@gifting.system';
  
  -- Create admin in auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'a98be3f0-0000-4000-a000-000000000000',
    'authenticated',
    'authenticated',
    'admin@gifting.system',
    crypt('admin123', gen_salt('bf')),
    now(),
    now(),
    now(),
    jsonb_build_object(
      'provider', 'email',
      'providers', array['email']
    ),
    jsonb_build_object(
      'full_name', 'System Admin'
    ),
    false
  );

  -- Create admin in public.users
  INSERT INTO public.users (
    id,
    full_name,
    email,
    role,
    level,
    referral_code,
    referred_by,
    status
  ) VALUES (
    'a98be3f0-0000-4000-a000-000000000000',
    'System Admin',
    'admin@gifting.system',
    'admin',
    'master',
    'ADMIN_REF_CODE',
    'a98be3f0-0000-4000-a000-000000000000',
    'active'
  );

  -- Ensure RLS policies are in place
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' AND policyname = 'Allow public read access'
  ) THEN
    CREATE POLICY "Allow public read access"
      ON public.users
      FOR SELECT
      TO public
      USING (true);
  END IF;

  -- Ensure email confirmation is disabled
  ALTER TABLE auth.users
  ALTER COLUMN email_confirmed_at
  SET DEFAULT now();

END $$;