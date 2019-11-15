#!/bin/bash

RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'

function red_echo() {
	echo -e "${RED}$1 ${NC}"
}


function green_echo() {
	echo -e "${GREEN}$1 ${NC}"
}

