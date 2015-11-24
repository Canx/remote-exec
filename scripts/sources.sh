#!/bin/bash
cd /etc/apt
sudo rm -rf /etc/apt/sources.list.d/*
sudo wget -N http://aulainf04-00.local/sources.list
sudo apt-get update
