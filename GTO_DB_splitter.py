import json
import timeit
import pandas as pd
import os
import shutil
import time
import sys

import time

start_time = time.time()

args = sys.argv

file_in = args[1]
file_path_out = args[2]


"""file_in = '2d,2h,3h.json'
file_path_in = os.path.dirname(os.path.abspath(__file__)) + '/2d,2h,3h.json'
file_path_out = os.path.dirname(os.path.abspath(__file__)) + '/'
file_path_db = os.path.dirname(os.path.abspath(__file__)) + '/'"""

def open_json(table_cards):
    with open(table_cards, 'r') as f:
        try:
            db = json.load(f)
            print('Opened DB')
        except:
            with open('broken_jsons.txt', 'a') as w:
                w.writelines(table_cards + '\n')
                db = None
    return db


def process_layer(db, file_path, layer=''):

    #print(eval(f'db{layer}["node_type"]'))
    # get values for this strat of the json
    if eval(f'db{layer}["node_type"]') == 'chance_node': # check action can be taken
        #print('Chance Node Break')
        return [], []

    try:
        actions = eval(f'db{layer}["strategy"]["actions"]') # check that more than one action is available
        if len(actions) == 0:
            #print('Actions == 0 Break')
            return [], []
    except:
        # There is a bug with some DB's where no strategies are generated for certain cards.
        # In this situation copy the db from a similar card
        #print('No Actions Break', f'db{layer}["strategy"]["actions"]')
        return [], []

    strat = eval(f'db{layer}["strategy"]["strategy"]')
    #print(strat)
    cols = ['actions'] + list(strat.keys())
    try:
        childrens = eval(f'db{layer}["childrens"]')
    except:
        #print('Childrens set to None')
        childrens = []

    # make df
    df = pd.DataFrame(strat, columns=cols, index=range(len(actions)))
    df.actions = actions
    #print(df)
  #  for j in strat.keys():
   #     for i in range(len(actions)):
    #        df.at[i, j] = strat[j][i]

    #code to save df
    moves = layer.split('"]["')
    name = 'df_'
    for move in moves:
        if move [-2:] == '"]':
            move = move[:-2]
        if move == 'CHECK':
            name += 'c'
        if move == 'CALL':
            name += 'd'
        if move[:3] in ['BET', 'RAI']:
            act, amount = move.split(' ')
            if float(amount) < 80:
                name += 'r'
            else:
                name += 'a'
    name = file_path + '/' + name + '.pkl'
    #print(name)
    df.to_pickle(name)

    # get sub_layers
    sub_layers = []
    next_street = []
    for i in childrens:
        if eval(f'db{layer}["childrens"]["{i}"]["node_type"]') == 'action_node':
            sub_layers.append(layer + f'["childrens"]["{i}"]')
        else:
            #print(i, layer + f'["childrens"]["{i}"]', eval(f'db{layer}["childrens"]["{i}"]["deal_number"]'), type(eval(f'db{layer}["childrens"]["{i}"]["deal_number"]')))
            try:
                eval(f'db{layer}["childrens"]["{i}"]["dealcards"]')
                next_street.append(layer + f'["childrens"]["{i}"]')
            except:
                pass

    return sub_layers, next_street

def main(file_in):
    table_cards = file_in[-14:-5]
    db = open_json(file_in)
    #Flop
    try:
        os.mkdir(file_path_out + '/' + table_cards)
    except:
        pass
    flop_folder = (file_path_out + '/' + table_cards)
    next_street_flop = []
    sub_1, next_1 = process_layer(db, flop_folder, layer='')
    next_street_flop += next_1
    for layer_1 in sub_1:
        sub_2, next_2 = process_layer(db, flop_folder, layer=layer_1)
        next_street_flop += next_2
        for layer_2 in sub_2:
            sub_3, next_3 = process_layer(db, flop_folder, layer=layer_2)
            next_street_flop += next_3
            for layer_3 in sub_3:
                sub_4, next_4 = process_layer(db, flop_folder, layer=layer_3)
                next_street_flop += next_4


    # Turn

    for branch in next_street_flop:
        turn_cards = list(eval(f'db{branch}["dealcards"].keys()'))
        for turn_card in turn_cards:
            #print(turn_card)
            try:
                os.mkdir(flop_folder + '/' + turn_card)
            except:
                pass
            turn_folder = flop_folder + '/' + turn_card
            next_street_turn = []
            sub_1, next_1 = process_layer(db, turn_folder, branch + f'["dealcards"]["{turn_card}"]')
            next_street_turn += next_1
            for layer_1 in sub_1:
                sub_2, next_2 = process_layer(db, turn_folder, layer=layer_1)
                next_street_turn += next_2
                for layer_2 in sub_2:
                    sub_3, next_3 = process_layer(db, turn_folder, layer=layer_2)
                    next_street_turn += next_3

            # River
            for river_branch in next_street_turn:
                river_cards = list(eval(f'db{river_branch}["dealcards"].keys()'))
                for river_card in river_cards:
                    try:
                        os.mkdir(turn_folder + '/' + river_card)
                    except:
                        pass
                    #print(river_card)
                    river_folder = turn_folder + '/' + river_card
                    next_street_river = []
                    sub_1, next_1 = process_layer(db, river_folder, river_branch + f'["dealcards"]["{river_card}"]')
                    next_street_river += next_1
                    for layer_1 in sub_1:
                        sub_2, next_2 = process_layer(db, river_folder, layer=layer_1)
                        next_street_river += next_2
                        for layer_2 in sub_2:
                            sub_3, next_3 = process_layer(db, river_folder, layer=layer_2)
                            next_street_river += next_3


def fill_empty_folders(table_cards):
    file = file_path_out + '/' + table_cards[-14:-5] + '/'
    full_turn_folders = []
    for turn_card in os.listdir(file):
        if turn_card[-4:] != '.pkl':
            if os.listdir(file + turn_card + '/', ) != []:
                full_turn_folders.append(turn_card)
            else:
                if full_turn_folders:
                    os.rmdir(file + turn_card)
                    shutil.copytree(file + full_turn_folders[-1] + '/', file + turn_card)

            full_river_folders = []
            for river_card in os.listdir(file + turn_card + '/'):
                if river_card[-4:] != '.pkl':
                    if os.listdir(file + turn_card + '/' + river_card + '/', ) != []:
                        full_river_folders.append(river_card)
                    else:
                        if full_river_folders:
                            os.rmdir(file + turn_card + '/' + river_card)
                            shutil.copytree(file + turn_card + '/' + full_river_folders[-1] + '/', file + turn_card + '/' + river_card)




if __name__ == '__main__':
    main(file_in)
    fill_empty_folders(file_in)
    print(time.time() - start_time)
