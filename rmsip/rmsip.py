#! /usr/bin/env python3
from math import sqrt, pow
import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description="Calculates the RMSIP of a ran\
ge of vectors.")
    parser.add_argument('file',nargs=2, help="File containing vectors as column\
s.")
    parser.add_argument('range', type=int, help="Range of vectors (columns) to \
be selected from both files.")
    parser.add_argument('-o',nargs=1, metavar=("gen-dot-file"), help="Generate \
a file with 3 columns (vectorF1 X vectorF1, vectorF2 X vectorF2, vectorF1 X vectorF2.")
    parser.add_argument('-d','--disconsider', type=int, nargs='+', metavar="N",\
help="Disconsider column(s) N from both vector files.")
    args = parser.parse_args()

    print_out_rmsip(rmsip(load_eigenvector_array(args.file[0], args.range, args\
.disconsider),load_eigenvector_array(args.file[1], args.range, args.disconsider\
), args.o))
    
    return 0

def load_eigenvector_array(vector_file, length, to_exclude):
    file = open(vector_file,'r')

    if to_exclude is not None:
        items = [i for i in range(length ) if i not in to_exclude]
    else:
        items = range(length)

    vector_array= [list() for count in items]

    for line in file:
        elements = line.split()
        for x, item in enumerate(items):
            vector_array[x].append(float(elements[item]))
        
    file.close()
    return vector_array

def inner_product(vector1,vector2):
    return  sum([value1*value2 for value1, value2 in zip(vector1,vector2)])

def check_for_equal_vector_legths(vector1, vector2):
    if (len(vector1) != len(vector2)):
        print("Eigenvectors of different sizes.")
        sys.exit()
    else:
        return

def generate_dot_prod_file(dot_prod):
    new_file = open('dot_prod.dat', 'w')

    for i in range(len(dot_prod[0])):
        str_line = " ".join([dot_prod[0][i], dot_prod[1][i], dot_prod[2][i]])
        new_file.write(str_line + '\n')
    
    new_file.close()

def rmsip(vector_array_1, vector_array_2, optionals):
    rmsip = 0.0
    prod_list = [list(), list(), list()]

    for i, vector1 in enumerate(vector_array_1):

        for j, vector2 in enumerate(vector_array_2):
            prod_list[0].append(str(i+1));
            prod_list[1].append(str(j+1));

            check_for_equal_vector_legths(vector1, vector2)
            i_product = inner_product(vector1, vector2)
            prod_list[2].append("%1.5f" %abs(i_product))
            rmsip = rmsip + pow(i_product,2)

    length = len(vector_array_1)
    rmsip = sqrt(rmsip/float(length))

    if optionals is not None:
        if "gen-dot-file" in optionals:
            generate_dot_prod_file(prod_list)

    return rmsip

def print_out_rmsip(value):
    print("rmsip = " + str(value))

main()
