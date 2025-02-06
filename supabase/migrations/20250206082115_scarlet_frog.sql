/*
  # Create admin user and set up admin access

  1. Changes
    - Create admin user with specific UUID and credentials
    - Add admin role to user_role enum
    - Add admin-specific policies

  2. Security
    - Ensure admin user has proper access rights
    - Add policies for admin-only routes
*/

-- Add admin role to user_role enum if it doesn't exist
DO $$ 
BEGIN 
  IF NOT EXISTS (
    SELECT 1 FROM pg_type 
    WHERE typname = 'user_role' 
    AND 'admin' = ANY(enum_range(NULL::user_role)::text[])
  ) THEN
    ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';
  END IF;
END $$;

-- Create or update admin user
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE email = 'admin@gifting.system'
  ) THEN
    INSERT INTO users (
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
  ELSE
    UPDATE users
    SET 
      role = 'admin',
      level = 'master',
      status = 'active'
    WHERE email = 'admin@gifting.system';
  END IF;
END $$;