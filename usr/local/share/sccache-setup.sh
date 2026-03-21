#!/bin/bash
set -euxo pipefail

mkdir -p /var/cache/sccache
chown root:portage /var/cache/sccache
chmod 2775 /var/cache/sccache

