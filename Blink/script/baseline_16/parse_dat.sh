#!/bin/bash
cat $1 | awk -F, 'BEGIN { OFS=","; }
{ 
	#if (NR <= 2560)
	print $2,$3,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25;
}'
