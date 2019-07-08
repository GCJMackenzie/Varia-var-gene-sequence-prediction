#!/bin/bash

## 1. Add the path to Varia1_4 directory to your pathway
## 2. Run Install_proto.sh from the Varia1_4 directory to setup databases and check necessary tools are installed.
## 3. Run this script with command line: Varia.sh <name of fasta file> <identity value for initial blast>

##obtains current path to Varia1_4 directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##checks that the name of fasta file is both present and valid.
if [ "$1" = "" ]
then
	echo "No filename specified, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi
CHECK=$(echo $1 | cut -d '.' -f2)
if [ "$CHECK" != "fasta" ]
then
	echo "filename is not in a fasta format, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi

CHECK=$(head $1)
if [ "$CHECK" = '' ]
then
	echo "No file called $1 was found in this directory"
	exit
fi


FILE=$(basename $1 .fasta)

HERECHECK=$(ls -F | grep $FILE.fasta)
if [ "$HERECHECK" = "" ]
then
	cp $1 ./$FILE.fasta
fi

##checks an identity score is present and valid
IDENT=$2
if [ "$IDENT" = "" ]
then
	echo "No Identity score detected, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi


if ! echo $IDENT | egrep -q '^[0-9]+$';
then
	echo "Identity score must be an integer between 1 and 100, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi

if [ $IDENT -gt 100 ] || [ $IDENT -lt 1 ]
then
	echo "Identity score out of range, keep identity score between 1 and 100"
	exit
fi

echo "Setting up environment."
##makes directories to sort output files
##will notify user if a set already exist and ask if they wish to replace them.
DIRCHECK=$(ls -F | grep $FILE-$IDENT-Varia_Out)
if [ "$DIRCHECK" = "" ]
then
	mkdir ./$FILE-$IDENT-Varia_Out
	mkdir ./$FILE-$IDENT-Varia_Out/cluster_files
	mkdir ./$FILE-$IDENT-Varia_Out/length
	mkdir ./$FILE-$IDENT-Varia_Out/chromosomes
	mkdir ./$FILE-$IDENT-Varia_Out/links
	mkdir ./$FILE-$IDENT-Varia_Out/labels
	mkdir ./$FILE-$IDENT-Varia_Out/domains
	mkdir ./$FILE-$IDENT-Varia_Out/coverage
	mkdir ./$FILE-$IDENT-Varia_Out/filedump
	mkdir ./$FILE-$IDENT-Varia_Out/plots
	mkdir ./$FILE-$IDENT-Varia_Out/axis
	mkdir ./$FILE-$IDENT-Varia_Out/axis_label
	mkdir ./$FILE-$IDENT-Varia_Out/summaries
else
	echo "An oputput directory named $FILE-$IDENT-Varia_Out is already present"
	read -n1 -p "Do you wish for Varia to overwrite the contents of $FILE-$IDENT-Varia_Out? [y,n]" doit
		case $doit in
			y|Y) 
			echo ""
			echo "Varia will now overwrite $FILE-$IDENT-Varia_Out"
			cd ./$FILE-$IDENT-Varia_Out
			DIRCHECK=$(ls -F | grep cluster_files)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir cluster_files
			fi
			DIRCHECK=$(ls -F | grep length)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir length
			fi
			DIRCHECK=$(ls -F | grep chromosomes)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir chromosomes
			fi
			DIRCHECK=$(ls -F | grep links)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir links
			fi
			DIRCHECK=$(ls -F | grep labels)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir labels
			fi
			DIRCHECK=$(ls -F | grep domains)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir domains
			fi
			DIRCHECK=$(ls -F | grep coverage)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir coverage
			fi
			DIRCHECK=$(ls -F | grep filedump)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir filedump
			fi
			DIRCHECK=$(ls -F | grep plots)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir plots
			fi
			DIRCHECK=$(ls -F | grep axis)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir axis
			fi
			DIRCHECK=$(ls -F | grep axis_label)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir axis_label
			fi
			DIRCHECK=$(ls -F | grep summaries)
			if [ "$DIRCHECK" = "" ]
			then
				mkdir summaries
			fi
			cd .. ;;
			n|N)
			echo ""
			echo "Please move $FILE-$IDENT-Varia_Out to a new directory or rename input file"
			exit ;;
		esac
