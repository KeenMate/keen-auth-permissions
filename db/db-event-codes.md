# Database event codes 


## Common

| Event code  | Description |
| ------------- | ------------- |
| 50003  | Permission denied  |


## Security

| Event code  | Description |
| ------------- | ------------- |
| 50001  | Tenant created  |
| 50002  | Tenant updated  |
| 50003  | Tenant deleted  |
| 50004  | Assign tenant owner  |
| 50011  | Provider created |
| 50012  | Provider updated  |
| 50013  | Provider deleted  |
| 50014  | Provider enabled |
| 50015  | Provider disabled |
| 50016  | Get provider users |
| 50101  | User created  |
| 50102  | User updated  |
| 50103  | User deleted  |
| 50104  | User identity created  |
| 50105  | User identity deleted  |
| 50131  | User added to group  |
| 50133  | User deleted from group  |
| 50201  | Group created  |
| 50202  | Group updated  |
| 50203  | Group deleted  |
| 50204  | Group enabled  |
| 50205  | Group disabled  |
| 50206  | Group unlocked  |
| 50207  | Group locked  |
| 50208  | Group set as external group  |
| 50209  | Group set as hybrid group |
| 50231  | Group mapping created  |
| 50233  | Group mapping deleted  |
| 50301  | Permission set created |
| 50302  | Permission set updated |
| 50303  | Permission set deleted |
| 50304  | Permission assigned |
| 50305  | Permission unassigned |

## Security Error codes
| Event code  | Description |
| ------------- | ------------- |
| 52101  | Cannot ensure user for email provider |
| 52102  | User cannot register user because the identity is already in use  |
| 52103  | User does not exist  |
| 52104  | User is a system user  |
| 52105  | User is in inactive state  |
| 52106  | User is locked  |
| 52107  | Provider is not active |
| 52171  | User group not found  |
| 52172  | User cannot be added to group because the group is not active  |
| 52173  | User cannot be added to group because it's either not assignable or an external group  |
| 52174  | Either mapped object id or role must not be empty  |
| 52175  | Permission set is not assignable  |
| 52271  | User group cannot be deleted because it's a system group  |
| 52272  | Either user group id or target user id has to be not null  |
| 52273  | Either permission set code or permission code has to be not null  |

