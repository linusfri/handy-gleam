-- migrate:up
create table file_user_group (
  id serial primary key,
  file_id int not null references files(id) on delete cascade,
  user_group_id varchar(255) not null,
  created_at timestamp default now(),
  unique(file_id, user_group_id)
);

create index idx_file_user_groups_file_id on file_user_group(file_id);
create index idx_file_user_groups_user_group_id on file_user_group(user_group_id);

-- migrate:down
drop table file_user_group;
