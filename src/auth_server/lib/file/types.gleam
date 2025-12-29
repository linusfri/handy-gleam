import auth_server/sql
import gleam/option.{type Option}

pub type File {
  File(
    id: Option(Int),
    data: Option(String),
    filename: String,
    file_type: FileType,
    context_type: sql.ContextTypeEnum,
    uri: Option(String),
  )
}

pub type FileType =
  sql.FileTypeEnum

pub type ContextType =
  sql.ContextTypeEnum

pub type CreatedFile {
  CreatedFile(
    filename: String,
    file_type: FileType,
    context_type: sql.ContextTypeEnum,
  )
}

pub type FileUploadRequest {
  FileUploadRequest(
    data: String,
    filename: String,
    mimetype: FileType,
    context: ContextType,
  )
}
