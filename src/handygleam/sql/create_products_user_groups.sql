insert into product_user_group (product_id, user_group_id, created_at)
select p.product_id, g.user_group_id, now()
from unnest($1::int[]) as p(product_id)
cross join unnest($2::text[]) as g(user_group_id);