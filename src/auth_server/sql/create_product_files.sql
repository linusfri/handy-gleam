insert into product_file (product_id, file_id, display_order)
select $1, file_id, row_number() over () - 1
from unnest($2::int[]) as file_id;