# Block distracting sites system-wide by resolving them to a null address in /etc/hosts.
# /etc/hosts is consulted before any DNS server (including Tailscale MagicDNS), so this
# holds for every app. Turning it off requires a rebuild, which is the point.
{ lib, config, ... }: let
  cfg = config.myHome.focus;

  # /etc/hosts has no wildcards, so expand each domain with the subdomains actually in use.
  subdomains = [ "" "www." "m." "mobile." "api." "app." "i." "l." "web." "music." "old." "new." "gql." ];
  hostnames = lib.concatMap (domain: map (sub: sub + domain) subdomains) cfg.domains;
in {
  options.myHome.focus = {
    enable = lib.mkEnableOption "blocking of distracting websites" // { default = true; };
    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # YouTube
        "youtube.com" "youtu.be" "youtube-nocookie.com" "youtubei.googleapis.com"
        # Instagram
        "instagram.com" "cdninstagram.com" "instagr.am"
        # TikTok
        "tiktok.com" "tiktokv.com" "tiktokcdn.com"
        # Reddit
        "reddit.com" "redd.it" "redditmedia.com" "redditstatic.com"
        # X / Twitter
        "x.com" "twitter.com" "t.co" "twimg.com"
        # Facebook
        "facebook.com" "fb.com" "fbcdn.net"
        # Twitch
        "twitch.tv" "ttvnw.net"
      ];
      description = "Domains (plus common subdomains) to block.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.hosts = {
      "0.0.0.0" = hostnames;
      "::" = hostnames;
    };
  };
}
