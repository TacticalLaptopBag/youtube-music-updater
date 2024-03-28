which apt > /dev/null
APT_EXIT=$?

set -e

if [ $APT_EXIT -eq 0 ]
then
    echo "===================================="
    echo "Apt detected. Installing packages..."
    echo "===================================="
    echo
    apt update -y
    apt install -y lua5.3 liblua5.3-dev luarocks libyaml-dev
else
    echo "===================================================================="
    echo "WARN: Apt not detected. Manual installation of packages is required."
    echo "WARN: See depends.txt"
    echo "===================================================================="
    echo
fi

echo
echo "==============================="
echo "Installing luarocks packages..."
echo "==============================="
echo
luarocks install penlight
luarocks install luasocket
luarocks install lyaml

echo "======================="
echo "Downloading json.lua..."
echo "======================="
echo
curl -O https://raw.githubusercontent.com/rxi/json.lua/master/json.lua

echo
echo "Done!"
