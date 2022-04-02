#!/bin/bash

dor () {
set -e -o pipefail
if [ $? -ne 0 ]; then trap 'luz' EXIT; fi
}
dor

luz() {
echo "Uso: $0 [-opção] [-opção argumento] [diretoria(s)]"
echo "Este script apresenta informações sobre os ficheiros, pastas, e devidos tamanhos contidos na(s) pasta(s) dada(s) como argumento(s)."
echo "Cada diretoria/subdiretoria gera uma linha no output, ou, caso a opção -L seja ativada, é gerada uma linha por ficheiro, até se atingir o limite dado pelo argumento de -L."
echo "	Opções:"
echo "	-n <EXPRESSÃO>	seleção dos ficheiros de interesse"
echo "	-d <DATA>	considerar apenas ficheiros cuja data de acesso seja inferior à dada pelo argumento"
echo "	-a		mostrar resultados por ordem alfabética"
echo "	-r		mostrar resultados por ordem inversa"
echo "	-l <NÚMERO>	nº (máximo) de ficheiros, de entre os maiores em cada diretoria, devem ser considerados. Não pode ser usado com a opção -L"
echo "	-L <NÚMERO>	nº (máximo) de ficheiros, de entre os maiores em todas as diretorias, devem ser considerados. Não pode ser usado com a opção -l. Altera o output de modo a gerar uma linha por cada ficheiro, e não uma linha por cada (sub)diretoria"

}




array_Ficheiros_Tamanhos=()
declare -A array_Dir_Tamanhos
array_Dir_Nomes=()

