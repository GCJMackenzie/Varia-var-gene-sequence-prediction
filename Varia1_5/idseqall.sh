#!/bin/bash
NAME=$1
HERE=$(pwd)

mkdir ${NAME}_identity_seqall
grep -n '>' ${NAME}seqs.fasta >> $NAME.list.txt
while read p; do
	echo $p | cut -d ':' -f 2
	ID=$(echo $p | cut -d ':' -f 2 | cut -d '>' -f 2)
	echo $p | cut -d ':' -f 2 > tempseq.fasta
	LINE=$(echo $p | cut -d ':' -f 1)
	LINE=$(($LINE + 1 ))
	sed -n ${LINE}p ${NAME}seqs.fasta >> tempseq.fasta
	LENGTH=$(sed -n ${LINE}p ${NAME}seqs.fasta | wc -c)
	echo $LENGTH
	LENGTH=$(($LENGTH - 1))
	echo $LENGTH
	RANGE=$( bc <<<"scale=0; $LENGTH * 0.8")
	RANGE=$(printf %.0f $RANGE)
	echo $RANGE
	cd ./${NAME}tags-99-Varia_Out/summaries
	HERECHECK=$(ls -F | grep $ID.final_summary.txt)
	cd $HERE
	if [ "$HERECHECK" != "" ]
		then
		
		tail -n +2 ./${NAME}tags-99-Varia_Out/summaries/$ID.cluster_summary.txt | cut -f 2 > tempnames.txt
		while read q; do
			echo ">"$q >> tempdb.fasta
			SEQLINE=$(grep -n -w ">$q" /home/manager/databases/varDB.version4.fasta | cut -d ':' -f 1)
			SEQLINE=$(($SEQLINE + 1))
			sed -n ${SEQLINE}p /home/manager/databases/varDB.version4.fasta >> tempdb.fasta
			done < tempnames.txt
		rm tempnames.txt
		formatdb -i tempdb.fasta -p F -o T -t tempdb.fasta
		megablast  -b 2000 -v 2000 -e 1e-10 -m 8 -F F -d tempdb.fasta -i tempseq.fasta -o $ID.ident.blast
		awk '$3 > 99' $ID.ident.blast >> $ID.identity_filt.txt
		awk -v range="$RANGE" '$4 > range' $ID.identity_filt.txt >> $ID.identlength.txt
		echo "" >> $ID.identlength.txt
		rm tempdb*
		rm formatdb.log
		mv $ID.ident.blast ./${NAME}_identity_seqall/$ID.ident.blast
		mv $ID.identity_filt.txt ./${NAME}_identity_seqall/$ID.identity_filt.txt
		else
		echo "" > $ID.identlength.txt
		fi
	rm tempseq.fasta
	mv $ID.identlength.txt ./${NAME}_identity_seqall/$ID.identlength.txt
	done < $NAME.list.txt
rm $NAME.list.txt
