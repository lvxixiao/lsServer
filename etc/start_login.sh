export ROOT=$(cd `dirname $0`; pwd)
export SKYNETROOT=$(dirname "$PWD")"/3rd/skynet"
$SKYNETROOT/skynet $ROOT/etc/login.conf