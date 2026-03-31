{...}: {
  services.caddy.globalConfig = ''
    local_certs
    auto_https disable_redirects
  '';
}
