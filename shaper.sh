#!/bin/sh
#A network shaping script.
#Useful for testing applications over a simulated slow connection.

usage()
{
cat << EOF
Usage: $0
Example: shaper -a start -i eth0 -d 5120 -u 1000 -l 1 -r kbit -t sec

OPTIONS:
  -h   Show this message.
  -a   The action to take ("-a start", "-a stop", "-a restart", "-a show").
  -i   Interface name to shape ("-i eth0", "-i lo").
  -d   Maximum download speed in mbits ("-d 5" is 5mbit).
  -u   Maximum upload speed in Mbits ("-u 2" is 2mbit).
  -l   Latency to add ("-l 50" split over upload and download, totaling 50ms).
  -r   Rate at which download and upload options operate, defaults to mbit.
  -t   Scale at which latency option operates, defaults to ms.
EOF
}

ACT=
IF=
DWLD=
UPLD=
LAT=
HLAT=
BAND=mbit
TIME=ms
TC=/sbin/tc
IP=/bin/ip

while getopts “ha:i:d:u:l:r:t:” OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    a)
      ACT=$OPTARG
      ;;
    i)
      IF=$OPTARG
      ;;
    d)
      DWLD=$OPTARG
      ;;
    u)
      UPLD=$OPTARG
      ;;
    l)
      LAT=$OPTARG
      let HLAT=$LAT/2
      ;;
    r)
      BAND=$OPTARG
      ;;
    t)
      TIME=$OPTARG
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

if [[ -z $ACT ]]
then
  echo "You must pass an action!"
  usage
  exit 1
fi

if [[ -z $IF ]]
then
  echo "You must pass an interface!"
  usage
  exit 1
fi

start() {

  echo "Starting bandwidth shaping for $IF"

  if [[ -n $DWLD ]] || [[ -n $PING ]]
  then
    FLT="$TC filter add dev $IF parent ffff: protocol ip u32 match u32 0 0"

    $IP link set dev ifb0 up
    $TC qdisc add dev $IF handle ffff: ingress
    $FLT action mirred egress redirect dev ifb0
  fi

  if [[ -n $DWLD ]]
  then
    $TC qdisc add dev ifb0 root handle 1: htb default 10
    $TC class add dev ifb0 parent 1: classid 1:10 htb rate $DWLD$BAND
    echo "Download speed on $IF limited to $DWLD$BAND"
  fi

  if [[ -n $UPLD ]]
  then
    $TC qdisc add dev $IF root handle 1: htb default 10
    $TC class add dev $IF parent 1: classid 1:10 htb rate $UPLD$BAND
    echo "Upload speed on $IF limited to $UPLD$BAND"
  fi

  if [[ -n $LAT ]]
  then
    $TC qdisc add dev $IF parent 1:10 netem delay $HLAT$TIME
    $TC qdisc add dev ifb0 parent 1:10 netem delay $HLAT$TIME
    echo "Latency on $IF increased by $LAT$TIME"
  fi

}

stop() {

  $TC qdisc del dev $IF root 2> /dev/null
  $TC qdisc del dev $IF ingress 2> /dev/null
  $TC qdisc del dev ifb0 root 2> /dev/null
  $IP link set dev ifb0 down 2> /dev/null

  echo "Bandwidth shaping stopped for $IF"

}

restart() {

  stop
  sleep 1
  start

}

show() {

  echo "Bandwidth shaping status for $IF"

  $TC qdisc show dev $IF
  $TC qdisc show dev ifb0

}

case "$ACT" in

  start)

    start
    ;;

  stop)

    stop
    ;;

  restart)

    restart
    ;;

  show)

    show
    ;;

  *)

    pwd=$(pwd)
    echo "Action options {start|stop|restart|show}"
    ;;

esac

exit 0

