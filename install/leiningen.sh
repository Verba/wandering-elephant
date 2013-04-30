#!/usr/bin/env bash
# http://leiningen.org/

mkdir ~/leiningen
curl https://raw.github.com/technomancy/leiningen/stable/bin/lein > ~/leiningen/lein
chmod +x ~/leiningen/lein
echo "export PATH=~/leiningen:$PATH" >> ~/.bashrc
source ~/.bashrc
lein version

