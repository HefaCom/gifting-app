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
    -- Check if all users at current level have completed
    SELECT COUNT(*) = 0 INTO level_completed
    FROM users u
    WHERE u.level = current_level
    AND (
      SELECT COUNT(*)
      FROM gifts g
      WHERE g.receiver_id = u.id
      AND g.level = current_level
      AND g.status = 'completed'
    ) < 8;

    -- Only progress if all users at current level are complete
    IF level_completed THEN
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
      VALUES (NEW.receiver_id, current_level, next_level);
      
      -- Update user level and role
      UPDATE users
      SET 
        level = next_level,
        role = CASE 
          WHEN current_role = 'funder' AND next_level = 'gifter' THEN 'gifter'
          ELSE role
        END
      WHERE id = NEW.receiver_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER check_user_progression
AFTER INSERT OR UPDATE ON gifts
FOR EACH ROW
EXECUTE FUNCTION check_and_progress_user();

-- Grant necessary permissions
GRANT INSERT ON progression TO authenticated;