pub type FacebookToken {
  FacebookToken(access_token: String, token_type: String)
}

pub type FacebookPage {
  FacebookPage(access_token: String, id: String, name: String)
}

pub type FacebookPagesResponse {
  FacebookPagesResponse(data: List(FacebookPage))
}
