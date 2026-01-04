{ ... }:
{
  config = {
    env = {
      SECRET_KEY = "";
      FACEBOOK_BASE_URL = "";
      FACEBOOK_APP_ID = "";
      FACEBOOK_REDIRECT_URI = "";
      FACEBOOK_STATE_PARAM = "";
      FACEBOOK_APP_SECRET = "";
      CLOUDFLARE_TUNNEL_TOKEN = "IN DEPLOYMENTS REPO. RUN 'tofu output -raw cloudflare_tunnel_token_friikod'";
    };
  };
}