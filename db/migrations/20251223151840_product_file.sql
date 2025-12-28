-- migrate:up
create table product_file (
  product_id integer references products(id) on delete cascade,
  file_id integer references files(id) on delete cascade,
  display_order integer default 0,  -- for ordering multiple images
  primary key (product_id, file_id)
);

-- migrate:down
drop table product_file;