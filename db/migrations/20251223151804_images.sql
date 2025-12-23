-- migrate:up
create table images (
  id serial primary key,
  filename varchar(255) not null,  -- just the filename: "product_1234.png"
  deleted boolean default false,
  created_at timestamp default current_timestamp
);

-- migrate:down
drop table images;