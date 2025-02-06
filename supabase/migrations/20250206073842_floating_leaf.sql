/*
  # Add referral code requirement
  
  1. Changes
    - Add check constraint to users table to ensure referred_by is not null
    - Add check constraint to referrals table to ensure referred_id is not null
  
  2. Security
    - No changes to existing RLS policies
*/

-- Add check constraint to users table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'users_referred_by_required'
  ) THEN
    ALTER TABLE users
    ADD CONSTRAINT users_referred_by_required
    CHECK (referred_by IS NOT NULL);
  END IF;
END $$;

-- Add check constraint to referrals table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'referrals_referred_id_required'
  ) THEN
    ALTER TABLE referrals
    ADD CONSTRAINT referrals_referred_id_required
    CHECK (referred_id IS NOT NULL);
  END IF;
END $$;