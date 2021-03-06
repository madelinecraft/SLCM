*** Import and organize data;
proc import datafile="C:\Users\mcraft\Desktop\chaiken_blozis2004.xlsx" out=chaiken dbms = xlsx replace; run;
data quant;
	set chaiken;
	keep subid qrt1-qrt12;
run;
data quant_long;
	set quant;
	array quantvar[12] qrt1-qrt12;
	do i = 1 to 12;
	quant = quantvar [i]; 
	output; end;
	drop i qrt1-qrt12 ;
run;
data quant_long;
  set quant_long;
  count + 1;
  by subid;
  if first.subid then count = 1;
run;

*** Exploratory plots;
* Preparatory code;
ods output solutionf=sf(keep=effect estimate  
                                 rename=(estimate=FE));
ods output solutionr=sr(keep=effect M2ID estimate
                                 rename=(estimate=RE));
proc mixed data=quant_long;
	class subid;
    model quant = count/ s outp = pred;
    random int / s g gcorr type=un subject=subid;
run; quit;
ods output close;
data subpred;
	set pred;
	where subid = 73 or subid = 171 or subid = 77  or subid = 189 or subid = 177 or subid = 181 or subid = 112 or subid = 136;
run;
data subpred2;
	set pred;
	where subid = 73 or subid = 171 or subid = 77  or subid = 189 or subid = 177 or subid = 181 or subid = 112 or subid = 136
	or subid = 113 or subid = 199 or subid = 124  or subid = 118 or subid = 91 or subid = 5 or subid = 228 or subid = 116;
run;
ods pdf file = 'BrownBagPlots.pdf';
* 4x2 scatterplots with fitted trajectories;
proc sgpanel data=subpred;
	panelby subid / columns=4 spacing=5;
	styleattrs datacolors=(GRAY4F);
	scatter x = count y = quant;
	rowaxis label = "Response Time (Milliseconds)";
	colaxis label = "Trial" display = all values = (1 to 12 by 1);
	series x = count y = pred / lineattrs = (color = black) 
	legendlabel = "Fitted Values";
	*reg x=count y=quant/ cli clm;
	title "Fitted Intercepts for a Random Subsample of Eight Individuals";
run;
* Overlaid trajectories;
proc sgplot data = subpred2 noautolegend; 
	styleattrs datalinepatterns = (solid shortdash mediumdash longdash 
	mediumdashshortdash dashdashdot dash dot)
	datasymbols = (circle circlefilled diamond diamondfilled 
	triangle trianglefilled square squarefilled)
	datacontrastcolors = (black);
	series x = count y = quant / group = subid;
	scatter x = count y = quant / group = subid;
	xaxis label = "Trial" display=ALL values = (1 to 12 by 1);
	yaxis label = "Response Time (Milliseconds)";
	title "Overlayed Trajectories for a Random Subsample of 16 Individuals";
run;
* Distribution of response time;
proc sgplot data=quant_long;
  title "Distribution of Response Time";
  histogram quant;
  xaxis label = "Response Time (Milliseconds)";
run;
ods pdf close;

*** Models;
* Obtain starting values;
proc glmmix;
	model quant = count / dist = gamma s;
run;
* Center trials variable;
data quant_long;
	set quant_long;
	cencount = count-1;
run;
* b0 is the initial value at t = 0;
* b2 is the asymptote as t goes to infinite;
* b1 is the rate of change;
proc nlmixed data = quant_long;
	parms b0=0.95 b1=-0.39 b2=2.13 scale=13.32 varu=0.01;
	linp = b2+(b0-b2)*exp(b1*cencount)+u1;
	mu=exp(linp);
	b=mu/scale;
	model quant ~ gamma(scale,b);
	random u1 ~ normal (0, varu) subject = subid;
	predict mu out=fit;
run;
* Final plot of fitted trajectories;
ods pdf file = 'expoplot.pdf';
proc sgplot data=fit;
	scatter x=count y=quant / group=subid;
	series x=count y=pred / group=subid;
	xaxis label = "Trial" values = (1 to 12 by 1);
	yaxis label = "Response Time (Milliseconds)";
run;
ods pdf close;
