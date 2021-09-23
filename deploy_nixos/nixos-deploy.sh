#!/usr/bin/env bash
# nixos-deploy deploys a nixos-instantiate-generated drvPath to a target host
#
# Usage: nixos-deploy.sh <drvPath> <host> <switch-action> [<build-opts>] ignoreme
set -euo pipefail

### Defaults ###

buildArgs=(
  --option extra-binary-caches https://cache.nixos.org/
)
profile=/nix/var/nix/profiles/system
# will be set later
sshOpts=(
  -o "ControlMaster=auto"
  -o "ControlPersist=60"
  # Avoid issues with IP re-use. This disable TOFU security.
  -o "StrictHostKeyChecking=no"
  -o "UserKnownHostsFile=/dev/null"
  -o "GlobalKnownHostsFile=/dev/null"
  # interactive authentication is not possible
  -o "BatchMode=yes"
  # verbose output for easier debugging
  -v
)

###  Argument parsing ###

nix_portable="$1"
NP_LOCATION="$(realpath "$2")"
drvPath="$3"
outPath="$4"
targetHost="$5"
targetPort="$6"
buildOnTarget="$7"
sshPrivateKey="$8"
action="$9"
deleteOlderThan="${10}"
shift 10

export NP_LOCATION

# remove the last argument
set -- "${@:1:$(($# - 1))}"
buildArgs+=("$@")

sshOpts+=( -p "${targetPort}" )

workDir=$(mktemp -d)
trap 'rm -rf "$workDir"' EXIT

if [[ -n "${sshPrivateKey}" && "${sshPrivateKey}" != "-" ]]; then
  sshPrivateKeyFile="$workDir/ssh_key"
  echo "$sshPrivateKey" > "$sshPrivateKeyFile"
  chmod 0700 "$sshPrivateKeyFile"
  sshOpts+=( -o "IdentityFile=${sshPrivateKeyFile}" )
fi

### Functions ###

log() {
  echo "--- $*" >&2
}

copyToTarget() {
  NIX_SSHOPTS="${sshOpts[*]}" "$nix_portable" nix-copy-closure --to "$targetHost" "$@"
}

# assumes that passwordless sudo is enabled on the server
targetHostCmd() {
  # ${*@Q} escapes the arguments losslessly into space-separted quoted strings.
  # `ssh` did not properly maintain the array nature of the command line,
  # erroneously splitting arguments with internal spaces, even when using `--`.
  # Tested with OpenSSH_7.9p1.
  #
  # shellcheck disable=SC2029
  ssh "${sshOpts[@]}" "$targetHost" "./maybe-sudo.sh ${*@Q}"
}

# Setup a temporary ControlPath for this session. This speeds-up the
# operations by not re-creating SSH sessions between each command. At the end
# of the run, the session is forcefully terminated.
setupControlPath() {
  sshOpts+=(
    -o "ControlPath=$workDir/ssh_control"
  )
  cleanupControlPath() {
    local ret=$?
    # Avoid failing during the shutdown
    set +e
    # Close ssh multiplex-master process gracefully
    log "closing persistent ssh-connection"
    ssh "${sshOpts[@]}" -O stop "$targetHost"
    rm -rf "$workDir"
    exit "$ret"
  }
  trap cleanupControlPath EXIT
}

# Fixup nix symlinks
fixupLinks() {
    while IFS= read -r -d '' link; do
        if readlink "$link" | grep ^"$NP_LOCATION"/.nix-portable > /dev/null; then
            newlink=$(readlink "$link" | sed -e "s:$NP_LOCATION/.nix-portable:/nix:")
            if [ -w "$(dirname "$link")" ]; then
                ln -sf "$newlink" "$link"
            else
                chmod +w "$(dirname "$link")"
                ln -sf "$newlink" "$link"
                chmod -w "$(dirname "$link")"
            fi
        fi
    done <   <(find "$NP_LOCATION/.nix-portable/" ./result -type l -print0)
}

### Main ###

fixupLinks

#drvPath=${drvPath//$NP_LOCATION\/.nix-portable/\/nix}
#outPath=${outPath//$NP_LOCATION\/.nix-portable/\/nix}

setupControlPath

if [[ "${buildOnTarget:-false}" == true ]]; then

  # Upload derivation
  log "uploading derivations"
  copyToTarget "$drvPath" --gzip --use-substitutes

  # Build remotely
  log "building on target"
  set -x
  targetHostCmd "nix-store" "--realize" "$drvPath" "${buildArgs[@]}"

else

  # Build derivation
  log "building on deployer"
  outPath=$("$nix_portable" nix-store --realize "$drvPath" "${buildArgs[@]}")

  # Upload build results
  log "uploading build results"
  copyToTarget "$outPath" --gzip --use-substitutes

fi

# Activate
log "activating configuration"
targetHostCmd nix-env --profile "$profile" --set "$outPath"
targetHostCmd "$outPath/bin/switch-to-configuration" "$action"

# Cleanup previous generations
log "collecting old nix derivations"
# Deliberately not quoting $deleteOlderThan so the user can configure something like "1 2 3" 
# to keep generations with those numbers
targetHostCmd "nix-env" "--profile" "$profile" "--delete-generations" $deleteOlderThan
targetHostCmd "nix-store" "--gc"
