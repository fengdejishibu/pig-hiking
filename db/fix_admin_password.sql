USE pig;
UPDATE sys_user SET password='$2a$10$c/Ae0pRjJtMZg3BnvVpO.eIK6WYWVbKTzqgdy3afR7w.vd.xi3Mgy', salt='' WHERE username='admin';
