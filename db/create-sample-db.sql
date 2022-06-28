-- create role keen_auth_sample with password 'Protect yourself with KeenAuth' login;

SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'keen_auth_sample'
  AND pid <> pg_backend_pid();

drop database if exists keen_auth_sample;
create database keen_auth_sample with owner keen_auth_sample;
