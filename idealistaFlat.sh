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

function cachePiso
{
    local piso=$1
    local cache=$2
    local urlBase="http://www.idealista.com/pagina/inmueble?codigoinmueble="
    curl --silent $urlBase$piso | html2text > $cache
}
function getFrase
{
    local palabra=$1
    local frase=$2
    echo $frase | sed "s/.*[\.\,]\([^\.\,]*$palabra[^\.\,]*\)[\.\,].*/\1/g"
}
function escape
{
    local text="$*"
    echo $text |sed "s/\,//g;s/\"//g;s/'//g" |sed "s/^\ *\s*//g;s/\ *\s*$//g"
}
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
function loginfo
{
    # Displays the desired info message
    local msg=$*              # info message to display
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
function getCsv
{
    local piso=$1
    local cache="/tmp/idealista.$piso.tmp"
    cachePiso $piso $cache

    local dormitorios=$(cat $cache |grep "[0-9]\ dormitorios" |head -n 1|sed "s/\ dormitorios//g")
    local banos=$(cat $cache |grep "[0-9]\ wc$" |sed "s/\ wc//g")
    local eurmes=$(cat $cache |grep "eur\/mes, " |sed "s/\ eur.*//g")
    local metros=$(cat $cache |grep "eur\/mes, " |sed "s/.*mes, //g;s/\ .*//g")
    local planta=$(cat $cache |grep "^\(bajo\|planta\|entreplanta\)" |sed "s/bajo/0/g;s/entreplanta/0.5/g;s/planta //g;s/planta //g;s/[^0-9]*ascensor//g" |grep -v " "|head -n 1)
    local aire=$((0$(cat $cache |grep "^aire acondicionado" |sed "s/aire.*/1/g")))
    local ascensor=$((0$(cat $cache |grep "con ascensor" |sed "s/.*con ascensor/1/g" |head -n 1)))
    local garaje=$(cat $cache |grep "plaza de garaje incluida en el precio$" |sed "s/\ plaza de garaje incluida.*//g")
    if [ "$garaje" == "" ]; then garaje="$(getFrase "araje" "$(cat $cache |grep -i garaje)")"; fi
    if [ "$garaje" == "" ]; then garaje=0; fi
    local garaje=$(escape $garaje)
    local comision=$(echo $piso |grep "VW" >/dev/null && echo "0" || (cat $cache |grep "sin comisiones" >/dev/null && echo "0" || echo "1"))
    local amueblado=$(cat $cache |grep amueblado >/dev/null && echo "1" || echo "0")
    local comunidad=$(cat $cache |grep "comunidad incluida en el alquiler" >/dev/null && echo "0" || (cat $cache |grep " eur al mes de gastos de comunidad$" | sed "s/\ eur al mes de gastos de comunidad//g"))
    if [ "$comunidad" == "" ]; then comunidad=$(cat $cache |grep -i "comunidad inclu" >/dev/null && echo "0" || getFrase "comunidad" "$(cat $cache |grep -i comunidad)"); fi
    if [ "$comunidad" == "" ]; then comunidad="n/a"; fi
    #zona TODO
    local piscina=$(cat $cache |grep -i "piscina" >/dev/null && echo "1" || echo "0")

    echo "piso=$piso, m2=$metros, eur/mes=$eurmes, comision=$comision, comunidad=$comunidad, planta=$planta, ascensor=$ascensor, dormitorios=$dormitorios, baños=$banos, amueblado=$amueblado, aire=$aire, garaje=$garaje, piscina=$piscina"
}
if [ -z $1 ]
then
    echo "Pon el codigo de piso o pisos"
    exit 0
fi

checkDeps html2text curl sed grep 
for i in $*
do
    piso=$i
    getCsv $piso
    #exit 0
done

