/*
  # Set up admin user with correct credentials

  1. Changes
    - Create admin user if it doesn't exist
    - Set up admin user with correct password hash
    - Ensure admin role and permissions

  2. Security
    - Uses secure password hashing
    - Maintains existing RLS policies
*/

-- First, ensure the admin user exists with the correct role
DO $$ 
BEGIN
  -- Insert admin user if not exists
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = 'admin@gifting.com'
  ) THEN
    -- Insert into auth.users
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
      confirmation_token,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      'a98be3f0-0000-4000-a000-000000000000',
      'authenticated',
      'authenticated',
      'admin@gifting.com',
      crypt('admin123', gen_salt('bf')), -- Hash the password
      now(),
      now(),
      now(),
      encode(gen_random_bytes(32), 'hex'),
      encode(gen_random_bytes(32), 'hex')
    );

    -- Insert into public.users
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
      'admin@gifting.com',
      'admin',
      'master',
      'ADMIN_REF_CODE1',
      'active'
    );
  END IF;
END $$;