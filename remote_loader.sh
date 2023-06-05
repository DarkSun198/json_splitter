#!/system/bin/sh

sudo apt install python3.10-venv
sudo apt install unzip

echo Creating virtual environment
python3 -m venv json_splitter
source json_splitter/bin/activate

echo Installing prerequisites
pip install pandas


echo Installing Texas Solver
wget -q https://github.com/bupticybee/TexasSolver/releases/download/v0.1.0/TexasSolver-v0.1-Linux.zip
unzip TexasSolver-v0.1-Linux.zip

mv input.txt /TexasSolver-Linux

cd TexasSolver-Linux
#curl -o GTO_DB_splitter.py https://raw.githubusercontent.com/DarkSun198/json_splitter/main/GTO_DB_splitter.py

mkdir input
mkdir output 

#!/bin/bash

# Read in the list of possible values for X from input.txt
IFS=$'\n' read -d '' -r -a x_values < input.txt

#x_values=("Th,3s,Td" "2c,8d,Jh" "5d,6d,7d")

# Loop through each value of X and create a separate file for each one
for x in "${x_values[@]}"; do

    # Remove any leading or trailing whitespace from the value of X
    x=$(echo "$x" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # If no folder in output
    if  [ ! -d "output/$x" ]
    then
    	echo "No folder for output/$x"

    	# If no json in output
    	if [ ! -f "output/$x.json" ]
    	then
    	    echo "No JSON for $x"

	    # Create the file with the desired contents
	    echo "set_pot 25
set_effective_stack 100
set_board $x
set_range_ip AA
set_range_oop AA
set_bet_sizes oop,flop,bet,100
set_bet_sizes oop,flop,raise,100
set_bet_sizes ip,flop,bet,100
set_bet_sizes ip,flop,raise,100
set_bet_sizes oop,turn,bet,100
set_bet_sizes oop,turn,raise,100
set_bet_sizes ip,turn,bet,100
set_bet_sizes ip,turn,raise,100
set_bet_sizes oop,river,bet,100
set_bet_sizes oop,river,donk,100
set_bet_sizes oop,river,raise,100
set_bet_sizes ip,river,bet,100
set_bet_sizes ip,river,raise,100
set_allin_threshold 0.8
build_tree
set_thread_num 2
set_accuracy 5.0
set_max_iteration 101
set_print_interval 10
set_use_isomorphism 1
start_solve
set_dump_rounds 3
dump_result output/$x.json" > "input/${x}.txt"

	    # Make JSON and store in DB folder
    	    ./console_solver -i "input/$x.txt"

    	    echo "JSON made for $x"

    	fi

    	# Run DB Splitter on JSON
        python3 GTO_DB_splitter.py "output/$x.json" output

        echo "$x has been split"


    fi

    # Remove JSON


done

