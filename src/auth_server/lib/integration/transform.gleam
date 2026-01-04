import auth_server/lib/integration/types.{type FacebookToken, FacebookToken}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json

pub fn facebook_token_to_json(facebook_token: FacebookToken) -> json.Json {
  let FacebookToken(access_token:, token_type:) = facebook_token
  json.object([
    #("access_token", json.string(access_token)),
    #("token_type", json.string(token_type)),
  ])
}

pub fn facebook_token_decoder(token_data: dynamic.Dynamic) {
  let facebook_token_decoder = {
    use access_token <- decode.field("access_token", decode.string)
    use token_type <- decode.field("token_type", decode.string)
    decode.success(FacebookToken(access_token:, token_type:))
  }

  decode.run(token_data, facebook_token_decoder)
}
