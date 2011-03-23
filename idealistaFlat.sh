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
    piso=$1
    cache=$2
    urlBase="http://www.idealista.com/pagina/inmueble?codigoinmueble="
    curl --silent $urlBase$piso | html2text > $cache
}

function getFrase
{
    palabra=$1
    frase=$2
    echo $frase | sed "s/.*[\.\,]\([^\.\,]*$palabra[^\.\,]*\)[\.\,].*/\1/g"
}
cache="/tmp/idealista.tmp"
if [ -z $1 ]
then
    echo "Pon el codigo de piso o pisos"
    exit 0
fi

for i in $*
do
    piso=$i
    cachePiso $piso $cache
    dormitorios=$(cat $cache |grep "[0-9]\ dormitorios" |head -n 1|sed "s/\ dormitorios//g")
    banos=$(cat $cache |grep "[0-9]\ wc$" |sed "s/\ wc//g")
    eurmes=$(cat $cache |grep "eur\/mes, " |sed "s/\ eur.*//g")
    metros=$(cat $cache |grep "eur\/mes, " |sed "s/.*mes, //g;s/\ .*//g")
    planta=$(cat $cache |grep "^\(bajo\|planta\|entreplanta\)" |sed "s/bajo/0/g;s/entreplanta/0.5/g;s/planta //g;s/planta //g;s/[^0-9]*ascensor//g" |grep -v " "|head -n 1)
    aire=$((0$(cat $cache |grep "^aire acondicionado" |sed "s/aire.*/1/g")))
    ascensor=$((0$(cat $cache |grep "con ascensor" |sed "s/.*con ascensor/1/g" |head -n 1)))
    garaje=$(cat $cache |grep "plaza de garaje incluida en el precio$" |sed "s/\ plaza de garaje incluida.*//g")
    if [ "$garaje" == "" ]; then garaje="$(getFrase "araje" "$(cat $cache |grep -i garaje)")"; fi
    if [ "$garaje" == "" ]; then garaje=0; fi
    comision=$(echo $piso |grep "VP" >/dev/null && (cat $cache |grep "sin comisiones" >/dev/null && echo "0" || echo "1") || echo "0")
    amueblado=$(cat $cache |grep amueblado >/dev/null && echo "1" || echo "0")
    comunidad=$(cat $cache |grep "comunidad incluida en el alquiler" >/dev/null && echo "0" || (cat $cache |grep " eur al mes de gastos de comunidad$" | sed "s/\ eur al mes de gastos de comunidad//g"))
    if [ "$comunidad" == "" ]; then comunidad=$(cat $cache |grep -i "comunidad inclu" >/dev/null && echo "0" || getFrase "comunidad" "$(cat $cache |grep -i comunidad)"); fi
    if [ "$comunidad" == "" ]; then comunidad="n/a"; fi
    piscina=$(cat $cache |grep -i "piscina" >/dev/null && echo "1" || echo "0")
    echo "piso=$piso, m2=$metros, eur/mes=$eurmes, comision=$comision, comunidad=$comunidad, planta=$planta, ascensor=$ascensor, dormitorios=$dormitorios, baños=$banos, amueblado=$amueblado, aire=$aire, garaje=$garaje, piscina=$piscina"
    #exit 0
done

