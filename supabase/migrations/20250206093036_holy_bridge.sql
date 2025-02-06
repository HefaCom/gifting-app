/*
  # Fix admin authentication without confirmed_at

  1. Changes
    - Remove confirmed_at from INSERT as it's a generated column
    - Properly set up admin user in auth.users
    - Ensure admin exists in public.users
  
  2. Security
    - Maintains proper authentication setup
    - Preserves data integrity
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
    is_super_admin
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
    false
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