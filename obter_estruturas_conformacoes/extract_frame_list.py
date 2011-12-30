#! /usr/bin/python3

import sys

cam_arq_pdb = sys.argv[1]
cam_arq_indices = sys.argv[2]

def ler_indices(caminho):
    arq_indices = open(caminho, 'r')

    indices = set()
    
    for line in arq_indices:
        indices.add(int(line))

    arq_indices.close()

    return indices

def parse_pdb(caminho, indices_set):

    arq_pdb = open(caminho, 'r')
    contador_indices = 1

    for line in arq_pdb:
        if contador_indices in indices_set:
            while "END" not in line:
                print(line[:-1])
                line = arq_pdb.readline()
            else:
                contador_indices = contador_indices + 1
                print(line[:-1])
                continue

        if "END" in line:
            contador_indices = contador_indices + 1

    arq_pdb.close()

parse_pdb(cam_arq_pdb, ler_indices(cam_arq_indices))
