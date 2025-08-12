{ lib, stdenv, makeWrapper, bash, curl, jq, coreutils, gawk, gnugrep }:

stdenv.mkDerivation rec {
  pname = "cloudflare-ddns";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ bash curl jq coreutils gawk gnugrep ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp cloudflare-ddns.sh $out/bin/cloudflare-ddns
    chmod +x $out/bin/cloudflare-ddns

    wrapProgram $out/bin/cloudflare-ddns \
      --prefix PATH : ${lib.makeBinPath [ bash curl jq coreutils gawk gnugrep ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Lightweight Cloudflare DDNS script";
    longDescription = ''
      A lightweight script for updating Cloudflare DNS records automatically.
      Supports IPv4 and IPv6, multiple records, smart monitoring, automatic caching,
      multiple authentication methods, proxy support, systemd integration,
      Telegram notifications, CSV logging, and hook commands.
    '';
    homepage = "https://github.com/fernvenue/cloudflare-ddns";
    license = licenses.bsd3;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "cloudflare-ddns";
  };
}