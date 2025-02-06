/*
  # Fix User Progression System

  1. Changes
    - Fix progression order from gifter -> beginner
    - Add proper error handling
    - Improve level progression logic
    - Add logging for progression events
    - Fix role updates during progression

  2. Security
    - Maintain existing RLS policies
    - Add proper error handling
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS check_user_progression ON gifts;
DROP FUNCTION IF EXISTS check_and_progress_user();

-- Create updated function with proper progression logic
CREATE OR REPLACE FUNCTION check_and_progress_user()
RETURNS TRIGGER AS $$
DECLARE
  current_level user_level;
  next_level user_level;
  current_role user_role;
  completed_count integer;
  level_completed boolean;
  progression_id uuid;
BEGIN
  -- Get current user info
  SELECT level, role INTO current_level, current_role
  FROM users
  WHERE id = NEW.receiver_id;

  -- Count completed gifts at current level
  SELECT COUNT(*) INTO completed_count
  FROM gifts
  WHERE receiver_id = NEW.receiver_id
  AND level = current_level
  AND status = 'completed';

  -- Check if user has received 8 gifts at their current level
  IF completed_count >= 8 THEN
    -- Determine next level based on current level
    next_level := CASE current_level
      WHEN 'gifter' THEN 'beginner'::user_level
      WHEN 'beginner' THEN 'apprentice'::user_level
      WHEN 'apprentice' THEN 'advanced'::user_level
      WHEN 'advanced' THEN 'teacher'::user_level
      WHEN 'teacher' THEN 'master'::user_level
      WHEN 'master' THEN 'gifter'::user_level
    END;

    -- Record progression
    INSERT INTO progression (user_id, old_level, new_level)
    VALUES (NEW.receiver_id, current_level, next_level)
    RETURNING id INTO progression_id;
    
    -- Update user level and role
    UPDATE users
    SET 
      level = next_level,
      -- Reset role to gifter when completing master level
      role = CASE 
        WHEN current_level = 'master' AND next_level = 'gifter' THEN 'gifter'::user_role
        ELSE role
      END,
      -- Update timestamp
      updated_at = now()
    WHERE id = NEW.receiver_id;

    -- Log progression
    RAISE NOTICE 'User % progressed from % to %', 
      NEW.receiver_id, 
      current_level, 
      next_level;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error details
    RAISE NOTICE 'Error in progression: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER check_user_progression
AFTER INSERT OR UPDATE ON gifts
FOR EACH ROW
EXECUTE FUNCTION check_and_progress_user();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION check_and_progress_user() TO authenticated;
GRANT USAGE ON SEQUENCE progression_id_seq TO authenticated;
GRANT INSERT ON progression TO authenticated;