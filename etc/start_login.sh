export ETCPATH=$(cd `dirname $0`; pwd)
export ROOT=$(dirname $ETCPATH)
$ROOT/3rd/skynet/skynet $ETCPATH/login.conf
# $ROOT/co $ETCPATH/login.conf