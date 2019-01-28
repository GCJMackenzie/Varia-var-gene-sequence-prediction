# Varia-var-gene-sequence-prediction
Varia predicts the sequence of var genes in Plasmodium falciparum. Varia is designed to use the DBL alpha tags supplied by the user to find the full sequenc of the var gene, by comparing the tag to the Pf3k database for near identical tag regions. It then clusters all hits and presents the largest sequence of each clusteron the Circos plot and in the summary files.

Use by running command:
Varia.sh [Name_of_input.fasta] [Identity_score (1-100)]