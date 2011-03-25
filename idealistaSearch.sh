#!/bin/bash

#### MANUAL ####################################################################
# NAME
#   idealistaSearch.sh - parses idealista.com search URLs and returns flat IDs
#
# SYNOPSIS
#   idealistaSearch.sh url
#
# EXAMPLE
#   idealistaSearch.sh "http://www.idealista.com/..."
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
sitioGeneral=""  #used to narrow down google maps search
direccionCurro="" #used to lookup public transport travel times in google maps

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
function checkParams
{
    if [ -z $1 ]
    then
        logerror "Pon la URL de búsqueda"
        exit 1
    fi
}
function search
{
    url="$1"
    page=1
    curl --silent "$url&chpa=$page" |grep "codigoinmueble" |grep "ver" |sed "s/.*inmueble\=//g" |cut -c -15
    page=$(( $page + 1))
    curl --silent "$url&chpa=$page" |grep "codigoinmueble" |grep "ver" |sed "s/.*inmueble\=//g" |cut -c -15
    page=$(( $page + 1))
    curl --silent "$url&chpa=$page" |grep "codigoinmueble" |grep "ver" |sed "s/.*inmueble\=//g" |cut -c -15
    page=$(( $page + 1))
    curl --silent "$url&chpa=$page" |grep "codigoinmueble" |grep "ver" |sed "s/.*inmueble\=//g" |cut -c -15
    page=$(( $page + 1))
    curl --silent "$url&chpa=$page" |grep "codigoinmueble" |grep "ver" |sed "s/.*inmueble\=//g" |cut -c -15
    # yes i know, only 5 pages of search results? meh, i'm lazy. copy-paste at will...
}

checkDeps curl sed grep cut
checkErr $? "Missing dependencies. Stopping..."
checkParams $*
for i in $*
do
    url="$i"
    search "$url" &
done
wait
