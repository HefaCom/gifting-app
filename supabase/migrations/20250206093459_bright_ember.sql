/*
  # Fix admin authentication

  1. Changes
    - Clean up existing admin data
    - Create admin user in auth schema with proper metadata
    - Create admin user in public schema with proper references
    - Set up proper RLS policies for admin access
  
  2. Security
    - Ensures admin user has proper authentication
    - Maintains data integrity
    - Sets up proper access controls
*/

-- First, clean up any existing admin data
DO $$ 
BEGIN
  -- Clean up existing data
  DELETE FROM auth.users WHERE email = 'admin@gifting.system';
  DELETE FROM public.users WHERE email = 'admin@gifting.system';
  
  -- Create admin in auth.users with proper metadata
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
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"System Admin"}',
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
    status
  ) VALUES (
    'a98be3f0-0000-4000-a000-000000000000',
    'System Admin',
    'admin@gifting.system',
    'admin',
    'master',
    'ADMIN_REF_CODE',
    'active'
  );

  -- Temporarily disable the referred_by constraint for admin
  ALTER TABLE public.users 
  DROP CONSTRAINT IF EXISTS users_referred_by_required;

  -- Add back the constraint with admin exception
  ALTER TABLE public.users
  ADD CONSTRAINT users_referred_by_required
  CHECK (
    referred_by IS NOT NULL OR 
    email = 'admin@gifting.system'
  );

  -- Ensure RLS policies allow admin access
  DROP POLICY IF EXISTS "Allow admin full access to users" ON public.users;
  CREATE POLICY "Allow admin full access to users"
    ON public.users
    FOR ALL
    TO authenticated
    USING (
      (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
    )
    WITH CHECK (
      (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
    );

  -- Ensure email confirmation is disabled
  ALTER TABLE auth.users
  ALTER COLUMN email_confirmed_at
  SET DEFAULT now();

END $$;