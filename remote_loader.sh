#!/system/bin/sh

sudo apt-get update
sudo apt-get upgrade
sudo apt install python3.10-venv
sudo apt install unzip
sudo apt-get install libgomp1

echo Creating virtual environment
python3 -m venv json_splitter
source json_splitter/bin/activate

echo Installing prerequisites
pip install pandas


echo Installing Texas Solver
wget -q https://github.com/bupticybee/TexasSolver/releases/download/v0.1.0/TexasSolver-v0.1-Linux.zip
unzip TexasSolver-v0.1-Linux.zip

sudo mv input.txt TexasSolver-Linux
sudo mv GTO_DB_splitter.py TexasSolver-Linux

cd TexasSolver-Linux
#curl -o GTO_DB_splitter.py https://raw.githubusercontent.com/DarkSun198/json_splitter/main/GTO_DB_splitter.py

mkdir input
mkdir output 

#!/bin/bash

# Read in the list of possible values for X from input.txt
#IFS=$'\n' read -d '' -r -a x_values < input.txt

x_values=("Th,3s,Td") # "2c,8d,Jh" "5d,6d,7d")

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
	    echo "set_pot 6
set_effective_stack 100
set_board $x
set_range_ip AA,AKs,AQs,AJs,ATs,A9s,A8s,A7s,A6s,A5s,A4s,A3s,A2s,AKo,KK,KQs,KJs,KTs,K9s,K8s,K7s,K6s,K5s,K4s,K3s,K2s,AQo,KQo,QQ,QJs,QTs,Q9s,Q8s,Q7s,Q6s,Q5s,Q4s,Q3s,Q2s,AJo,KJo,QJo,JJ,JTs,J9s,J8s,J7s,J6s,J5s,J4s,ATo,KTo,QTo,JTo,TT,T9s,T8s,T7s,T6s,T5s,A9o,K9o,Q9o,J9o,T9o,99,98s,97s,96s,95s,A8o,K8o,Q8o,J8o,T8o,98o,88,87s,86s,85s,A7o,K7o,Q7o,77,76s,75s,A6o,K6o,66,65s,A5o,K5o,55,54s,A4o,K4o,44,A3o,33,A2o,22
set_range_oop AA,AKs,AQs,AJs,ATs,A9s,A8s,A7s,A6s,A5s,A4s,A3s,A2s,AKo,KK,KQs,KJs,KTs,K9s,K8s,K7s,K6s,K5s,K4s,K3s,K2s,AQo,KQo,QQ,QJs,QTs,Q9s,Q8s,Q7s,Q6s,Q5s,Q4s,Q3s,Q2s,AJo,KJo,QJo,JJ,JTs,J9s,J8s,J7s,J6s,J5s,J4s,ATo,KTo,QTo,JTo,TT,T9s,T8s,T7s,T6s,T5s,A9o,K9o,Q9o,J9o,T9o,99,98s,97s,96s,95s,A8o,K8o,Q8o,J8o,T8o,98o,88,87s,86s,85s,A7o,K7o,Q7o,77,76s,75s,A6o,K6o,66,65s,A5o,K5o,55,54s,A4o,K4o,44,A3o,33,A2o,22
set_bet_sizes oop,flop,bet,50,100
set_bet_sizes oop,flop,raise,50,100
set_bet_sizes ip,flop,bet,50,100
set_bet_sizes ip,flop,raise,50,100
set_bet_sizes oop,turn,bet,100
set_bet_sizes oop,turn,raise,100
set_bet_sizes ip,turn,bet,100
set_bet_sizes ip,turn,raise,100
set_allin_threshold 0.8
build_tree
set_thread_num 32
set_accuracy 0.5
set_max_iteration 201
set_print_interval 10
set_use_isomorphism 1
start_solve
set_dump_rounds 2
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

