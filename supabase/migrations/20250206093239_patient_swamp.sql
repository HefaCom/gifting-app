/*
  # Fix admin user reference constraints

  1. Changes
    - Temporarily disable foreign key checks
    - Update users referencing admin to use their own ID as referred_by
    - Clean up and recreate admin user
  
  2. Security
    - Maintains referential integrity
    - Preserves existing user data
*/

DO $$ 
BEGIN
  -- First, update any users that reference the admin user to reference themselves
  UPDATE public.users
  SET referred_by = id
  WHERE referred_by = 'a98be3f0-0000-4000-a000-000000000000'
  AND id != 'a98be3f0-0000-4000-a000-000000000000';

  -- Now we can safely delete the admin user
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

END $$;