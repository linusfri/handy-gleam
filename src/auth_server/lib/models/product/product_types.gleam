import auth_server/lib/models/file/file_types.{type File}
import auth_server/sql.{type ProductStatus}
import gleam/option.{type Option}

pub type FacebookProduct {
  FacebookProduct(
    id: Int,
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    images: List(File),
  )
}