fi

echo "Comparing sample to database."
##temporary copy of input file made
cp $FILE.fasta $FILE.alt.fasta
##end of file line added to temp copy
echo '>END OF FILE' >> $FILE.alt.fasta
##list of sample names and their starting lines added to names .txt
grep -n '>' $FILE.alt.fasta > names.txt

##counter set to 1, total sample names set to the number of lines in names.txt
COUNT=1
TOT=$(wc -l names.txt| head -n1| awk '{print $1;}')
##this loop runs for each name in names.txt not including the end of file line
while [ $COUNT -lt $TOT ]
do
	PROGRESS=0
	##sample name extracted from names.txt
	NAME=$(awk -v line="$COUNT" 'NR==line {print}' names.txt| head -n1| cut -d ">" -f2)
	echo "now working on sample: $NAME"
	##the line where the sample begins is set
	BLINE=$(awk -v line="$COUNT" 'NR==line {print}' names.txt| head -n1| cut -d ":" -f1)
	
	##the line where the sample ends is set
	ELINE=$(awk -v line="$((COUNT +1))" 'NR==line {print}' names.txt| head -n1| cut -d ":" -f1)
	ELINE=$((ELINE -1))
	
	##the current sample is copied into a temporary fasta file
	awk -v first="$BLINE" -v last="$ELINE" 'NR>=first&&NR<=last' $FILE.alt.fasta > $NAME.fasta
	
	##sample is blast searched against the database, then the length of the sequence is added

	megablast  -b 2000 -v 2000 -e 1e-10 -m 8 -F F -d $DIR/vardb/megavardb.fasta -i $NAME.fasta -o $NAME.blast
	
	##if no hits to db were found the program notifies user and moves to next sample.
	HITCHECK=true
	FIRSTHIT=$(wc -l $NAME.blast | cut -d ' ' -f 1)
	if [ $FIRSTHIT -eq 0 ]
	then
		echo "no hits found for $NAME in the database, moving to next sample."
		echo $NAME >> no_hits.txt
		HITCHECK=false
	fi
	if [ $HITCHECK = true ]
	then
		PROGRESS=1
		perl $DIR/scripts/helper.putlengthfasta2Blastm8.pl $NAME.fasta $DIR/vardb/megavardb.fasta $NAME.blast
		##fasta index made for temp fasta file
		samtools faidx $NAME.fasta
	
		##genes of interest added to genes.fasta file
		n=$(awk -v identity="$IDENT" '$3>identity && $4>200' $NAME.blast.length | cut -f 2 | awk ' {n=n" "$FILE } END {print n}')
		samtools faidx $DIR/vardb/megavardb.fasta $n >> ${NAME}_genes.fasta
			
		##checks that there are hits remaining after the filter is applied.
		##if not then moves on to the next sample.
		FIRSTHIT=$(wc -l ${NAME}_genes.fasta | cut -d ' ' -f 1)
		if [ $FIRSTHIT -eq 0 ]
		then
			echo "no hits found for $NAME in the database, that met the length and identity cutoff moving to next sample."
			echo $NAME >> no_hits.txt
			HITCHECK=false
		fi
	fi
	if [ $HITCHECK = true ]
	then
		PROGRESS=2
		##cat $NAME.fasta >> $NAME.genes.fasta
		BLAST=$(awk '$3>99 && $4>200' $NAME.blast | wc -l)

		echo "Generating cluster values."

		##genes file blast searched against itself and lengths added
		formatdb -i ${NAME}_genes.fasta -p F -o T -t ${NAME}_db.fasta
		megablast  -b 2000 -v 2000 -e 1e-10 -m 8 -F F -d ${NAME}_genes.fasta -i ${NAME}_genes.fasta -o $NAME.Self.blast
		perl $DIR/scripts/helper.putlengthfasta2Blastm8.pl ${NAME}_genes.fasta ${NAME}_genes.fasta $NAME.Self.blast
		##genes to be passed to mcl added to txt file
		awk '$3>99&& ($4>= (0.8*$13) || $4 >= (0.8*$14))' $NAME.Self.blast.length  | cut -f 1,2,4 > $NAME.formcl.txt
		##checks that there are hits remaining after the filter is applied to self blast.
		##if not then moves on to the next sample.
		FIRSTHIT=$(wc -l $NAME.formcl.txt | cut -d ' ' -f 1)
		if [ $FIRSTHIT -eq 0 ]
		then
			echo "no self hits for $NAME in the database that met the length and identity cutoff, moving to next sample."
			echo $NAME >> no_hits.txt
			HITCHECK=false
		fi
	fi
	if [ $HITCHECK = true ]
	then
		echo "Clustering with mcl."	
		## mcl forms cluster groups of the genes
		mcl $NAME.formcl.txt -q x -V all --abc -o $NAME.clusters.txt
		echo "Generating files for Circos plot."	
		##finds total number of lines in cluster file
		CTOT=$(wc -l $NAME.clusters.txt| head -n1| awk '{print $1;}')
	
		##cluster counter set to 1
		CCOUNT=1
	
		##variables storing the number of clusters and lone genes are set to 0
		CCLUSTER=0
		CSINGLE=0
		
		##loops through lines in the cluster file
		while [ $CCOUNT -le $CTOT ]
		do
			##counts the number of genes on each line, ifi it is 1 then 1 is added to the lone genes counter, if it is >1 then 1 is added to the cluster counter
			CHECK=$(awk -v line="$CCOUNT" 'NR==line {print}' $NAME.clusters.txt| wc -w)
			if [ $CHECK == 1 ]
			then
				CSINGLE=$((CSINGLE + 1))
			else
				CCLUSTER=$((CCLUSTER + 1))
			fi
				
			CCOUNT=$((CCOUNT +1))
		done
	
		##sends line summarising the cluster counter and lone genes counter to cluster summary file
		CRESULT="$NAME has $CCLUSTER cluster(s) and $CSINGLE lone match(es)."
		echo $CRESULT >> mcl_summary_$FILE.txt
		##runs the pythonsort script to make the chromosomes file for sample and the fasta file for blast to use to make a links file
		mv ${NAME}_genes.fasta $NAME.genes.fasta
		python $DIR/scripts/pythonsort.py $NAME
		mv $NAME.forblast.fasta ${NAME}_forblast.fasta
		formatdb -i ${NAME}_forblast.fasta -p F -o T -t ${NAME}_forblast.fasta
		##blast run to perform self comparison of fasta file generated from pythonsort
		megablast  -b 2000 -v 2000 -e 1e-10 -m 8 -F F -d ${NAME}_forblast.fasta -i ${NAME}_forblast.fasta -o $NAME.link.blast
		perl $DIR/scripts/helper.putlengthfasta2Blastm8.pl ${NAME}_forblast.fasta ${NAME}_forblast.fasta $NAME.link.blast

		##runs the labelfile python script to create file containing domain names for sample
		python $DIR/scripts/add_domain.py $NAME $DIR

	
		##adds blast entries to the links file then re-orders the columns into correct format for the link file
		##awk -v identity="$IDENT" '$3>identity && $4>200 && $1!=$2' $NAME.link.blast.length | cut -f 1,7,8,2,9,10 >> 	$NAME.links.txt
		awk -v identity="$IDENT" '$3>99 && $4>200 && $1!=$2' $NAME.link.blast.length | cut -f 1,7,8,2,9,10 >> 			$NAME.links.txt
		awk '{print $1 "\t" $3 "\t" $4 "\t" $2 "\t" $5 "\t" $6}' $NAME.links.txt > $NAME.linked.txt
		## colour added to links using add_color.py
		python $DIR/scripts/add_color.py $NAME
	
		##coverage files for each cluster generated using add_coverage.py
		python $DIR/scripts/add_coverage.py $NAME
	
		##abridges coverage files for each cluster using give_median.py
		while read p; do
			for x in depth.$p.plot; do
			python $DIR/scripts/give_median.py $x 
			done
			mv depth.$p.plot ./$FILE-$IDENT-Varia_Out/filedump/$NAME.depth.$p.plot
			##adds each clusters coverage file to the main coverage file for Circos
			cat plotme.txt >> $NAME.Plot.median.coverage.plot
		done <$NAME.plotlist.txt
	
		##generates the Y axis for each clusters coverage plot
		python $DIR/scripts/add_axis.py $NAME
	
		## removes any mirrored links generated by the self blast 
		python $DIR/scripts/remove_twins.py $NAME
	
		##finds max coverage value
		MAX=$(awk '{print $4}' $NAME.axis_label_max.txt | head -n1)
		MAX=$((MAX + 1))
		##calculates how many lines should be present on coverage plot by dividing 1 by the value of MAX
		RANGE=$(bc <<<"scale=4; 1 / $MAX")
		RANGE=0${RANGE}r
	
		echo "Generating summary files."
		##cluster summary genrated
		python $DIR/scripts/get_clusters.py $NAME $DIR
		##each cluster is blast searched against its largest sequence to help find how many samples in the cluster are 80% length of the largest sequence
		while read p; do
			mv $p.db_seq.txt ${p}_db_seq.fasta
			mv $p.query_seq.txt ${p}_query_seq.fasta
			formatdb -i ${p}_db_seq.fasta -p F -o T -t ${p}_db_seq.fasta
			megablast  -b 2000 -v 2000 -e 1e-10 -m 8 -A 100 -F F -d ${p}_db_seq.fasta -i ${p}_query_seq.fasta -o $p.80.blast
		##coverage file generated for the regions of similarity between genes in a single cluster.
			cut -f 1,2,7,8 $p.80.blast | sort -k 4 -n -r  > $p.cover.txt
			python $DIR/scripts/cluster_coverage.py $p
			rm $p.cover.txt
			python $DIR/scripts/give_median.py $p.plotcov.txt
			rm $p.plotcov.txt
			cat plotme.txt >> $NAME.intraclustcoverage.plot
			rm plotme.txt
		done <$NAME.listclust.txt
		INTRAMAX=$(cut -f 4 $NAME.intraclustcoverage.plot | sort -n | tail -n 1 | awk '{printf "%.0f\n", $1}')
		INTRARANGE=$(bc <<<"scale=4; 1 / $INTRAMAX")
		INTRARANGE=0${INTRARANGE}r
		while read p; do
			MSTORE=$(echo $p | awk '{print $1 "\t" $2 "\t" $3}')
			NSTORE=$(echo $p | awk '{print $1}')
			echo -e "$MSTORE\t0\tr0=1.045r,r1=1.055r" >> $NAME.axis_label_min2.txt
			echo -e "$MSTORE\t$INTRAMAX\tr0=1.125r,r1=1.145r" >> $NAME.axis_label_max2.txt
			echo -e "$NSTORE\t0\t0\t0" >> $NAME.axis_line2.txt
			echo -e "$NSTORE\t0\t0\t$INTRAMAX" >> $NAME.axis_line2.txt
		done <$NAME.axis_label_max.txt
		##final summary file generated
		python $DIR/scripts/give_final.py $NAME
		echo ">${NAME}_tag" > tag.fasta
		sed -n 2p $NAME.fasta >> tag.fasta
		TAGLEN=$(sed -n 2p tag.fasta | wc -c)
		TAGLEN=$(($TAGLEN - 1))
		megablast  -b 2000 -v 2000 -e 1e-10 -m 8 -F F -d ${NAME}_forblast.fasta -i tag.fasta -o ${NAME}_taglink.blast
		cat $NAME.untwin_link.txt >> $NAME.plustag_link.txt
		
		cut -f 1,2,7,8,9,10 ${NAME}_taglink.blast >> linktemp.txt
		awk '{print $1 "\t" $3 "\t" $4 "\t" $2 "\t" $5 "\t" $6 "\tcolor=yellow_a3"}' linktemp.txt >> $NAME.plustag_link.txt
		rm tag.fasta
		rm linktemp.txt
		echo -e "chr\t-\t${NAME}_tag\t${NAME}_tag\t0\t$TAGLEN\tlyellow" >> $NAME.chromosome.txt
		echo "Generating Circos plot."
		##Circos plot generated
		circos -silent -conf $DIR/scripts/Varia.conf -param chromosome_file=$NAME.chromosome.txt -param link_file=$NAME.plustag_link.txt -param domain_file=$NAME.domains.txt -param domain_label_file=$NAME.domain_label.txt -param intracov_file=$NAME.intraclustcoverage.plot -param coverage_file=$NAME.Plot.median.coverage.plot -param axis_file=$NAME.axis_line2.txt -param axis_file2=$NAME.axis_line.txt -param axis_min=$NAME.axis_label_min.txt -param axis_min2=$NAME.axis_label_min2.txt -param axis_max=$NAME.axis_label_max.txt -param axis_max2=$NAME.axis_label_max2.txt -param max=$MAX -param range=$RANGE -param intramax=$INTRAMAX -param intrarange=$INTRARANGE -outputfile $NAME.circos.plot.png
	
		echo "Removing temporary files and organising files."
		##sample specific temporary files deleted
		while read p; do
			rm $p.80.blast
			rm ${p}_query_seq.fasta
			rm ${p}_db_seq.fasta
			rm ${p}_db_seq.fasta.nsq
			rm ${p}_db_seq.fasta.nsi
			rm ${p}_db_seq.fasta.nsd
			rm ${p}_db_seq.fasta.nin
			rm ${p}_db_seq.fasta.nhr
		done <$NAME.listclust.txt
		rm $NAME.listclust.txt
		rm ${NAME}_forblast.fasta.nhr
		rm ${NAME}_forblast.fasta.nin
		rm ${NAME}_forblast.fasta.nsd
		rm ${NAME}_forblast.fasta.nsi
		rm ${NAME}_forblast.fasta.nsq
		##sample specific temporary files moved to filedump directory
		mv ${NAME}_forblast.fasta ./$FILE-$IDENT-Varia_Out/filedump/$NAME.forblast.fasta
		mv $NAME.link.blast ./$FILE-$IDENT-Varia_Out/filedump/$NAME.link.blast
		mv $NAME.link.blast.length ./$FILE-$IDENT-Varia_Out/filedump/$NAME.link.blast.length
		mv $NAME.links.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.links.txt
		mv $NAME.link.txt ./$FILE-$IDENT-Varia_Out/links/$NAME.link.txt
		mv $NAME.linked.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.linked.txt
		mv $NAME.plotlist.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.plotlist.txt
	
		##sample specific result files moved to appropriate directories
		mv $NAME.clusters.txt ./$FILE-$IDENT-Varia_Out/cluster_files/$NAME.clusters.txt
		mv $NAME.chromosome.txt ./$FILE-$IDENT-Varia_Out/chromosomes/$NAME.chromosome.txt
		mv $NAME.domain_label.txt ./$FILE-$IDENT-Varia_Out/labels/$NAME.domain_label.txt
		mv $NAME.domains.txt ./$FILE-$IDENT-Varia_Out/domains/$NAME.domains.txt
		mv $NAME.untwin_link.txt ./$FILE-$IDENT-Varia_Out/links/$NAME.untwin_link.txt
		mv $NAME.plustag_link.txt ./$FILE-$IDENT-Varia_Out/links/$NAME.plustag_link.txt
		mv ${NAME}_taglink.blast ./$FILE-$IDENT-Varia_Out/filedump/${NAME}_taglink.blast
		mv $NAME.axis_line.txt ./$FILE-$IDENT-Varia_Out/axis/$NAME.axis_line.txt
		mv $NAME.axis_line2.txt ./$FILE-$IDENT-Varia_Out/axis/$NAME.axis_line2.txt
		mv $NAME.axis_label_min.txt ./$FILE-$IDENT-Varia_Out/axis_label/$NAME.axis_label_min.txt
		mv $NAME.axis_label_min2.txt ./$FILE-$IDENT-Varia_Out/axis_label/$NAME.axis_label_min2.txt
		mv $NAME.axis_label_max.txt ./$FILE-$IDENT-Varia_Out/axis_label/$NAME.axis_label_max.txt
		mv $NAME.axis_label_max2.txt ./$FILE-$IDENT-Varia_Out/axis_label/$NAME.axis_label_max2.txt
		mv $NAME.Plot.median.coverage.plot ./$FILE-$IDENT-Varia_Out/coverage/$NAME.Plot.median.coverage.plot
		mv $NAME.intraclustcoverage.plot ./$FILE-$IDENT-Varia_Out/coverage/$NAME.intraclustcoverage.plot
		mv $NAME.circos.plot.png ./$FILE-$IDENT-Varia_Out/plots/$NAME.circos.plot.png
		mv $NAME.circos.plot.svg ./$FILE-$IDENT-Varia_Out/plots/$NAME.circos.plot.svg
		mv $NAME.cluster_summary.txt ./$FILE-$IDENT-Varia_Out/summaries/$NAME.cluster_summary.txt
		mv $NAME.final_summary.txt ./$FILE-$IDENT-Varia_Out/summaries/$NAME.final_summary.txt
	fi
	mv $NAME.fasta ./$FILE-$IDENT-Varia_Out/filedump/$NAME.fasta
	mv $NAME.blast ./$FILE-$IDENT-Varia_Out/filedump/$NAME.blast
	if [ $PROGRESS -gt 0 ]
		then
		mv $NAME.fasta.fai ./$FILE-$IDENT-Varia_Out/filedump/$NAME.fasta.fai
		mv $NAME.blast.length ./$FILE-$IDENT-Varia_Out/filedump/$NAME.blast.length
		fi
	if [ $PROGRESS -gt 1 ]
		then
		rm ${NAME}_genes.fasta.nhr
		rm ${NAME}_genes.fasta.nin
		rm ${NAME}_genes.fasta.nsd
		rm ${NAME}_genes.fasta.nsi
		rm ${NAME}_genes.fasta.nsq
		mv $NAME.formcl.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.formcl.txt
		mv $NAME.Self.blast ./$FILE-$IDENT-Varia_Out/filedump/$NAME.Self.blast
		mv $NAME.Self.blast.length ./$FILE-$IDENT-Varia_Out/length/$NAME.Self.blast.length
		fi
	GENECHECK=$(ls -F | grep "${NAME}_genes.fasta")
			if [ "$GENECHECK" != "" ]
			then
				rm ${NAME}_genes.fasta
			fi

	GENECHECK=$(ls -F | grep "$NAME.genes.fasta")
			if [ "$GENECHECK" != "" ]
			then
				mv $NAME.genes.fasta ./$FILE-$IDENT-Varia_Out/filedump/$NAME.genes.fasta

			fi

			
	COUNT=$((COUNT +1))
	echo ""
