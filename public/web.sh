#!/bin/env bash

# Convert the website html to markdown then output to terminal

# Set website color palette
declare -A pallete=(
	
	[nord0]=$'\e[38;2;59;66;82m'
	[nord1]=$'\e[38;2;191;97;106m'
	[nord2]=$'\e[38;2;163;190;140m'
	[nord3]=$'\e[38;2;235;203;139m'
	[nord4]=$'\e[38;2;129;161;193m'
	[nord5]=$'\e[38;2;180;142;173m'
	[nord6]=$'\e[38;2;136;192;208m'
	[nord7]=$'\e[38;2;143;188;187m'
	[nord8]=$'\e[38;2;76;86;106m'
	[nord9]=$'\e[38;2;216;222;233m'
	[nord1]0=$'\e[38;2;236;239;244m'
	[reset]=$'\e[0m'
	
)

# Define functions
check_deps() {

	code=0

	check() {
		echo -n "$*... "
		if ! "$@"; then
			echo 'error'
			code=1
		fi
	}

	check command -v bash
	check command -v curl
	check command -v jq

	exit "$code"
}

main() {
	check_deps || exit 1
}
