#!/bin/bash
cd /tmp
wget http://aulainf01-00.local/minecraft.tar.gz .
tar xvf ./minecraft.tar.gz
mv /tmp/.minecraft /home/alumno
sudo chown alumno:alumno -R /home/alumno/.minecraft/
