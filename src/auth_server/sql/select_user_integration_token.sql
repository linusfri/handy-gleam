-- name: select_user_integration_token
select *
from user_integration_tokens
where
    user_id = $1
    and platform = $2
limit 1;