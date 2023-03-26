#!/bin/sh
set -e
PROGNAME=$(basename $0)
die() {
    echo "$PROGNAME: $*" >&2
    exit 1
}
usage() {
    if [ "$*" != "" ] ; then
        echo "Error: $*"
    fi
    cat << EOF

Usage: $PROGNAME [OPTION ...] [foo] [bar]

-------------------------------------------------------------
|  CLI tool for Edgebox for command-line based setup tasks  |
-------------------------------------------------------------

Options:
-h, --help          display this usage message and exit
-s, --setup         execute initial setup script
-u, --update        update edgebox components by pulling from source
-o, --output [FILE] write output to file

EOF
    exit 1
}

install_edgeboxctl(){
    echo ""
    echo "--> Installing edgeboxctl"
    echo ""
    cd /home/system/components/
    cd edgeboxctl && make build-prod && cd ..
    cp ./edgeboxctl/edgeboxctl.service /lib/systemd/system/edgeboxctl.service
    sudo cp ./edgeboxctl/bin/edgeboxctl /usr/local/sbin/edgeboxctl
    sudo systemctl daemon-reload
}

install_cloudflared() {
    echo ""
    echo "--> Installing cloudflared"
    echo ""
    wget -q https://github.com/cloudflare/cloudflared/releases/download/2023.3.1/cloudflared-linux-armhf.deb
    sudo dpkg -i cloudflared-linux-armhf.deb
}


install_buster_backports() {
    echo ""
    echo "--> Installing buster-backports and libseccomp2"
    echo ""
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138
    echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee -a /etc/apt/sources.list.d/buster-backports.list
    sudo apt update
    sudo apt install -t buster-backports libseccomp2
}

foo=""
bar=""
setup=0
output="-"
while [ $# -gt 0 ] ; do
    case "$1" in
    -h|--help)
        usage
        ;;
    -u|--update)
        update=1
        echo ""
        echo "--> Updating Edgebox components"
        echo ""
        cd /home/system/components/
        cd edgeboxctl
        echo "----> Updating edgeboxctl"
        cd /home/system/components/
        cd edgeboxctl
        git pull
        sudo systemctl stop edgeboxctl
	    install_edgeboxctl
        echo "----> Updating WS"
        cd /home/system/components/
        cd ws
        git pull
        cd ../api
        echo "----> Updating API"
        git pull
        echo "----> Building and Restarting Services"
        cd /home/system/components/
        cd ws
        ./ws -b
        ;;
    -s|--setup)
        setup=1
        if [ -e /home/system/components/.installed ]; then
            echo "File exists! Skipping Components Installation"
        else
            echo "File does not exist. Installing component dependencies"
            sleep 60
            key_name="github_key"
            pubkey_name="github_key.pub"
            key_found=0
            for f in home/system/.ssh/ ; do
                FILE="$key_name"
                if test -f "$FILE"; then
                    key_found=1
                    echo "Setting up GitHub SSH key in home/system/.ssh/$FILE"
                    eval "$(ssh-agent -s)"
                    ssh-add home/system/.ssh/github_key
                fi
            done
            echo ""
            echo "--> Initializing Edgebox Setup Script"
            echo ""
            install_buster_backports
            echo "----> Installing Docker:"
            echo ""
            curl -ksSL https://get.docker.com | sh
            echo ""
            echo "----> Installing Docker Compose:"
            echo ""
            sudo pip3 -v install docker-compose
            echo ""
            echo ""
            echo "----> Settting up edgebox-iot/ws"
            echo ""
            mkdir /home/system/components
            git config --global credential.helper cache # Set git to use the credential memory cache
            git config --global credential.helper 'cache --timeout=3600' # Set the cache to timeout after 1 hour (setting is in seconds)
            cd /home/system/components
            if [ $key_found != 0 ]; then
                git clone git@github.com:edgebox-iot/ws.git
            else
                git clone https://github.com/edgebox-iot/ws.git
            fi
            chmod 757 ws
            cd ws
            mkdir appdata
            touch /home/system/components/ws/assets/installing.html
            sudo chmod -R 777 appdata/
            ./ws -b
            cd ..
            echo "----> Installing yq:"
            echo ""
            sudo pip3 -v install yq
            echo ""
            echo "----> Installing Go:"
            export GOLANG="$(curl https://go.dev/dl/|grep armv6l|grep -v beta|head -1|awk -F\> {'print $3'}|awk -F\< {'print $1'})"
            wget https://golang.org/dl/$GOLANG
            sudo tar -C /usr/local -xzf $GOLANG
            rm $GOLANG
            unset GOLANG
            echo "" >> /home/system/.profile
            echo "export PATH=\$PATH:/usr/local/go/bin" >> /home/system/.profile
            export PATH=$PATH:/usr/local/go/bin
            echo ""
            echo "----> Setting up edgebox-iot/edgeboxctl"
            echo ""
            if [ $key_found != 0 ]; then
                git clone git@github.com:edgebox-iot/edgeboxctl.git
            else
                git clone https://github.com/edgebox-iot/edgeboxctl.git
            fi
            echo ""
            echo "----> Settting up edgebox-iot/api"
            echo ""
            if [ $key_found != 0 ]; then
                git clone git@github.com:edgebox-iot/api.git
            else
                git clone https://github.com/edgebox-iot/api.git
            fi
                echo ""
            echo "----> Setting up edgebox-iot/apps"
            if [ $key_found != 0 ]; then
                git clone git@github.com:edgebox-iot/apps.git
            else
                git clone https://github.com/edgebox-iot/apps.git
            fi
            echo ""
            echo "----> Building Reverse Proxy and Service Containers Configs"
            echo ""
            cd ws
            ./ws -b
            echo ""
            echo "----> Installing edgeboxctl"
            echo ""
            install_edgeboxctl
            install_cloudflared
            echo ""
            echo "----> Starting Edgeboxctl"
            sudo systemctl enable edgeboxctl
            sudo systemctl start edgeboxctl
            rm /home/system/components/ws/assets/installing.html
            touch /home/system/components/.installed
            echo ""
            echo "---------------------------"
            echo "| Edgebox Setup Finished  |"
            echo "---------------------------"
            echo ""
        fi
        ;;
    -o|--output)
        output="$2"
        shift
        ;;
    -*)
        usage "Unknown option '$1'"
        ;;
    *)
        if [ -z "$foo" ] ; then
            foo="$1"
        elif [ -z "$bar" ] ; then
            bar="$1"
        else
            usage "Too many arguments"
        fi
        ;;
    esac
    shift
done
if [ -z "$bar" ] ; then
    usage "Not enough arguments"
fi
cat <<EOF
foo=$foo
bar=$bar
delete=$delete
output=$output
EOF
