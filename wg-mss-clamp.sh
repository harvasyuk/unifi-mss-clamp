#!/bin/sh

IP=/sbin/ip
IPTABLES=/usr/sbin/iptables

# Check if any wgclt* interface exists
if ! $IP link show | grep -q "wgclt"; then
    exit 0
fi

# Add MSS clamp rule if not present
$IPTABLES -t mangle -C UBIOS_FORWARD_TCPMSS -o wgclt+ -p tcp --tcp-flags SYN,RST SYN \
  -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || {
  $IPTABLES -t mangle -A UBIOS_FORWARD_TCPMSS -o wgclt+ -p tcp --tcp-flags SYN,RST SYN \
    -j TCPMSS --clamp-mss-to-pmtu
  logger -t wg-mss-clamp "MSS clamp rule added to wgclt+"
}