select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider := 'aad', _provider_uid := '123456',
                                    _username := 'ondrej.valenta@keenmate.com', _display_name := 'Ondrej Valenta',
                                    _email := 'ondrej.valenta@keenmate.com', _user_data := null);

select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider := 'aad', _provider_uid := '456825',
                                    _username := 'albert.moravec@keenmate.com', _display_name := 'Albert Moravec',
                                    _email := 'albert.moravec@keenmate.com', _user_data := null);

select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider := 'aad', _provider_uid := '45682511',
                                    _username := 'filip.jakab@keenmate.com', _display_name := 'Filip Jakab',
                                    _email := 'filip.jakab@keenmate.com', _user_data := null);

select *
from auth.ensure_user_from_provider(_created_by := 'system', _provider := 'aad', _provider_uid := '45682132123',
                                    _username := 'jan.rada@keenmate.com', _display_name := 'Jan Rada',
                                    _email := 'jan.rada@keenmate.com', _user_data := null);

select *
from auth.register_user(1, 'lucie.novakova1@keenmate.com', '123456', _display_name := 'Lucie Novakova',
                        _user_data := '{firstName: "Lucie", lastname: "Novakova"}');

-- select * from auth.get_user_by_email_for_authentication(1, 'Lucie.Novakova@keenmate.com');

select *
from unsecure.add_user_to_group_as_system('ondrej.valenta@keenmate.com', 'Tenant admins', 1);

select *
from create_tenant('ondrej.valenta', 2, 'Albert Moravec', _tenant_owner_id := 3);

select *
from assign_tenant_owner('ondrej.valenta', 2, 2, 4);

select *
from create_user_group('filip.jakab', 4, 'Our customers', 2);

select *
from auth.add_user_group_member('albert.moravec', 3, 2, 4, 5);

select *
from create_tenant('ondrej.valenta', 2, 'Jan Rada');

select *
from assign_tenant_owner('ondrej.valenta', 2, 3, 5);


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