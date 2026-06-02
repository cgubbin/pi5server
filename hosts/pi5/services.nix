{
  config,
  pkgs,
  lib,
  ...
}: let
  lanCidr = "192.168.1.0/24";
  domain = "home.arpa";
in {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "none";
    openFirewall = true;
  };

  services.fail2ban.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/pi5.yaml;
    defaultSopsFormat = "yaml";

    age = {
      # Recommended for a server: host-specific age key stored locally.
      keyFile = "/home/kit/.config/sops/age/keys.txt";
      generateKey = true;
    };

    secrets = {
      "adguard/admin-password-hash" = {
        sopsFile = ../../secrets/pi5.yaml;
        key = "adguard/admin-password-hash";
        path = "/run/secrets/adguard/admin-password-hash";
        owner = "kit";
        group = "users";
        mode = "0400";
      };

      "grafana/admin-password" = {
        sopsFile = ../../secrets/pi5.yaml;
        key = "grafana/admin-password";
        path = "/run/secrets/grafana/admin-password";
        owner = "kit";
        group = "users";
        mode = "0400";
      };

      "syncthing/gui-password" = {
        sopsFile = ../../secrets/pi5.yaml;
        key = "syncthing/gui-password";
        path = "/run/secrets/syncthing/gui-password";
        owner = "kit";
        group = "users";
        mode = "0400";
      };

      # Optional, only needed if you later use Caddy DNS-provider plugins.
      # "caddy/env" = {
      #   owner = "caddy";
      #   group = "caddy";
      #   mode = "0400";
      # };
    };
  };

  services.adguardhome = {
    enable = true;
    openFirewall = true;
    mutableSettings = false;

    settings = {
      http = {
        address = "0.0.0.0:3000"; # IMPORTANT: not just localhost
        session_ttl = "720h";
      };

      users = [
        {
          name = "admin";
          password = builtins.readFile config.sops.secrets."adguard/admin-password-hash".path;
        }
      ];

      auth_attempts = 5;
      block_auth_min = 15;

      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 53;

        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://1.1.1.1/dns-query"
        ];

        bootstrap_dns = ["9.9.9.9" "1.1.1.1"];

        protection_enabled = true;
        blocking_mode = "nxdomain"; # better UX than "default"
        upstream_mode = "load_balance";

        cache_size = 8388608; # 8MB (Pi-safe improvement)
        cache_ttl_min = 300;
        cache_ttl_max = 86400;
        cache_optimistic = true;

        ratelimit = 100; # 20 is too low for LAN bursts

        allowed_clients = [
          "127.0.0.1"
          lanCidr
          "100.64.0.0/10"
        ];
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search = {
          enabled = false;
        };

        rewrites = [
          {
            domain = "*.home.arpa";
            answer = "192.168.1.37";
            enabled = true;
          }
          # {
          #   domain = "grafana.home.arpa";
          #   answer = "192.168.1.37";
          #   enabled = true;
          # }
          # {
          #   domain = "prometheus.home.arpa";
          #   answer = "192.168.1.37";
          #   enabled = true;
          # }
          # {
          #   domain = "syncthing.home.arpa";
          #   answer = "192.168.1.37";
          #   enabled = true;
          # }
        ];
      };

      safebrowsing = {
        enabled = false;
      };

      querylog = {
        enabled = true;
        interval = "720h"; # 30 days is more realistic than 90d memory-heavy logs
        size_memory = 2000;
      };

      statistics = {
        enabled = true;
        interval = "24h";
      };

      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt";
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
        }
      ];

      user_rules = [
        # Example:
        # "||ads.example.com^"
      ];

      dhcp = {
        enabled = false;
      };

      log = {
        file = "";
        max_backups = 2;
        max_size = 50;
        max_age = 7;
        compress = true;
        verbose = false;
      };
    };
  };

  services.prometheus = {
    enable = true;
    enableReload = true;
    listenAddress = "127.0.0.1";
    port = 9090;

    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {targets = ["127.0.0.1:9090"];}
        ];
      }
      {
        job_name = "adguard";
        static_configs = [
          {
            targets = ["127.0.0.1:9618"];
          }
        ];
      }
      {
        job_name = "node";
        static_configs = [
          {targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];}
        ];
      }
      {
        job_name = "caddy";
        static_configs = [
          {
            targets = ["127.0.0.1:2019"];
          }
        ];
      }
    ];
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    openFirewall = false;
    enabledCollectors = ["systemd" "cpu" "meminfo" "filesystem" "loadavg" "netdev"];
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3010;
        domain = "grafana.${domain}";
        root_url = "https://grafana.${domain}/";
      };

      security = {
        admin_user = "admin";
        admin_password = builtins.readFile config.sops.secrets."grafana/admin-password".path;
        cookie_secure = true;
        strict_transport_security = true;
      };

      users = {
        allow_sign_up = false;
      };
    };

    provision = {
      enable = true;

      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
        ];
      };
    };
  };

  services.syncthing = {
    enable = true;
    user = "kit";
    group = "users";
    dataDir = "/home/kit/Sync";
    configDir = "/home/kit/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = false;
    overrideDevices = false;
    overrideFolders = false;
    guiPasswordFile = config.sops.secrets."syncthing/gui-password".path;

    settings = {
      options = {
        localAnnounceEnabled = true;
        relaysEnabled = true;
        urAccepted = -1;
      };

      devices = {};
      folders = {};
    };
  };

  services.caddy = {
    enable = true;
    enableReload = true;

    # If you later switch to public DNS + ACME DNS challenges,
    # point this at a sops secret file.
    # environmentFile = config.sops.secrets."caddy/env".path;

    virtualHosts = {
      "grafana.${domain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3010
        '';
      };

      "prometheus.${domain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:9090
        '';
      };

      "syncthing.${domain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8384
        '';
      };

      "adguard.${domain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3000
        '';
      };
    };
    extraConfig = ''
      reverse_proxy 127.0.0.1:3010
      encode gzip

      tls internal
      metrics
    '';
  };
}
