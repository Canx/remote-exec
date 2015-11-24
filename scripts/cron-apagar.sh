rm -f /etc/cron.d/shutdown
echo "0 22 * * * root /sbin/shutdown -P now" > /etc/cron.d/shutdown
