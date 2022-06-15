-- create role keen_auth_sample with password 'Protect yourself with KeenAuth' login;

SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'keen_auth_sample'
  AND pid <> pg_backend_pid();

drop database if exists keen_auth_sample;
create database keen_auth_sample with owner keen_auth_sample;

-----------------------------------------------------
-- !!!!! SWITCH TO keen_auth_sample database !!!!! --
-----------------------------------------------------

create schema if not exists unsecure; -- functions without any permission validation
create schema if not exists helpers;
create schema if not exists ext;
create schema if not exists auth;

alter default privileges
    in schema public
    grant select, insert, update, delete on tables to keen_auth_sample;
alter default privileges
    in schema public, helpers, ext, unsecure grant usage, select on sequences to keen_auth_sample;

alter role keen_auth_sample set search_path to public, const, ext, helpers, unsecure, auth;
set search_path = public, const, ext, stage, helpers, unsecure, auth;
ALTER DATABASE keen_auth_sample SET search_path TO public, ext, stage, helpers, unsecure;