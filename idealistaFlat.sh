#!/bin/bash

#### MANUAL ####################################################################
# NAME
#   idealistaFlat.sh - parses idealista.com flats and outputs its data in a sort of CSV format
#
# SYNOPSIS
#   idealistaFlat.sh code [ code2 code3 code4 ... ]
#
# EXAMPLE
#   idealistaFlat.sh VP0000004207764 VP0000004207884 VW0000003534007
#
# AUTHOR
# Written by STenyaK <stenyak@stenyak.com>.
#
# COPYRIGHT
# Copyright © 2011 Bruno Gonzalez.  License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
# This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
#
# REPORTING BUGS
# This script is known to work on Mint and Ubuntu.
# Please report bugs to <stenyak@stenyak.com>.
#
# The latest version of this script can hopefully be obtained by emailing the author.
#
#### SETTINGS ####################################################################
# some hardcoded values you can override in settings.sh file
sitioGeneral=""
direccionCurro=""
outfile=""
connections=""

function setColors
{
    export RESET="\033[00m"
    export GREEN="\033[01;32m"
    export WHITE="\033[01;37m"
    export YELLOW="\033[01;33m"
    export RED="\033[01;31m"
}
function checkErr
{
    # Checks the error code, and displays the error message and exits if error was found (err != 0)
    local err=$1
    local msg=$2
    local quit=$3
    setColors
    if [ "$err" -ne "0" ]; then
        logerror "$msg"
        if [ "$quit" == "false" ]; then
            return $err
        else
            exit $err
        fi
    fi
}
function logerror
{
    # Displays the desired error message
    local msg=$*              # error message to display
    setColors
    echo -e " $RED>>>>>$WHITE Error!$RESET $msg"
}
function logwarning
{
    # Displays the desired warning message
    local msg=$*              # warning message to display
    echo -e " $YELLOW>>>>>$WHITE Warning!$RESET $msg"
}
function loginfo
{
    # Displays the desired info message
    local msg=$*              # info message to display
    setColors
    echo -e " $GREEN>>>>>$RESET $msg"
}
function checkDep
{
    local cmd=$1
    local msg="Command '$cmd' is missing. Please install and retry."
    msg="$msg Use your package manager to install it. E.g.: sudo apt-get install $cmd"
    which $cmd &>/dev/null
    checkErr $? "$msg" false
    return $?
}
function checkDeps
{
    # Checks all necessary tools are installed
    local deps="$*"     # list of dependencies to check
    local error="0"
    for dep in $deps
    do
        checkDep $dep
        if [ $? -ne 0 ]; then error="1"; fi
    done
    return $error
}
escapeRegexp="s/á/a/g;s/é/e/g;s/í/i/g;s/ó/o/g;s/ú/u/g;s/Á/A/g;s/É/E/g;s/Í/I/g;s/Ó/O/g;s/Ú/U/g"
function escapeUrl
{
    echo $1 |sed "$escapeRegexp" |sed "s/\ /+/g"
}
function getFootTravelTime
{
    local origen="$1"
    local destino="$2"
    local sitioGeneral="$3"
    # escape stuff
    local origen=$(escapeUrl "$origen, $sitiogeneral")
    local destino=$(escapeUrl "$destino, $sitioGeneral")
    local url="http://maps.google.com/maps?f=d&source=s_d&saddr=$origen&daddr=$destino&hl=en&mra=ltm&dirflg=r&ttype=dep&date=03/23/11&time=7:32pm&noexp=0&noal=0&sort=def&sll=40.407091,-3.651323&sspn=0.037711,0.076904&ie=UTF8&ll=40.407222,-3.651838&spn=0.037711,0.076904&t=h&z=14&start=0"
    echo $(( $(curl --silent "$url" | html2text |grep -m 1 --before 10000 "^Travel time" |grep "^About [0-9]" | sed "s/About //g;s/ .*//g" |tr "\n" "+")0 ))
}
function getTotalTravelTime
{
    local origen="$1"
    local destino="$2"
    local sitioGeneral="$3"
    # escape stuff
    local origen=$(escapeUrl "$origen, $sitiogeneral")
    local destino=$(escapeUrl "$destino, $sitioGeneral")
    local url="http://maps.google.com/maps?f=d&source=s_d&saddr=$origen&daddr=$destino&hl=en&mra=ltm&dirflg=r&ttype=dep&date=03/23/11&time=7:32pm&noexp=0&noal=0&sort=def&sll=40.407091,-3.651323&sspn=0.037711,0.076904&ie=UTF8&ll=40.407222,-3.651838&spn=0.037711,0.076904&t=h&z=14&start=0"
    curl --silent "$url" | html2text |grep --after 1 "1. 1." |tail -n 1 |sed "s/^\s*//g;s/\s.*//g"
}
function cachePiso
{
    local piso=$1
    local cache=$2
    local urlBase="http://www.idealista.com/pagina/inmueble?codigoinmueble="
    curl --silent $urlBase$piso | html2text | sed "$escapeRegexp" > $cache
    curl --silent $urlBase$piso | html2text > $cache
}
function getFrase
{
    local palabra=$1
    local frase=$2
    echo $frase | sed "s/.*[\.\,]\([^\.\,]*$palabra[^\.\,]*\)[\.\,].*/\1/g;s/\"//g;s/,/-/g"
}
function escape
{
    local text="$*"
    echo $text |sed "s/\,//g;s/\"//g;s/'//g" |sed "s/^\ *\s*//g;s/\ *\s*$//g"
}
function getCsv
{
    local piso=$1
    local outfile=$2

    local cache=$(tempfile -p "idealista.")
    local ok="false"
    local eurmes=""
    while [ "$eurmes" == "" ]
    do
        cachePiso $piso $cache
        eurmes=$(cat $cache |grep "eur\/mes, " |sed "s/\ eur.*//g")
        if [ "$eurmes" == "" ]
        then
            logwarning "Lost connection to flat $piso data. Retrying..."
            logwarning "(if this problem persists, try lowering the 'connections' setting)"
        fi
    done

    local dormitorios=$(cat $cache |grep "[0-9]\ dormitorios" |head -n 1|sed "s/\ dormitorios//g")
    local banos=$(cat $cache |grep "[0-9]\ wc$" |sed "s/\ wc//g")
    local metros=$(cat $cache |grep "eur\/mes, " |sed "s/.*mes, //g;s/\ .*//g")
    local planta=$(cat $cache |grep "^\(bajo\|planta\|entreplanta\)" |sed "s/bajo/0/g;s/entreplanta/0.5/g;s/planta //g;s/planta //g;s/[^0-9]*ascensor//g" |grep -v " "|head -n 1)
    local aire=$((0$(cat $cache |grep "^aire acondicionado" |sed "s/aire.*/1/g")))
    local aval=$(cat $cache |grep -i aval >/dev/null && echo "0" || echo "1")
    local ascensor=$((0$(cat $cache |grep "con ascensor$" |sed "s/.*con ascensor/1/g" |head -n 1)))
    local armarios=$((0$(cat $cache |grep "^[0-9] armario[s]* empotrado[s]*$" |sed "s/ .*//g")))
    local garaje=$(cat $cache |grep "plaza de garaje incluida en el precio$" |sed "s/\ plaza de garaje incluida.*//g")
    if [ "$garaje" == "" ]; then garaje="$(getFrase "araje" "$(cat $cache |grep -i garaje)")"; fi
    if [ "$garaje" == "" ]; then garaje=0; fi
    local garaje=$(escape $garaje)
    local comision=$(echo $piso |grep "VW" >/dev/null && echo "0" || (cat $cache |grep "sin comisiones" >/dev/null && echo "0" || echo "1"))
    local amueblado=$(cat $cache |grep amueblado >/dev/null && echo "1" || echo "0")
    local comunidad=$(cat $cache |grep "comunidad incluida en el alquiler" >/dev/null && echo "0" || (cat $cache |grep " eur al mes de gastos de comunidad$" | sed "s/\ eur al mes de gastos de comunidad//g"))
    if [ "$comunidad" == "" ]; then comunidad=$(cat $cache |grep -i "comunidad inclu" >/dev/null && echo "0" || getFrase "omunidad" "$(cat $cache |grep -i comunidad)"); fi
    if [ "$comunidad" == "" ]; then comunidad="n/a"; fi
    local distrito=$(cat $cache |grep "^distrito" |sed "s/distrito //g")
    local piscina=$(cat $cache |grep -i "piscina" >/dev/null && echo "1" || echo "0")
    local direccion=$(cat $cache | grep "^piso en" |sed "s/^piso en //g;s/,//g")
    local traveltime=$(getTotalTravelTime "$direccion" "$direccionCurro" "$sitioGeneral")
    local foottime=$(getFootTravelTime "$direccion" "$direccionCurro" "$sitioGeneral")
    local totaleur=$eurmes
    if [ "$comision" == "1" ]; then totaleur=$(( $totaleur + ($eurmes*118/100/12) )); fi
    if [ "$garaje" != "1" ]; then totaleur=$(( $totaleur + 110 )); fi
    if [[ "$comunidad" =~ ^[0-9]+$ ]] ; then totaleur=$(( $totaleur + $comunidad )); fi

    echo "$piso, $dormitorios, $banos, $armarios, $metros, $planta, $ascensor, $aire, $garaje, $comision, $aval, $amueblado, $comunidad, $distrito, $piscina, $direccion, $traveltime, $foottime, $totaleur, $eurmes" >> $outfile
    rm -f $cache
}
function checkSettings
{
    if [ -x "settings.sh" ]
    then
        diff settings_example.sh settings.sh >/dev/null && checkErr 1 "Please customize your settings.sh file!"
        . ./settings.sh
    else
        cp settings_example.sh settings.sh
        chmod +x settings.sh
        logerror "Please customize your settings.sh file!"
        exit 1
    fi
}

function checkParams
{
    if [ -z $1 ]
    then
        logerror "Pon el codigo de piso o pisos"
        exit 1
    fi
}

checkDeps html2text curl sed grep tempfile tr
checkErr $? "Missing dependencies. Stopping..."
checkSettings
checkParams $*
n=0
echo "piso, dormitorios, banos, armarios, metros, planta, ascensor, aire, garaje, comision, aval, amueblado, comunidad, distrito, piscina, direccion, traveltime, foottime, totaleur, eurmes" > $outfile
for i in $*
do
    piso=$i
    if [ "$(($n % $connections))" -eq "0" ]
    then
        wait
        loginfo "Processing flat $n ($(($# - $n)) remaining)"
    fi
    n=$(($n+1))  
    getCsv $piso $outfile &
done
wait

cat $outfile | sort > $outfile.tmp
mv $outfile.tmp $outfile
loginfo "All your flats information is stored at $outfile"
