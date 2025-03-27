#自身节点信息
export CLUSTER_NODE="login"
export CLUSTER_IP="127.0.0.1"
export CLUSTER_PORT="57002"

#master节点信息
export MASTER_NODE_NAME="master"
export MASTER_NODE_IP="127.0.0.1"
export MASTER_NODE_PORT="57000"

#服务器ID
export SERVER_ID=1

export ETCPATH=$(cd `dirname $0`; pwd)
export ROOT=$(dirname $ETCPATH)

touch etc/cluster_${CLUSTER_NODE}${SERVER_ID}.lua
$ROOT/3rd/skynet/skynet $ETCPATH/login.conf
# $ROOT/co $ETCPATH/login.conf