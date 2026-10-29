#!/usr/bin/env bash

set -euo pipefail

echo "Deployment of the Worker on Linux. Prerequisites:"
echo "    - ArmoniK must be already deployed locally"
echo "    - kubectl and jq must be installed"
echo ""

# Set current directory to the current script location
cd "$(dirname "$0")"

Project="DynamicWorkerExample"
Version="1.0.0.0"
pathToBinaries="./publish/$Project/$Version"

if [ -d "$pathToBinaries" ]; then
  # Remove binaries from any previous build
  rm -rf "${pathToBinaries:?}"/*
fi

zipName="$Project-v$Version.zip"
zipPath="./packages/$zipName"
if [ -f "$zipPath" ]; then
  echo "Remove existing zip file"
  rm "$zipPath"
fi

# Trigger compilation of the worker
echo "Build and publish worker"
dotnet publish --self-contained -c Release -r linux-x64 -f net10.0 .

# Find control-plane IP and gRPC port.
# The ingress service is named "ingress" by the Terraform deployment and "armonik-ingress" by the Helm one.
ingress=$(kubectl -n armonik get service ingress armonik-ingress --ignore-not-found -o json | jq '.items[0] // empty')
if [ -z "$ingress" ]; then
  echo "No ingress service found in namespace armonik"
  exit 1
fi
IP=$(echo "$ingress" | jq -r '.status.loadBalancer.ingress[0].ip')
port=$(echo "$ingress" | jq '(.spec.ports | map(select(.name | endswith("grpc"))) | .[0].port) // .spec.ports[-1].port')
url="http://$IP:$port"

# Write the control-plane url in appsettings client
appSettingsPath="../UsageExample/appsettings.json"
if ! appSettings=$(jq --arg url "$url" '.Grpc.EndPoint = $url' "$appSettingsPath"); then
  echo "Unexpected error (syntax error?) while parsing $appSettingsPath"
  exit 1
fi

echo "Set control plane url $url to $appSettingsPath"
echo "$appSettings" > "$appSettingsPath"
