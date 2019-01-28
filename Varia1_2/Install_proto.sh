#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR

chmod 755 $DIR/Varia.sh
echo "Now Checking PATH for blastn:"
echo "Now Checking PATH for blastn:" > Varia_install_log.txt

BLSTN=$(which blastn)

if [ "$BLSTN" = "" ]
then
	echo "blastn is required by Varia to run. But no instance of blastn can be found on your PATH, please install and add blastn to your PATH."
	echo "blastn is required by Varia to run. But no instance of blastn can be found on your PATH, please install and add blastn to your PATH." >> Varia_install_log.txt
else
	BLSTN="blastn is required by Varia to run. Varia will use the blastn instance found in $BLSTN"
	echo $BLSTN
	echo $BLSTN >> Varia_install_log.txt
fi

echo "Now Checking PATH for samtools faidx:"
echo "Now Checking PATH for samtools faidx:" >> Varia_install_log.txt

SMTLS=$(which samtools)

if [ "$SMTLS" = "" ]
then
	echo "samtools faidx is required by Varia to run. But no instance of samtools faidx can be found on your PATH, please install and add samtools to your PATH."
	echo "samtools faidx is required by Varia to run. But no instance of samtools faidx can be found on your PATH, please install and add samtools to your PATH." >> Varia_install_log.txt
else
	SMTLS="samtools faidx is required by Varia to run. Varia will use the samtools instance found in $SMTLS"
	echo $SMTLS
	echo $SMTLS >> Varia_install_log.txt
fi

echo "Now Checking PATH for mcl:"
echo "Now Checking PATH for mcl:" >> Varia_install_log.txt

MCL=$(which mcl)
if [ "$MCL" = "" ]
then
	echo "mcl is required by Varia to run. But no instance of mcl can be found on your PATH, please install and add mcl to your PATH."
	echo "mcl is required by Varia to run. But no instance of mcl can be found on your PATH, please install and add mcl to your PATH." >> Varia_install_log.txt
	read -n1 -p "Do you wish for Varia to try install mcl using CONDA? [y,n]" doit
	case $doit in
		y|Y) 
		echo " Attempting to install mcl:"
		conda install mcl
		MCL=$(which mcl)
		echo "new mcl installation is in: $MCL"
		echo "new mcl installation is in: $MCL" >> Varia_install_log.txt ;;

		n|N) 
		echo " Varia will not run without mcl, please consider installing manually if you do not wish to use conda."
		echo " Varia will not run without mcl, please consider installing manually if you do not wish to use conda." >> Varia_install_log.txt ;;
	esac	
else
	MCL="mcl is required by Varia to run. Varia will use the mcl instance found in $MCL"
	echo $MCL
	echo $MCL >> Varia_install_log.txt
fi

echo "Now Checking PATH for circos:"
echo "Now Checking PATH for circos:" >> Varia_install_log.txt

CIRC=$(which circos)
if [ "$CIRC" = "" ]
then
	echo "circos is required by Varia to produce output plots. But no instance of circos can be found on your PATH, please install and add circos to your PATH."
	echo "circos is required by Varia to produce output plots. But no instance of circos can be found on your PATH, please install and add circos to your PATH." >> Varia_install_log.txt
	read -n1 -p "Do you wish for Varia to try install circos using CONDA? [y,n]" doit
	case $doit in
		y|Y) 
		echo " Attempting to install circos:"
		conda install circos
		CIRC=$(which circos)
		echo "The new installation is in: $CIRC"
		echo "The new installation is in: $CIRC" >> Varia_install_log.txt ;;

		n|N) 
		echo " While Varia will run without circos it will not be able to produce plots, please consider installing manually if you do not wish to use conda."
		echo " While Varia will run without circos it will not be able to produce plots, please consider installing manually if you do not wish to use conda." >> Varia_install_log.txt ;;
	esac
else
	CIRC="circos is required by Varia to run. Varia will use the circos instance found in $CIRC"
	echo $CIRC
	echo $CIRC >> Varia_install_log.txt
fi

echo "Installation complete: please add $DIR to your PATH before running Varia.sh"
echo "Installation complete: please add $DIR to your PATH before running Varia.sh" >> Varia_install_log.txt
