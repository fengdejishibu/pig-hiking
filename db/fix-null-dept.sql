-- Fix existing users with null dept_id that cannot log in
-- Root cause: PigUserDetailsService.getUserDetails() NPEs on null dept
UPDATE sys_user SET dept_id = 1 WHERE dept_id IS NULL AND del_flag = '0';
