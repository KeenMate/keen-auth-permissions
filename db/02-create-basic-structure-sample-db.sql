/***
 *    ███████╗██╗    ██╗██╗████████╗ ██████╗██╗  ██╗    ███████╗ ██████╗██╗  ██╗███████╗███╗   ███╗ █████╗
 *    ██╔════╝██║    ██║██║╚══██╔══╝██╔════╝██║  ██║    ██╔════╝██╔════╝██║  ██║██╔════╝████╗ ████║██╔══██╗
 *    ███████╗██║ █╗ ██║██║   ██║   ██║     ███████║    ███████╗██║     ███████║█████╗  ██╔████╔██║███████║
 *    ╚════██║██║███╗██║██║   ██║   ██║     ██╔══██║    ╚════██║██║     ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══██║
 *    ███████║╚███╔███╔╝██║   ██║   ╚██████╗██║  ██║    ███████║╚██████╗██║  ██║███████╗██║ ╚═╝ ██║██║  ██║
 *    ╚══════╝ ╚══╝╚══╝ ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝
 *
 */

create schema if not exists error;
create schema if not exists const;
create schema if not exists unsecure; -- functions without any permission validation
create schema if not exists helpers;
create schema if not exists ext;
create schema if not exists auth; 

alter default privileges
    in schema public, auth, const
    grant select, insert, update, delete on tables to keen_auth_sample;
alter default privileges
    in schema public, helpers, ext, unsecure grant usage, select on sequences to keen_auth_sample;

alter role keen_auth_sample set search_path to public, const, ext, helpers, unsecure, auth;
set search_path = public, const, ext, helpers, unsecure, auth;
ALTER DATABASE keen_auth_sample SET search_path TO public, ext, helpers, unsecure;
