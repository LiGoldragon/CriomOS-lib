_:

# criomos-lib — Sema-style namespace of shared helpers consumed by
# CriomOS and CriomOS-home. Keep names flat. No type-suffixed names.
#
# Most magnitude / list helpers that used to live here are now derived
# fields on horizon-rs Node / User (horizon.node.size.atLeastMed etc.),
# so this library is intentionally small.

let
  inherit (builtins)
    fromJSON
    readFile
    toJSON
    ;

  systemd = rec {
    stateDirectory = "/var/lib";
    runtimeDirectory = "/run";
    dynamicUserStateDirectory = stateDirectory + "/private";
    dynamicUserRuntimeDirectory = runtimeDirectory + "/private";
  };
in
{
  constants = {
    fileSystem = {
      nix = {
        stateDirectory = "/etc/nix";
        preCriad = "/etc/nix/preCriad";
      };

      inherit systemd;

      yggdrasil = rec {
        subDirName = "yggdrasil";
        stateDirectory = systemd.dynamicUserStateDirectory + "/" + subDirName;

        runtimeDirectory = systemd.runtimeDirectory + "/" + subDirName;

        pubKeyJson = runtimeDirectory + "/pubKey.json";
        preCriadJson = stateDirectory + "/preCriad.json";
        combinedConfigJson = stateDirectory + "/combinedConfig.json";

        interfaceName = "yggTun";
      };

      nordvpn.privateKeyFile = "/etc/nordvpn/privateKey";

      complex = {
        dir = "/etc/criomOS/complex";
        keyFile = "/etc/criomOS/complex/key.pem";
        sshPubFile = "/etc/criomOS/complex/ssh.pub";
      };

      wifiPki = {
        caCertFile = "/etc/criomOS/wifi-pki/ca.pem";
        certsDir = "/etc/criomOS/wifi-pki";
        serverDir = "/etc/criomOS/wifi-server";
        serverCertFile = "/etc/criomOS/wifi-server/server.pem";
        serverKeyFile = "/etc/criomOS/wifi-server/server.key";
      };

      home = rec {
        screenshotDirectory = "Pictures/Screenshots";
        ensuredDirectories = [
          screenshotDirectory
        ];
      };
    };

    network = {
      ula48Suffix.wifi = rec {
        subnet = ":1000:1000";
        address = subnet + ":1000::";
        radvdPrefix = subnet + "::/64";
      };

      yggdrasil = rec {
        subnet = "200::";
        prefix = 7;
        namespace = subnet + "/" + (toString prefix);
        ports = {
          multicast = 9001;
          linkLocalTCP = 10001;
        };
      };

      # `lan` LAN subnet/gateway constants moved to horizon — see
      # `horizon.cluster.lan` (typed `LanNetwork { cidr, gateway,
      # dhcpPool, leasePolicy }`). CriomOS network/router modules
      # read directly from horizon; CriomOS-lib does not carry a
      # cluster-LAN literal.

      nat64.pool = rec {
        subnet = "64:ff9b::";
        prefix = 96;
        full = subnet + "/" + (toString prefix);
      };

      nix = {
        serve.ports = {
          external = 5000;
          internal = 4999;
        };

        store.http.ports.external = 8000;
      };
    };
  };

  # ─── JSON helpers ────────────────────────────────────────────────────

  importJSON = filePath: fromJSON (readFile filePath);

  # Deep-merge a nix-declared JSON object into a mutable settings file.
  # Nix-declared keys win; user-added keys are preserved.
  #
  # KNOWN LIMITATION: jq's `*` operator is a *shallow* merge — nested
  # objects get replaced wholesale. User edits inside nested keys
  # (e.g. VSCodium's `"[python]": { ... }`) are lost. Replacement is
  # tracked as CriomOS-bb5 (criomos-cfg side-repo with proper 3-way
  # merge + drift reporting).
  mkJsonMerge =
    {
      lib,
      pkgs,
      file,
      nixSettings,
    }:
    let
      nixJsonFile = pkgs.writeText "nix-settings.json" (toJSON nixSettings);
      jq = "${pkgs.jq}/bin/jq";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="${file}"
      mkdir -p "$(dirname "$target")"
      if [ -f "$target" ]; then
        ${jq} -s '.[0] * .[1]' "$target" ${nixJsonFile} > "$target.tmp"
        mv "$target.tmp" "$target"
      else
        cp ${nixJsonFile} "$target"
      fi
    '';
}
