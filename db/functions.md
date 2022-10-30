# Features map

## Database functions

| Group                        | Feature                                               | Function                                                                                                             | Permissions | Notice                                                       |
| ---------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------ |
| Database versioning          | Marks version update start                            | start\_version\_update(\_version text, \_title text, \_description text default null)                                |             |                                                              |
| Database versioning          | Marks version end                                     | stop\_version\_update(\_version text)                                                                                |             |                                                              |
| **Helper functions**         |                                                       |                                                                                                                      |             |                                                              |
|                              |                                                       | helpers.random\_string(len integer DEFAULT 36)                                                                       |             |                                                              |
|                              |                                                       | helpers.get\_code(\_title text, \_separator text default '-')                                                        |             |                                                              |
|                              |                                                       | helpers.ltree\_parent(path ext.ltree, levels integer DEFAULT 1)                                                      |             |                                                              |
|                              |                                                       | helpers.trg\_generate\_code\_from\_title()                                                                           |             |                                                              |
| **Unsecure functions**       |                                                       |                                                                                                                      |             |                                                              |
|                              |                                                       | unsecure.update\_permission\_full\_title(\_perm\_path ext.ltree)                                                     |             |                                                              |
|                              |                                                       | unsecure.update\_permission\_full\_code(\_perm\_path ext.ltree)                                                      |             |                                                              |
|                              |                                                       | unsecure.create\_permission\_by\_path\_as\_system(\_title text                                                       |             |                                                              |
|                              |                                                       | unsecure.clear\_permission\_cache(\_deleted\_by text, \_tenant\_id int, \_target\_user\_id bigint)                   |             |                                                              |
|                              |                                                       | unsecure.recalculate\_user\_groups(\_created\_by text,                                                               |             |                                                              |
|                              |                                                       | unsecure.recalculate\_user\_permissions(\_created\_by text, \_tenant\_id int, \_target\_user\_id bigint)             |             |                                                              |
|                              |                                                       | unsecure.create\_primary\_tenant()                                                                                   |             |                                                              |
|                              |                                                       | unsecure.create\_system\_user()                                                                                      |             |                                                              |
|                              |                                                       | unsecure.delete\_user\_by\_username\_as\_system(\_username text)                                                     |             |                                                              |
|                              |                                                       | unsecure.expire\_tokens(\_created\_by text)                                                                          |             |                                                              |
|                              |                                                       | unsecure.add\_user\_group\_member(\_created\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int,    |             |                                                              |
|                              |                                                       | unsecure.add\_user\_to\_group\_as\_system(\_user\_name text, \_group\_title text, \_tenant\_id int default null)     |             |                                                              |
|                              |                                                       | unsecure.assign\_permission(\_created\_by text, \_user\_id bigint, \_tenant\_id int,                                 |             |                                                              |
|                              |                                                       | unsecure.unassign\_permission(\_deleted\_by text, \_user\_id bigint, \_tenant\_id int,                               |             |                                                              |
|                              |                                                       | unsecure.set\_permission\_as\_assignable(\_modified\_by text, \_user\_id bigint,                                     |             |                                                              |
|                              |                                                       | unsecure.assign\_permission\_as\_system(\_tenant\_id int, \_user\_group\_id int, \_target\_user\_id bigint,          |             |                                                              |
|                              |                                                       | unsecure.create\_user\_group(\_created\_by text, \_user\_id bigint, \_title text                                     |             |                                                              |
|                              |                                                       | unsecure.create\_user\_group\_as\_system(\_tenant\_id int, \_title text                                              |             |                                                              |
|                              |                                                       | unsecure.get\_user\_group\_members(\_requested\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int) |             |                                                              |
|                              |                                                       | unsecure.create\_perm\_set(                                                                                          |             |                                                              |
|                              |                                                       | unsecure.create\_perm\_set\_as\_system(                                                                              |             |                                                              |
|                              |                                                       | unsecure.update\_perm\_set(                                                                                          |             |                                                              |
|                              |                                                       | unsecure.add\_perm\_set\_permissions(\_created\_by text, \_user\_id bigint, \_tenant\_id int,                        |             |                                                              |
|                              |                                                       | unsecure.delete\_perm\_set\_permissions(\_deleted\_by text, \_user\_id bigint, \_tenant\_id int,                     |             |                                                              |
|                              |                                                       | unsecure.update\_last\_used\_provider(\_target\_user\_id bigint, \_provider\_code text)                              |             |                                                              |
|                              |                                                       | unsecure.create\_user\_info(\_created\_by text, \_user\_id bigint, \_username text, \_email text,                    |             |                                                              |
|                              |                                                       | unsecure.create\_user\_identity(\_created\_by text, \_user\_id bigint, \_target\_user\_id bigint,                    |             |                                                              |
|                              |                                                       | unsecure.update\_user\_password(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint,                   |             |                                                              |
|                              |                                                       | unsecure.add\_user\_to\_default\_groups(\_created\_by text, \_user\_id bigint, \_target\_user\_id bigint,            |             |                                                              |
| **Public general functions** |                                                       |                                                                                                                      |             |                                                              |
|                              |                                                       | add\_journal\_msg\_jsonb(\_created\_by text, \_tenant\_id int, \_user\_id bigint, \_msg text,                        |             |                                                              |
|                              |                                                       | add\_journal\_msg(\_created\_by text, \_tenant\_id int, \_user\_id bigint, \_msg text,                               |             |                                                              |
|                              |                                                       | get\_journal\_msgs(\_tenant\_id int, \_user\_id int, \_from timestamptz, \_to timestamptz)                           |             |                                                              |
|                              |                                                       | get\_journal\_payload(\_tenant\_id int, \_user\_id int, \_journal\_id bigint)                                        |             |                                                              |
|                              |                                                       | public.assign\_tenant\_owner(\_created\_by text, \_user\_id bigint, \_tenant\_id int, \_target\_user\_id bigint)     |             |                                                              |
|                              |                                                       | public.create\_tenant(\_created\_by text, \_user\_id bigint, \_title text, \_code text default null,                 |             |                                                              |
|                              |                                                       | public.calculate\_roles\_and\_permissions(\_user\_id bigint, \_provider\_groups text[], \_provider\_roles text[])    |             |                                                              |
|                              |                                                       | load\_initial\_data()                                                                                                |             |                                                              |
| **Authorized functions**     |                                                       |                                                                                                                      |             |                                                              |
| Authentication               | Ensure user from external identity provider           |                                                                                                                      |             |                                                              |
| Authentication               | Ensure user's groups and permissions                  |                                                                                                                      |             | Also based on groups and roles coming from identity provider |
| Authentication               | Ensure user's groups and permissions                  |                                                                                                                      |             | Also based on groups and roles coming from identity provider |
|                              |                                                       | unsecure.create\_auth\_event(\_created\_by text, \_user\_id bigint, \_event\_type\_code text,                        |             |                                                              |
|                              |                                                       | auth.throw\_no\_access(\_tenant\_id int, \_username text)                                                            |             |                                                              |
|                              |                                                       | auth.throw\_no\_permission(\_tenant\_id int, \_user\_id bigint, \_perm\_codes text[])                                |             |                                                              |
|                              |                                                       | auth.throw\_no\_permission(\_tenant\_id int, \_user\_id bigint, \_perm\_code text)                                   |             |                                                              |
|                              |                                                       | auth.has\_permissions(\_tenant\_id int, \_target\_user\_id bigint, \_perm\_codes text[],                             |             |                                                              |
|                              |                                                       | auth.has\_permission(\_tenant\_id int, \_target\_user\_id bigint, \_perm\_code text,                                 |             |                                                              |
|                              |                                                       | auth.get\_user\_random\_code()                                                                                       |             |                                                              |
|                              |                                                       | auth.validate\_provider\_is\_active(\_provider\_code text)                                                           |             |                                                              |
|                              |                                                       | auth.create\_provider(\_created\_by text, \_user\_id bigint, \_provider\_code text, \_provider\_name text,           |             |                                                              |
|                              |                                                       | auth.update\_provider(\_modified\_by text, \_user\_id bigint, \_provider\_id int, \_provider\_code text,             |             |                                                              |
|                              |                                                       | auth.delete\_provider(\_deleted\_by text, \_user\_id bigint, \_provider\_code text)                                  |             |                                                              |
|                              |                                                       | auth.get\_provider\_users(\_requested\_by text, \_user\_id bigint, \_provider\_code text)                            |             |                                                              |
|                              |                                                       | auth.enable\_provider(\_modified\_by text, \_user\_id bigint, \_provider\_code text)                                 |             |                                                              |
|                              |                                                       | auth.disable\_provider(\_modified\_by text, \_user\_id bigint, \_provider\_code text)                                |             |                                                              |
|                              |                                                       | auth.create\_auth\_event(\_created\_by text, \_user\_id bigint, \_event\_type\_code text,                            |             |                                                              |
|                              |                                                       | auth.create\_token(\_created\_by text, \_user\_id bigint,                                                            |             |                                                              |
|                              |                                                       | auth.validate\_token(\_modified\_by text, \_user\_id bigint,                                                         |             |                                                              |
|                              |                                                       | auth.set\_token\_as\_used(\_modified\_by text, \_user\_id bigint, \_token\_id bigint,                                |             |                                                              |
|                              |                                                       | auth.set\_permission\_as\_assignable(\_modified\_by text, \_user\_id bigint,                                         |             |                                                              |
|                              |                                                       | auth.assign\_permission(\_created\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int,              |             |                                                              |
|                              |                                                       | auth.unassign\_permission(\_deleted\_by text, \_user\_id bigint, \_tenant\_id int, \_assignment\_id int)             |             |                                                              |
|                              |                                                       | auth.create\_user\_group(\_created\_by text, \_user\_id bigint, \_title text, \_tenant\_id int,                      |             |                                                              |
|                              |                                                       | auth.update\_user\_group(\_modified\_by text, \_user\_id bigint, \_tenant\_id int, \_ug\_id int, \_title text,       |             |                                                              |
|                              |                                                       | auth.enable\_user\_group(\_modified\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int)            |             |                                                              |
|                              |                                                       | auth.disable\_user\_group(\_modified\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int)           |             |                                                              |
|                              |                                                       | auth.lock\_user\_group(\_modified\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int)              |             |                                                              |
|                              |                                                       | auth.unlock\_user\_group(\_modified\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int)            |             |                                                              |
|                              |                                                       | auth.delete\_user\_group(\_deleted\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int)             |             |                                                              |
|                              |                                                       | auth.create\_user\_group\_member(\_created\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int,     |             |                                                              |
|                              |                                                       | auth.delete\_user\_group\_member(\_deleted\_by text, \_user\_id bigint, \_tenant\_id int, \_ug\_id int,              |             |                                                              |
|                              |                                                       | auth.get\_user\_group\_members(\_requested\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int)     |             |                                                              |
|                              |                                                       | auth.create\_user\_group\_mapping(\_created\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int,    |             |                                                              |
|                              |                                                       | auth.delete\_user\_group\_mapping(\_deleted\_by text, \_user\_id bigint, \_tenant\_id int, \_ug\_mapping\_id int)    |             |                                                              |
|                              |                                                       | auth.create\_external\_user\_group(\_created\_by text, \_user\_id bigint, \_title text, \_tenant\_id int,            |             |                                                              |
|                              |                                                       | auth.set\_user\_group\_as\_external(\_modified\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int) |             |                                                              |
|                              |                                                       | auth.set\_user\_group\_as\_hybrid(\_modified\_by text, \_user\_id bigint, \_tenant\_id int, \_user\_group\_id int)   |             |                                                              |
|                              |                                                       | auth.get\_tenants(\_user\_id bigint)                                                                                 |             |                                                              |
|                              |                                                       | auth.get\_tenant\_by\_id(\_tenant\_id int)                                                                           |             |                                                              |
|                              |                                                       | auth.get\_tenant\_users(\_requested\_by text, \_user\_id bigint, \_tenant\_id int)                                   |             |                                                              |
|                              |                                                       | auth.get\_tenant\_groups(\_requested\_by text, \_user\_id bigint, \_tenant\_id int)                                  |             |                                                              |
|                              |                                                       | auth.get\_tenant\_members(\_requested\_by text, \_user\_id bigint, \_tenant\_id int)                                 |             |                                                              |
|                              |                                                       | auth.create\_permission\_by\_path(\_created\_by text, \_user\_id int,                                                |             |                                                              |
|                              |                                                       | auth.create\_permission\_by\_code(\_created\_by text, \_user\_id int, \_title text,                                  |             |                                                              |
|                              |                                                       | auth.create\_perm\_set(                                                                                              |             |                                                              |
|                              |                                                       | auth.update\_perm\_set(                                                                                              |             |                                                              |
|                              |                                                       | auth.add\_perm\_set\_permissions(\_created\_by text, \_user\_id bigint, \_tenant\_id int, \_perm\_set\_id int,       |             |                                                              |
|                              |                                                       | auth.delete\_perm\_set\_permissions(\_created\_by text, \_user\_id bigint, \_tenant\_id int, \_perm\_set\_id int,    |             |                                                              |
|                              |                                                       | auth.enable\_user(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint)                                 |             |                                                              |
|                              |                                                       | auth.disable\_user(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint)                                |             |                                                              |
|                              |                                                       | auth.unlock\_user(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint)                                 |             |                                                              |
|                              |                                                       | auth.lock\_user(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint)                                   |             |                                                              |
|                              |                                                       | auth.enable\_user\_identity(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint,                       |             |                                                              |
|                              |                                                       | auth.disable\_user\_identity(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint,                      |             |                                                              |
|                              |                                                       | auth.ensure\_groups\_and\_permissions(\_created\_by text, \_user\_id bigint, \_target\_user\_id bigint,              |             |                                                              |
|                              |                                                       | auth.update\_user\_password(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint,                       |             |                                                              |
|                              |                                                       | auth.register\_user(\_created\_by text, \_user\_id int, \_email text, \_password\_hash text,                         |             |                                                              |
|                              |                                                       | auth.add\_user\_to\_default\_groups(\_created\_by text, \_user\_id bigint, \_target\_user\_id bigint,                |             |                                                              |
|                              |                                                       | auth.get\_user\_by\_id(\_user\_id bigint)                                                                            |             |                                                              |
|                              |                                                       | auth.get\_user\_identity(\_user\_id bigint, \_target\_user\_id bigint, \_provider\_code text)                        |             |                                                              |
|                              |                                                       | auth.get\_user\_identity\_by\_email(\_user\_id bigint, \_email text, \_provider\_code text)                          |             |                                                              |
|                              |                                                       | auth.get\_user\_by\_email\_for\_authentication(\_user\_id int, \_email text)                                         |             |                                                              |
|                              |                                                       | auth.ensure\_user\_from\_provider(\_created\_by text, \_user\_id bigint, \_provider\_code text,                      |             |                                                              |
|                              |                                                       | auth.update\_user\_data(\_modified\_by text, \_user\_id bigint, \_target\_user\_id bigint, \_provider text,          |             |                                                              |
|                              |                                                       | auth.get\_tenant\_permissions(\_tenant\_id int, \_user\_id bigint)                                                   |             |                                                              |
| **Error raising functions**  |                                                       |                                                                                                                      |             |                                                              |
| Error handling               | Throws 52101 error to stop processing of the function | error.raise\_52101(\_username text)                                                                                  |             |                                                              |
| Error handling               | Throws 52102 error to stop processing of the function | error.raise\_52102(\_normalized\_email text)                                                                         |             |                                                              |
| Error handling               | Throws 52103 error to stop processing of the function | error.raise\_52103(\_user\_id bigint, \_email text default null)                                                     |             |                                                              |
| Error handling               | Throws 52104 error to stop processing of the function | error.raise\_52104(\_user\_id bigint)                                                                                |             |                                                              |
| Error handling               | Throws 52105 error to stop processing of the function | error.raise\_52105(\_user\_id bigint)                                                                                |             |                                                              |
| Error handling               | Throws 52106 error to stop processing of the function | error.raise\_52106(\_email text)                                                                                     |             |                                                              |
| Error handling               | Throws 52107 error to stop processing of the function | error.raise\_52107(\_provider\_code text)                                                                            |             |                                                              |
| Error handling               | Throws 52108 error to stop processing of the function | error.raise\_52108(\_tenant\_id text, \_username text)                                                               |             |                                                              |
| Error handling               | Throws 52109 error to stop processing of the function | error.raise\_52109(\_user\_id bigint, \_tenant\_id int, \_perm\_codes text[])                                        |             |                                                              |
| Error handling               | Throws 52110 error to stop processing of the function | error.raise\_52110(\_user\_id bigint, \_provider\_code text)                                                         |             |                                                              |
| Error handling               | Throws 52111 error to stop processing of the function | error.raise\_52111(\_user\_id bigint, \_provider\_code text)                                                         |             |                                                              |
| Error handling               | Throws 52112 error to stop processing of the function | error.raise\_52112(\_user\_id bigint)                                                                                |             |                                                              |
| Error handling               | Throws 52171 error to stop processing of the function | error.raise\_52171(\_user\_group\_id int)                                                                            |             |                                                              |
| Error handling               | Throws 52172 error to stop processing of the function | error.raise\_52172(\_user\_group\_id int)                                                                            |             |                                                              |
| Error handling               | Throws 52173 error to stop processing of the function | error.raise\_52173(\_user\_group\_id int)                                                                            |             |                                                              |
| Error handling               | Throws 52174 error to stop processing of the function | error.raise\_52174()                                                                                                 |             |                                                              |
| Error handling               | Throws 52175 error to stop processing of the function | error.raise\_52175(\_perm\_set\_code text)                                                                           |             |                                                              |
| Error handling               | Throws 52176 error to stop processing of the function | error.raise\_52176(\_perm\_set\_code text)                                                                           |             |                                                              |
| Error handling               | Throws 52177 error to stop processing of the function | error.raise\_52177(\_perm\_set\_id int, \_tenant\_id int)                                                            |             |                                                              |
| Error handling               | Throws 52178 error to stop processing of the function | error.raise\_52178()                                                                                                 |             |                                                              |
| Error handling               | Throws 52271 error to stop processing of the function | error.raise\_52271(\_user\_group\_id int)                                                                            |             |                                                              |
| Error handling               | Throws 52272 error to stop processing of the function | error.raise\_52272()                                                                                                 |             |                                                              |
| Error handling               | Throws 52273 error to stop processing of the function | error.raise\_52273()                                                                                                 |             |                                                              |
| Error handling               | Throws 52274 error to stop processing of the function | error.raise\_52274()                                                                                                 |             |                                                              |
| Error handling               | Throws 52275 error to stop processing of the function | error.raise\_52275(\_permission\_full\_code text)                                                                    |             |                                                              |
| Error handling               | Throws 52276 error to stop processing of the function | error.raise\_52276()                                                                                                 |             |                                                              |
| Error handling               | Throws 52277 error to stop processing of the function | error.raise\_52277()                                                                                                 |             |                                                              |
| Error handling               | Throws 52278 error to stop processing of the function | error.raise\_52278(\_token\_uid text)                                                                                |             |                                                              |
| Error handling               | Throws 52279 error to stop processing of the function | error.raise\_52279(\_token\_uid text)                                                                                |             |                                                              |

## Security

| Event code | Description                       |
| ---------- | --------------------------------- |
| 50001      | Tenant created                    |
| 50002      | Tenant updated                    |
| 50003      | Tenant deleted                    |
| 50004      | Assign tenant owner               |
| 50005      | Get tenant users                  |
| 50006      | Get tenant groups                 |
| 50011      | Provider created                  |
| 50012      | Provider updated                  |
| 50013      | Provider deleted                  |
| 50014      | Provider enabled                  |
| 50015      | Provider disabled                 |
| 50016      | Get provider users                |
| 50101      | User created                      |
| 50102      | User updated                      |
| 50103      | User deleted                      |
| 50104      | User enabled                      |
| 50105      | User disabled                     |
| 50106      | User unlocked                     |
| 50107      | User locked                       |
| 50108      | User identity enabled             |
| 50109      | User identity disabled            |
| 50131      | User added to group               |
| 50133      | User deleted from group           |
| 50134      | User identity created             |
| 50135      | User identity deleted             |
| 50136      | User password changed             |
| 50201      | Group created                     |
| 50202      | Group updated                     |
| 50203      | Group deleted                     |
| 50204      | Group enabled                     |
| 50205      | Group disabled                    |
| 50206      | Group unlocked                    |
| 50207      | Group locked                      |
| 50208      | Group set as external group       |
| 50209      | Group set as hybrid group         |
| 50210      | User requested group members list |
| 50231      | Group mapping created             |
| 50233      | Group mapping deleted             |
| 50301      | Permission set created            |
| 50302      | Permission set updated            |
| 50303      | Permission set deleted            |
| 50304      | Permission assigned               |
| 50305      | Permission unassigned             |
| 50306      | Permission assignability changed  |
| 50311      | Permissions added to perm set     |
| 50313      | Permissions removed from perm set |
| 50401      | Token created                     |
| 50402      | Token validated                   |
| 50403      | Token set as used                 |

## Security Error codes

| Event code | Description                                                                           |
| ---------- | ------------------------------------------------------------------------------------- |
| 52101      | Cannot ensure user for email provider                                                 |
| 52102      | User cannot register user because the identity is already in use                      |
| 52103      | User does not exist                                                                   |
| 52104      | User is a system user                                                                 |
| 52105      | User is not active                                                                    |
| 52106      | User is locked                                                                        |
| 52107      | Provider is not active                                                                |
| 52108      | User has no access to tenant                                                          |
| 52109      | User has no correct permission in tenant                                              |
| 52110      | User provider identity is not active                                                  |
| 52111      | User provider identity does not exist                                                 |
| 52112      | User is not supposed to log in                                                        |
| 52171      | User group not found                                                                  |
| 52172      | User cannot be added to group because the group is not active                         |
| 52173      | User cannot be added to group because it's either not assignable or an external group |
| 52174      | Either mapped object id or role must not be empty                                     |
| 52175      | Permission set is not assignable                                                      |
| 52176      | Permission is not assignable                                                          |
| 52177      | Permission set is not defined in tenant                                               |
| 52178      | Some permission is not assignable                                                     |
| 52271      | User group cannot be deleted because it's a system group                              |
| 52272      | Either user group id or target user id has to be not null                             |
| 52273      | Either permission set code or permission code has to be not null                      |
| 52274      | Either permission id or code has to be not null                                       |
| 52275      | Permission does not exist                                                             |
| 52276      | The same token is already used                                                        |
| 52277      | Token does not exist                                                                  |
| 52278      | Token is not valid or has expired                                                     |
| 52279      | Token was created for different user                                                  |


