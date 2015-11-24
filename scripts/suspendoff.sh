usuarios=( alumno )
for usuario in "${usuarios[@]}"; do
   su -c "dbus-launch gsettings set org.gnome.settings-daemon.plugins.power button-suspend 'nothing'" -s /bin/sh ${usuario}
done
