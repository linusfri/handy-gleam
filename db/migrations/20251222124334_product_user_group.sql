-- migrate:up
create table product_user_group (
  id serial primary key,
  product_id int not null references products(id) on delete cascade,
  user_group_id varchar(255) not null,
  created_at timestamp default now(),
  unique(product_id, user_group_id)
);

create index idx_product_user_groups_product_id on product_user_group(product_id);
create index idx_product_user_groups_user_group_id on product_user_group(user_group_id);

-- migrate:down
drop table product_user_group;