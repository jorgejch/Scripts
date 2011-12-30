#! /bin/bash

###############################################################################
#TODO:                                                                        # 
#-Remover pdbs de trajetórias criados. (feito)                                #
#-Implementar comparação do número de estruturas comuns nas regiões.          #
#-Adequar rotina de alinhamento.                                              #  
###############################################################################

#Argumentos: 1) DCD da trajetória 2) PSF da trajetória

#Caminho para o extract_frame_list.py, ao invés do padrão - procurar no mesmo diretório de execução.
caminho_script_extrai_frames='/home/jorge/documents/mestrado/códigos/obter_estruturas_conformacoes/extract_frame_list.py'

arq_dcd=$1
arq_psf=$2

echo "Rodando sobre trajetória ${arq_dcd} com psf ${arq_psf}."

arquivos_existentes=$(tempfile)
ls > ${arquivos_existentes}

function extrai_indices {
#Argumentos: Não recebe argumentos.

    for file in *
    do
        if [[ -f $file && $file =~ [0-9_]+_regiao_[a-zA-Z]+ ]]
        then
            cat $file | grep '^[ ]\+[0-9]\+' | sed 's/^[ ]\+//' > ${file}_formated
    
            titulo=$(echo $file | sed 's/\([0-9_]\+\)_\(.\+\)/\1_indices_\2/')
            cat ${file}_formated | cut -d ' ' -f 1 > $titulo
        fi
    done
}

function dcd_to_pdb {
#Argumentos. 1) DCD 2) PSF 3) PDB (output) .

    local arq_dcd=$1
    local arq_psf=$2
    local arq_pdb=$3

    local temp=$(tempfile)
    echo "mol new ${arq_dcd} waitfor all" > $temp
    echo "mol addfile ${arq_psf}" >> $temp
    echo "animate write pdb ${arq_pdb}" >> $temp

    vmd -dispdev text -eofexit < $temp > /dev/null 
    rm $temp
}

function pdb_to_dcd {
#Argumtentos: 1) PDB 2) DCD (output)

    local arq_pdb=$1
    local arq_dcd=$2
    local temp=$(tempfile)

    echo "animate read pdb ${arq_pdb} waitfor all" > $temp
    echo "animate write dcd ${arq_dcd} waitfor all" >> $temp
    vmd -dispdev text -eofexit < $temp > /dev/null
    rm $temp
}

function extrai_estruturas_pdb {
#Argumentos: 1)PDB 2)Indices 3)Nome do output. 4)Caminho opicional para o extract_frame_list.py
    if [ -z $4 ]
    then
        local executavel="`pwd`/extract_frame_list.py"
    else
        local executavel=$4
    fi

    local arq_pdb=$1
    local arq_indices=$2
    local output=$3

    $executavel ${arq_pdb} ${arq_indices} > ${output}
}

function calcula_estrutura_media {
#Argumentos: 1) DCD 2) PSF 3) Nome pro output 4) Caminho alternativo pro template.

    if [ -z $4 ]
    then
        local template="`pwd`/avgstruct.inp"
    else
        local template=$4
    fi

    local arq_dcd=$1
    local arq_psf=$2
    local nome_output=$3

    local temp=$(tempfile)

    cat $template | sed  "s/^dcd.*/dcd ${arq_dcd}/" | sed "s/^psf[^_].*/psf ${arq_psf}/" | sed "s/^output.*/output ${nome_output}/" > $temp

    avgstruct $temp &> /dev/null 
    rm $temp
}

function alinhar_estruturas {
#Argumentos: 1) Arquivo com lista dos pdbs. 2) Nome do output
#Precisa ser implementada com outro código, que não o lovoalign.

    local arq_com_pdbs=$1
    local output=$2
    local argumentos="-pdblist ${arq_com_pdbs}"

    lovoalign $argumentos
}

#cria arquivo TCL com estruturas pra abrir no VMD
rm -f estruturas_medias_vmd.tcl
touch estruturas_medias_vmd.tcl

arq_pdb=$( echo $1 | sed 's/dcd$/pdb/' ) 
dcd_to_pdb ${arq_dcd} ${arq_psf} ${arq_pdb}

extrai_indices

vetor_estruturas=( $( ls | grep 'indices_regiao' ) )

for indice in $(seq 0 $((${#vetor_estruturas[@]} - 1)))
do
    pdb_estruturas=$( echo ${vetor_estruturas[${indice}]} | sed "s/\([0-9_]\+\)_indices_\(.\+\)/\1_estruturas_\2\.pdb/" )
    dcd_estruturas=$( echo ${pdb_estruturas} | sed 's/pdb$/dcd/' )
    output=$( echo ${vetor_estruturas[${indice}]} | sed "s/\([0-9_]\+\)_indices_\(.\+\)/\1_avgstruct_\2/" )

    extrai_estruturas_pdb ${arq_pdb} ${vetor_estruturas[${indice}]} ${pdb_estruturas} ${caminho_script_extrai_frames}
    pdb_to_dcd ${pdb_estruturas} ${dcd_estruturas}
    calcula_estrutura_media ${dcd_estruturas} ${arq_psf} $output

    #Incrementa arquivo TCL com estruturas pra abrir no VMD
    echo "mol new ${output}.pdb ">> estruturas_medias_vmd.tcl 
    echo "mol addfile ${output}.psf ">> estruturas_medias_vmd.tcl 
    echo "menu multiseq on" >> estruturas_medias_vmd.tcl
    echo 'for {set mol_index 0} { $mol_index <= [molinfo top] } { incr mol_index } {' >> estruturas_medias_vmd.tcl
    echo 'mol modcolor 1 $mol_index "ColorID $mol_index"' >> estruturas_medias_vmd.tcl
    echo '}' >> estruturas_medias_vmd.tcl

done 

#Rotina de alinhamento precisa usar algum outro código, que não seja o lovoalign. Pra poder alinhar mais de duas proteínas.
#temp=$(tempfile)
#ls | grep '.\+avgstruct_regiao.\+pdb' > $temp
#output_alinhamento="estruturas_medias_alinhadas.pdb"
#alinhar_estruturas $temp ${output_alinhamento}
#rm $temp

rm -f *estruturas*pdb pca*traj*pdb

rm -f arquivos_gerados_por_estruturas_rep
arquivos_apos_exec=$(tempfile)
ls > ${arquivos_apos_exec}
diff --suppress-common-lines ${arquivos_apos_exec} ${arquivos_existentes} | grep '< ' | sed 's/^< //' > arquivos_gerados_por_estruturas_rep
rm ${arquivos_apos_exec} ${arquivos_existentes} 

exit 0
