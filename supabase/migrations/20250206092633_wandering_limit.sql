/*
  # Fix admin user creation and constraints

  1. Changes
    - Drop and recreate admin user with correct email
    - Set admin as self-referential for referred_by
    - Update admin role and permissions
  
  2. Security
    - Maintains existing RLS policies
    - Preserves data integrity constraints
*/

-- First, remove existing admin user if exists
DELETE FROM auth.users WHERE email = 'admin@gifting.com';
DELETE FROM public.users WHERE email = 'admin@gifting.com';

-- Create admin user in auth.users
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'a98be3f0-0000-4000-a000-000000000000',
  'authenticated',
  'authenticated',
  'admin@gifting.system',
  crypt('admin123', gen_salt('bf')),
  now(),
  now(),
  now()
);

-- Create admin user in public.users with self-referential referred_by
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
  'a98be3f0-0000-4000-a000-000000000000', -- Self-referential
  'active'
);