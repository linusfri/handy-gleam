import gleam/option.{type Option}
import handygleam/lib/models/file/file_types.{type File}
import handygleam/sql.{type ProductStatus}

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
