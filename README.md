# 🛠️ MSS clamp Cron task for Wireguard interfaces on UCG-Ultra 

This guide walks you through creating a cron job to automatically apply an MSS clamp rule for any wgclt+ (Wireguard) interface on UniFi UCG-Ultra using a shell script.

---

## 📡 Prerequisites

- You **must SSH into your UCG-Ultra**:

```bash
ssh root@<your-ucg-ip>
```

---

## 📁 1. Create the Shell Script

> ⚠️ Cron uses a limited environment — you **must specify full paths** to `ip` and `iptables` inside the script.

### 🔍 Just to make sure `ip` and `iptables` paths are correct:

Run:
```bash
which ip
which iptables
```

Typical results:
```
/sbin/ip
/usr/sbin/iptables
```

Replace those in the script if there are differences.

### 📜 Create the script:

```bash
vim /etc/wg-mss-clamp.sh
```

Paste the following content:

```bash
#!/bin/sh

IP=/sbin/ip # The result of "which ip" command
IPTABLES=/usr/sbin/iptables # The result of "which iptables" command

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
```

Then make it executable:

```bash
chmod +x /etc/wg-mss-clamp.sh
```

---

## ⏰ 2. Add the Cron Job

Edit crontab:

```bash
crontab -e
```

Add this line:

```cron
*/1 * * * * /etc/wg-mss-clamp.sh
```

Cron will run the script every minute. If there's no rule already applied, the script will create it.

---

## 🐛 3. Debugging Tips

### 🔹 Check script logs

```bash
journalctl -t wg-mss-clamp
```

### 🔹 Check iptables rule

```bash
iptables -t mangle -L UBIOS_FORWARD_TCPMSS --line-numbers
```

---

## ✅ Done!

This setup:
- Checks for the `wgclt+` interface
- Applies MSS clamp if missing
- Runs every minute
- Logs only when MSS clamp is applied by running a script

No more manual SSH-ing after each reboot or config change 🎉