function listDir {
dir="$1"
flag_d="$2"
flag_f="$3"
flag_e="$4"
flag_e_arg="$5"
flag_n_arg="$6"


array_Dir_Nomes+=( "$1" )

for dent in "$dir"/* 
do

	if [[ -d "$dent" ]] && [[ -x "$dent" ]]; then
		listDir "$dent" "$flag_d" "$flag_f" "$flag_e" "$flag_e_arg" "$flag_n_arg" 
	elif [ -f "$dent" ] && [[ -r "$dent" ]]; then
			if [[ $flag_n -eq 0 ]] || [[ "$dent" == *$flag_n_arg* ]]; then
				if [[ $flag_d -eq 0 ]]; then
					if [[ $flag_L -eq 1 ]]; then
						tamanho=$(stat "$dent" | awk '{print $2}' | tail -n +2 | head -n 1)
						array_Ficheiros_Tamanhos+=("$dent	$tamanho")
					else
						tamanho=$(stat "$dent" | awk '{print $2}' | tail -n +2 | head -n 1)
						array_Dir_Tamanhos["$1"]="${array_Dir_Tamanhos[$1]} $tamanho" 
					fi
				else
					data=$(stat "$dent" | awk '{print $2, $3}' | tail -n +5 | head -n 1)
					data=$(date +%s -d "$data")
					#echo "$data"
					if  [[ "$data" < "$flag_d_arg" ]]; then
						if [[ $flag_L -eq 1 ]]; then
							tamanho=$(stat "$dent" | awk '{print $2}' | tail -n +2 | head -n 1)
							array_Ficheiros_Tamanhos+=("$dent	$tamanho")
						else
							tamanho=$(stat "$dent" | awk '{print $2}' | tail -n +2 | head -n 1)
							array_Dir_Tamanhos["$1"]="${array_Dir_Tamanhos[$1]} $tamanho"
						fi
					fi
				fi
			fi
	else
		continue
	fi
done
}



function bash_sort_head { 
if [[ $flag_l -eq 0 ]] && [[ $flag_L -eq 0 ]]; then
	for ((l=0; l<${#array_Dir_Nomes[@]}; l++)); do
		array_Dir_Tamanhos["${array_Dir_Nomes[l]}"]=$(printf '%s\n' "${array_Dir_Tamanhos[${array_Dir_Nomes[l]}]}" | awk '{for(i=t=0;i<NF;) t+=$++i; $0=t}1')
	done
elif [[ $flag_l -eq 1 ]] && [[ $flag_L -eq 0 ]]; then
	for ((l=0; l<${#array_Dir_Nomes[@]}; l++)); do
		array_Dir_Tamanhos["${array_Dir_Nomes[l]}"]=$(echo "${array_Dir_Tamanhos[${array_Dir_Nomes[l]}]}" | tr " " "\n" | sort -rn | head -n $flag_l_arg | awk '{s+=$1}END{print s}' )
	done
else
	IFS=$'\n' array_Ficheiros_Tamanhos2=($(printf '%s\n' "${array_Ficheiros_Tamanhos[@]}" | awk '{print $NF,$0}' | LC_ALL=C sort -nr | cut -d" " -f2-))
	unset array_Ficheiros_Tamanhos 
	array_Ficheiros_Tamanhos=("${array_Ficheiros_Tamanhos2[@]}") 
fi

}




function relampago {
	if [ $flag_L -eq 0 ]; then
		if [[ $flag_a -eq 1 ]] && [[ $flag_r -eq 1 ]]; then
			for ((i=0; i<${#array_Dir_Nomes[@]}; i++)); do	
				echo "${array_Dir_Nomes[i]}	${array_Dir_Tamanhos[${array_Dir_Nomes[i]}]}"
			done | LC_ALL=C sort $flag_a_arg $flag_r_arg 
			
		elif [[ $flag_a -eq 1 ]] && [[ $flag_r -eq 0 ]]; then
			for ((i=0; i<${#array_Dir_Nomes[@]}; i++)); do	
				echo "${array_Dir_Nomes[i]}	${array_Dir_Tamanhos[${array_Dir_Nomes[i]}]}"
			done | LC_ALL=C sort $flag_a_arg 
			
		elif [[ $flag_a -eq 0 ]] && [[ $flag_r -eq 1 ]]; then
			for ((i=0; i<${#array_Dir_Nomes[@]}; i++)); do	
				echo "${array_Dir_Nomes[i]}	${array_Dir_Tamanhos[${array_Dir_Nomes[i]}]}"
			done | awk '{print $NF,$0}' | LC_ALL=C sort -n | cut -d" " -f2-
			
		else
			for ((i=0; i<${#array_Dir_Nomes[@]}; i++)); do	
				echo "${array_Dir_Nomes[i]}	${array_Dir_Tamanhos[${array_Dir_Nomes[i]}]}"
			#done
			done | awk '{print $NF,$0}' | LC_ALL=C sort -nr | cut -d" " -f2- 
		fi
	else
		
		if [[ $flag_a -eq 1 ]] && [[ $flag_r -eq 1 ]]; then
			#for ((i=0; i<${#array_Ficheiros_Tamanhos[@]}; i++)); do
			for ((i=0; i<$flag_L_arg; i++)); do
				echo "${array_Ficheiros_Tamanhos[i]}"
			done | LC_ALL=C sort $flag_a_arg $flag_r_arg
			
		elif [[ $flag_a -eq 1 ]] && [[ $flag_r -eq 0 ]]; then
			for ((i=0; i<$flag_L_arg; i++)); do
				echo "${array_Ficheiros_Tamanhos[i]}"
			done | LC_ALL=C sort $flag_a_arg $flag_r_arg
		elif [[ $flag_a -eq 0 ]] && [[ $flag_r -eq 1 ]]; then
			for ((i=0; i<$flag_L_arg; i++)); do
				echo "${array_Ficheiros_Tamanhos[i]}"
			done | tac
			
		else
			for ((i=0; i<$flag_L_arg; i++)); do
				echo "${array_Ficheiros_Tamanhos[i]}"
			done
		fi
	fi
}



flag_n=0
flag_n_arg=" "
flag_d=0
flag_d_arg=" "
flag_l=0
flag_l_arg=" "
flag_L=0
flag_L_arg=" "
flag_a=0
flag_a_arg=" "
flag_r=0
flag_r_arg=" "

while getopts "d:al:L:n:r" option; do
	case $option in
		a) #ordenar output por nome
		if [ $flag_a -eq 1 ]; then
			luz
			exit 1
		fi
		flag_a=1
		flag_a_arg="-n"
		;;
		
		d) #filtrar ficheiros por data
		if [ $flag_d -eq 1 ]; then
			luz
			exit 1
		fi
		flag_d=1
		if [[ -z "${OPTARG// }" ]]; then 
			echo "Providencie uma data válida"
			exit 1
		fi
		flag_d_arg=$(date +%s -d "$OPTARG")
		if [[ $? -ne 0 ]]; then 
			echo "Data inválida"
			exit 1
		fi
		;;
		
		n) #filtro de ficheiros
		if [ $flag_n -eq 0 ]; then
			flag_n=1
			if [[ -z "${OPTARG// }" ]]; then 
				echo "Providencie um parâmetro à opção -n"
				exit 1
			fi
			flag_n_arg="$OPTARG"
		else
			echo "Insira apenas 1 filtro de redes"
			exit 1
		fi
		;;
		
		r)
		if [ $flag_r -eq 1 ]; then
			luz
			exit 1
		fi
		flag_r=1
		flag_r_arg=" -r"
		;;
		
		l)
		if [ $flag_l -eq 1 ] || [$flag_L -eq 1]; then
			luz
			exit 1
		fi
		flag_l=1
		if [[ ! $OPTARG =~ ^[0-9]+$ ]]; then
			echo "Indique um número inteiro positivo à opção -l"
			exit 1
		fi
		flag_l_arg=$OPTARG
		;;
		
		L)
		if [ $flag_L -eq 1 ] || [ $flag_l -eq 1 ]; then
			luz
			exit 1
		fi
		flag_L=1
		if [[ ! $OPTARG =~ ^[0-9]+$ ]]; then
			echo "Indique um número inteiro positivo à opção -L"
			exit 1
		fi
		flag_L_arg=$OPTARG
		;;
		
		
		*)
		echo "Usage: $0 [-e ext] [-d] [-f] name"
		exit 1
		;;
	esac
done

shift $((OPTIND-1))



if [ $# -eq 0 ]; then
	dir="."
	echo "Listagem de ""$(pwd)"
	listDir "$dir" "$flag_d" "$flag_f" "$flag_e" "$flag_e_arg" "$flag_n_arg"
else
	for dir in "$@"
	do
		echo "Listagem de ""$dir"
		listDir "$dir" "$flag_d" "$flag_f" "$flag_e" "$flag_e_arg" "$flag_n_arg"
		bash_sort_head
		relampago
	done
fi

