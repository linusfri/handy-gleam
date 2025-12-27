-- migrate:up
create type context_type_enum as enum ('user', 'product', 'misc');

create table files (
  id serial primary key,
  filename varchar(255) not null,  -- just the filename: "product_1234.png"
  file_type varchar(50) not null,  -- e.g., "image/png"
  context_type context_type_enum not null,  -- Determines directory structure: user/, product/, or misc/
  deleted boolean default false,
  created_at timestamp default current_timestamp,
  unique (filename, file_type, context_type)
);

-- migrate:down
drop table files;
drop type context_type_enum;