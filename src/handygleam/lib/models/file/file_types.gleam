import gleam/option.{type Option}
import handygleam/sql

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
    filetype: FileType,
    context_type: sql.ContextTypeEnum,
  )
}

pub type FileUploadRequest {
  FileUploadRequest(
    data: String,
    filename: String,
    filetype: FileType,
    context: ContextType,
  )
}
