/*
  # Fix admin authentication

  1. Changes
    - Properly set up admin user in auth.users with correct password
    - Ensure admin exists in public.users with correct configuration
    - Clean up any potential duplicate entries
  
  2. Security
    - Sets up proper authentication credentials
    - Maintains data integrity
*/

DO $$ 
BEGIN
  -- First, clean up any potential duplicate entries
  DELETE FROM auth.users WHERE email = 'admin@gifting.system';
  
  -- Create admin in auth.users with proper password
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
    is_super_admin,
    confirmed_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'a98be3f0-0000-4000-a000-000000000000',
    'authenticated',
    'authenticated',
    'admin@gifting.system',
    crypt('admin123', gen_salt('bf')), -- Set password to 'admin123'
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"System Admin"}',
    false,
    now()
  );

  -- Update or insert admin in public.users
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
  )
  ON CONFLICT (email) DO UPDATE 
  SET 
    role = 'admin',
    level = 'master',
    referral_code = 'ADMIN_REF_CODE',
    referred_by = 'a98be3f0-0000-4000-a000-000000000000',
    status = 'active';
END $$;