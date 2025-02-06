/*
  # Fix User Progression Function

  1. Changes
    - Fix syntax error in check_and_progress_user() function
    - Improve CTE structure for next level calculation
    - Maintain all existing functionality
*/

-- Drop existing function and trigger
DROP TRIGGER IF EXISTS check_user_progression ON gifts;
DROP FUNCTION IF EXISTS check_and_progress_user();

-- Recreate function with fixed syntax
CREATE OR REPLACE FUNCTION check_and_progress_user()
RETURNS TRIGGER AS $$
DECLARE
  current_level user_level;
  next_level user_level;
BEGIN
  -- Get current level
  SELECT level INTO current_level
  FROM users
  WHERE id = NEW.receiver_id;

  -- Check if user has received 8 gifts at their current level
  IF (
    SELECT COUNT(*)
    FROM gifts
    WHERE receiver_id = NEW.receiver_id
    AND level = current_level
    AND status = 'completed'
  ) >= 8 THEN
    -- Determine next level
    next_level := CASE current_level
      WHEN 'beginner' THEN 'apprentice'::user_level
      WHEN 'apprentice' THEN 'advanced'::user_level
      WHEN 'advanced' THEN 'teacher'::user_level
      WHEN 'teacher' THEN 'master'::user_level
      WHEN 'master' THEN 'gifter'::user_level
      ELSE current_level
    END;

    -- Record progression
    INSERT INTO progression (user_id, old_level, new_level)
    VALUES (NEW.receiver_id, current_level, next_level);
    
    -- Update user level
    UPDATE users
    SET level = next_level
    WHERE id = NEW.receiver_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER check_user_progression
AFTER INSERT OR UPDATE ON gifts
FOR EACH ROW
EXECUTE FUNCTION check_and_progress_user();