/*
  # Fix admin user duplicate key issue

  1. Changes
    - Add proper existence checks before inserting
    - Update admin user if exists instead of inserting
    - Maintain self-referential referred_by
  
  2. Security
    - Preserves existing RLS policies
    - Maintains data integrity
*/

DO $$ 
BEGIN
  -- Check if admin exists in auth.users
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = 'admin@gifting.system'
  ) THEN
    -- Insert into auth.users only if doesn't exist
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
  END IF;

  -- Check if admin exists in public.users
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE email = 'admin@gifting.system'
  ) THEN
    -- Insert into public.users only if doesn't exist
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
  ELSE
    -- Update existing admin user if needed
    UPDATE public.users
    SET 
      role = 'admin',
      level = 'master',
      referral_code = 'ADMIN_REF_CODE',
      referred_by = 'a98be3f0-0000-4000-a000-000000000000',
      status = 'active'
    WHERE email = 'admin@gifting.system';
  END IF;
END $$;