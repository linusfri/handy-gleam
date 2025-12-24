insert into product_image (product_id, image_id, display_order)
select $1, image_id, row_number() over () - 1
from unnest($2::int[]) as image_id;