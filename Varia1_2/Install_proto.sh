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

echo "Now installing Varia's local mcl instance:"
echo "Now installing Varia's local mcl instance:" >> Varia_install_log.txt
cd $DIR/tools/mcl/mcl-master
sh ./configure --prefix=$DIR/tools/mcl
make
make check
make install
make clean
cd $DIR

echo "Now installing Varia's local circos instance:"
echo "Now installing Varia's local circos instance:" >> Varia_install_log.txt
chmod 755 $DIR/tools/circos/circos-0.69-6/bin/circos

echo "Installation complete: please add $DIR to your PATH before running Varia.sh"
echo "Installation complete: please add $DIR to your PATH before running Varia.sh" >> Varia_install_log.txt