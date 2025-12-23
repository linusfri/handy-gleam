-- migrate:up
create table product_image (
  product_id integer references products(id) on delete cascade,
  image_id integer references images(id) on delete cascade,
  display_order integer default 0,  -- for ordering multiple images
  primary key (product_id, image_id)
);

-- migrate:down
drop table product_image;