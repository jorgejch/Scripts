#!/bin/bash

if [ ${#@} == 0 ]; then
    source caed.source
else
    source $1
fi

num_eigenvectors=${#EIGENVECTORS[@]}
current_path=`pwd`

PSF=$(echo $PSF | sed 's/\//\\\//g')


for (( i=0 ; i<num_eigenvectors ; i++ ))
do
    eigenvector_range=${EIGENVECTORS[$i]}

    index=`expr index $eigenvector_range '-'`

    if [ ! $index -eq 0 ]; then
        eigenvector_first=${eigenvector_range:0:(( $index - 1))}
        eigenvector_last=${eigenvector_range:${index}}
    else
        eigenvector_first=${eigenvector_range}
        eigenvector_last=${eigenvector_first}
    fi  
    
    caminho=${DESTINO}/${NAME}_${eigenvector_first}-${eigenvector_last}
    if [ ! -a  ${caminho} ]; then
    mkdir -p $caminho
    fi

    tail -n 29 caed.sh > ${caminho}/temp
   
    unset dcds
    while read -r line
    do
        dcds="${dcds}dcd_$(echo ${line} | sed 's/\//\\\//g')\n"
    done < $DCDS_FILE

    sed -i "s/#DCDS#/$dcds/" ${caminho}/temp 
    sed -i 's/dcd_/dcd /' ${caminho}/temp

    sed -i "s/#FIRST_EIGENVECTOR#/${eigenvector_first}/" ${caminho}/temp
    sed -i "s/#LAST_EIGENVECTOR#/${eigenvector_last}/" ${caminho}/temp
    
    sed -i "s/#PSF#/${PSF}/" ${caminho}/temp
    sed -i "s/#REFERENCE_SELECTION#/${REFERENCE_SELECTION}/" ${caminho}/temp
    sed -i "s/#MOBILITY_SELECTION#/${MOBILITY_SELECTION}/" ${caminho}/temp
    sed -i "s/#QUASI#/${QUASI}/" ${caminho}/temp
    sed -i "s/#OUT_NAME#/${NAME}/" ${caminho}/temp
    sed -i "s/#OUT_EIGENVALUE#/${OUT_EIGENVALUE}/" ${caminho}/temp
    sed -i "s/#OUT_EIGENVECTOR#/${OUT_EIGENVECTOR}/" ${caminho}/temp
    sed -i "s/#OUT_PROJECTION#/${OUT_PROJECTION}/" ${caminho}/temp
    sed -i "s/#OUT_COVARIANCE#/${OUT_COVARIANCE}/" ${caminho}/temp
    sed -i "s/#OUT_RMSFCA#/${OUT_RMSFCA}/" ${caminho}/temp
    sed -i "s/#OUT_TRAJECTORY#/${OUT_TRAJECTORY}/" ${caminho}/temp
    sed -i "s/#OUT_BINARY#/${OUT_BINARY}/" ${caminho}/temp
    sed -i "s/#OUT_PSF#/${OUT_PSF}/" ${caminho}/temp
    
    cd $caminho
    mv $caminho/temp $caminho/${NAME}.input
    comando="$EDYNAMICS $caminho/${NAME}.input &> $caminho/${NAME}.out"

#   echo "$comando"

    echo "Rodando analise ${NAME}_${eigenvector_first}-${eigenvector_last}."
    eval $comando
#    tail -f $caminho/${NAME}.out
    rm -f *.tcl
    cd ${current_path}

done
exit
#29_LINES####################EDYNAMICS_INPUT###################################
# DCD files
#DCDS#

# PSF file
psf #PSF#

# Group to perform the alignment (like VMD).
reference_selection #REFERENCE_SELECTION#

# Group to perform essential dynamics (like VMD).
mobility_selection  #MOBILITY_SELECTION# 

# First and last eigenvectors which will generate the essential subspace.
first_eigenvector   #FIRST_EIGENVECTOR# 
last_eigenvector    #LAST_EIGENVECTOR#

# Use mass-weighted covariance matrix to perform quasi-harmonic analysis?
quasi_harmonic       #QUASI#

# Output files
outputname           #OUT_NAME#
eigenvalue_file      #OUT_EIGENVALUE#
eigenvector_file     #OUT_EIGENVECTOR#
covariance_file      #OUT_COVARIANCE#
projection_file      #OUT_PROJECTION#
rmsfCA_file          #OUT_RMSFCA#
trajectory_file      #OUT_TRAJECTORY#
binary_trajectory    #OUT_BINARY#
psf_file             #OUT_PSF#
