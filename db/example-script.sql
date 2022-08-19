select * from auth.enable_provider('system', 1, 'aad');
select * from auth.enable_provider('system', 1, 'email');

select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider_code := 'aad', _provider_uid := '123456',
                                    _username := 'ondrej.valenta@keenmate.com', _display_name := 'Ondrej Valenta',
                                    _email := 'ondrej.valenta@keenmate.com', _user_data := null);

select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider_code := 'aad', _provider_uid := '456825',
                                    _username := 'albert.moravec@keenmate.com', _display_name := 'Albert Moravec',
                                    _email := 'albert.moravec@keenmate.com', _user_data := null);

select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider_code := 'aad', _provider_uid := '45682511',
                                    _username := 'filip.jakab@keenmate.com', _display_name := 'Filip Jakab',
                                    _email := 'filip.jakab@keenmate.com', _user_data := null);

select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider_code := 'aad', _provider_uid := '45682132123',
                                    _username := 'jan.rada@keenmate.com', _display_name := 'Jan Rada',
                                    _email := 'jan.rada@keenmate.com', _user_data := null);

select *
from auth.register_user(1, 'lucie.novakova1@keenmate.com', '123456', _display_name := 'Lucie Novakova',
                        _user_data := '{firstName: "Lucie", lastname: "Novakova"}');

select * from auth.get_users_by_provider('system', 1, 'aad');

select *
from unsecure.add_user_to_group_as_system('ondrej.valenta@keenmate.com', 'Tenant admins', 1);

select *
from create_tenant('ondrej.valenta', 2, 'Albert Moravec', _tenant_owner_id := 3);

select *
from assign_tenant_owner('ondrej.valenta', 2, 2, 4);

select *
from auth.create_user_group('filip.jakab', 4, 'Our customers', 2);

select *
from auth.create_user_group_member('albert.moravec', 3, 2, 4, 5);

select *
from create_tenant('ondrej.valenta', 2, 'Jan Rada');

select *
from assign_tenant_owner('ondrej.valenta', 2, 3, 5);

select * from auth.create_user_group_member('jan.rada@keenmate.com', 5, 3, 5, 2);

select * from auth.create_external_user_group('system', 2, 'External group 1', 3, 'aad', _mapped_object_id := 'aaa_rada');

select * from unsecure.create_perm_set_as_system('My external partners', 3, false, true, array ['system.admin', 'system.manage_providers', 'system.manage_permissions']);

select * from unsecure.assign_permission_as_system(3, 6, null, 'my_external_partners');

select * from auth.ensure_groups_and_permissions(1, 6, 3, 'aad', array ['aaa_rada']);


select * from permission_assignment;

select * from perm_set where perm_set_id = 6;
select * from perm_set_perm
         inner join permission p on p.permission_id = perm_set_perm.permission_id
         where perm_set_id = 6
;

-- select * from auth.create_user_group_member('ondrej.valenta@keenmate.com', 2, 3, 6, 6);
-- select * from auth.delete_user_group_member('ondrej.valenta@keenmate.com', 2, 3, 6, 6);

select * from user_info;
select * from user_group;
select * from user_group_member
;

select * from user_groups;

select user_group_id, group_code
                 from user_groups
                 where tenant_id = 3
                   and user_id = 6;

select distinct ep.permission_code as full_code
                               from (select user_group_id, group_code
                 from user_groups
                 where tenant_id = 3
                   and user_id = 6) ug
                                        inner join permission_assignment pa on ug.user_group_id = pa.group_id
                                        inner join effective_permissions ep on pa.perm_set_id = ep.perm_set_id
                               where ep.perm_set_is_assignable = true
                                 and ep.permission_is_assignable = true;

select distinct ep.permission_code as full_code
                              from permission_assignment pa
                                       inner join effective_permissions ep on pa.perm_set_id = ep.perm_set_id
                              where ep.perm_set_is_assignable = true
                                and ep.permission_is_assignable = true
                              union
                              select distinct sp.full_code
                              from permission_assignment pa
                                       inner join auth.permission p on pa.permission_id = p.permission_id
                                       inner join auth.permission sp
                                                  on sp.node_path <@ p.node_path and sp.is_assignable = true
                              where pa.user_id = 6;

select * from user_permission_cache


select distinct 6, ugm.group_id, ugm.ug_mapping_id, false
    from unnest(array['aaa_rada']) g
             inner join public.user_group_mapping ugm
                        on ugm.provider_code = 'aad' and ugm.mapped_object_id = lower(g)
    where ugm.group_id not in (select group_id from user_group_member where user_id = 6);

select *
from create_user_group_as_system('');

select *
from add_journal_msg('ondrej', 1, 1
    , format('User %s assigned new owner: %s to tenant: %s'
                         , 'ondrej', 2, 2)
    , 'tenant', 2
    , array ['target_user_id', 2::text]
    , 50004);


select *
from auth.add_user_to_group('system',)


select *
from tenant;
select *
from user_info;
select *
from user_identity;
select *
from journal
where tenant_id = 2;

select *
from user_group ug
         inner join public.user_group_member ugm on ug.user_group_id = ugm.group_id
         inner join public.user_info ui on ugm.user_id = ui.user_id;

--
select *
from tenant;
-- select * from user_group;
-- select * from auth.perm_set;
-- select * from user_group_assignment;


select *
from has_permissions(1)

select *
from throw_no_permission(1, 2, 'system.a.b');
select *
from throw_no_permission(1, 2, array ['system.a.b', 'd.e.f'])