/*
  # Add second admin user

  1. Changes
    - Add a second admin user with email admin@app.com
    - Set up proper authentication and access
  
  2. Security
    - Maintains data integrity
    - Sets up proper access controls
*/

DO $$ 
BEGIN
  -- Create second admin in auth.users
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = 'admin@app.com'
  ) THEN
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
      'b98be3f0-0000-4000-a000-000000000000',
      'authenticated',
      'authenticated',
      'admin@app.com',
      crypt('admin123', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Second Admin"}',
      false
    );

    -- Create second admin in public.users
    INSERT INTO public.users (
      id,
      full_name,
      email,
      role,
      level,
      referral_code,
      status
    ) VALUES (
      'b98be3f0-0000-4000-a000-000000000000',
      'Second Admin',
      'admin@app.com',
      'admin',
      'master',
      'ADMIN2_REF_CODE',
      'active'
    );
  END IF;
END $$;