done

##remaining temporary files removed
mv names.txt ./$FILE-$IDENT-Varia_Out/filedump/names.txt
rm $FILE.alt.fasta

REMCHECK=$(ls -F | grep formatdb.log)
if [ "$REMCHECK" != "" ]
	then
	rm formatdb.log
	fi
if [ "$HERECHECK" = "" ]
then
	rm ./$FILE.fasta
fi

##summary file moved into the Varia1_Out directory
REMCHECK=$(ls -F | grep mcl_summary_$FILE.txt)
if [ "$REMCHECK" != "" ]
	then
	mv mcl_summary_$FILE.txt ./$FILE-$IDENT-Varia_Out/summaries/mcl_summary_$FILE.txt
	fi
REMCHECK=$(ls -F | grep no_hits.txt)
if [ "$REMCHECK" != "" ]
	then
	mv no_hits.txt ./$FILE-$IDENT-Varia_Out/summaries/no_hits.txt
	fi
echo ""
echo "Done!"
echo ""
echo "Circos plots are located in:"
echo "./$FILE-$IDENT-Varia_Out/plots/$NAME.circos.plot.png"
echo "./$FILE-$IDENT-Varia_Out/plots/$NAME.circos.plot.svg"
echo ""
echo "Summary files are located in:"
echo "./$FILE-$IDENT-Varia_Out/summaries/$NAME.cluster_summary.txt"
echo "./$FILE-$IDENT-Varia_Out/summaries/$NAME.final_summary.txt"
