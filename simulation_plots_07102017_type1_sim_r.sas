%include "u:\thesis\master thesis\simulation\simulation_macro_1104_sim_r.sas"; 
%library(mm = 11, dd = 04);

%macro plotsdata(method = , mis = , nsub = , mech = , waist_hip = , cc = );
%&method.(libname = sim, dsname = sim&mis., nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = &cc.);
%if &method. = mixed %then %do;
data sim&mis._&nsub._&waist_hip._&cc.;
    set sim.sim&mis._&nsub._&waist_hip.;
	where effect = "post*treatment";
	if probt < 0.05 then &method._&cc. = 1;
	    else &method._&cc. = 0;
run;
%end;
%else %if &method. = ancova %then %do;
%if &cc. ne  %then %do;
data sim&mis._&nsub._&waist_hip._&cc.;
    set sim.ancova_&nsub._&mech._&cc._&waist_hip.;
	where type = "PVALUE";
	if treatment < 0.05 then &method._&cc. = 1;
	    else &method._&cc. = 0;
run;
%end;
%else %do;
data sim&mis._&nsub._&waist_hip._&cc.;
    set sim.ancova_&nsub._&mech._&waist_hip.;
	where parm = "treatment";
	if probt < 0.05 then &method._&cc. = 1;
	    else &method._&cc. = 0;
run;
%end;
%end;
proc means data = sim&mis._&nsub._&waist_hip._&cc.;
    var &method._&cc.;
	output out = sumstat;
run;
data &method.&mis._&nsub._&mech._&waist_hip._&cc.;
    set sumstat;
	mis = &mis.;
	where _stat_ = "MEAN";
	drop _type_;
run;
%mend;

%macro data_method(method = , nsub = , mech = , waist_hip = , cc = );
%plotsdata(method = &method.,  mis = 20, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = &cc.);
%plotsdata(method = &method.,  mis = 30, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = &cc.);
%plotsdata(method = &method.,  mis = 40, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = &cc.);
%plotsdata(method = &method.,  mis = 50, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = &cc.);
data &method._&nsub._&mech._&waist_hip._&cc.;
    set &method.20_&nsub._&mech._&waist_hip._&cc.
	    &method.30_&nsub._&mech._&waist_hip._&cc.
		&method.40_&nsub._&mech._&waist_hip._&cc.
		&method.50_&nsub._&mech._&waist_hip._&cc.;
run;
%mend;


%macro data_plot1(nsub = , mech = , waist_hip = );
%data_method(method = mixed, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = );
%data_method(method = mixed, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = cc);
%data_method(method = ancova, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = );
%data_method(method = ancova, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = cc);

data plot_&nsub._&mech._&waist_hip.;
    merge mixed_&nsub._&mech._&waist_hip._
	      mixed_&nsub._&mech._&waist_hip._cc
		  ancova_&nsub._&mech._&waist_hip._
		  ancova_&nsub._&mech._&waist_hip._cc;
run;

title;

ods html file = "plots for thesis.html" gpath = "u:\";
ods graphics on / imagename = "plot_&nsub._&mech._&waist_hip." noborder;
proc sgplot data = plot_&nsub._&mech._&waist_hip.;
	xaxis label = "Percentage of Missing Data" type = discrete labelattrs = (size = 16);
    yaxis label = "Type-I Error Rate" min = .02 max = .08 minor labelattrs = (size = 16);
    series x = mis y = mixed_ / markers datalabel lineattrs = (color = black pattern = 1 thickness = 2) markerattrs = (color = black symbol = circle) legendlabel = "Mixed Model, AA" name = "Mixed Model, AA";
    series x = mis y = mixed_cc / markers datalabel lineattrs = (color = black pattern = 41 thickness = 2) markerattrs = (color = black symbol = diamond) legendlabel = "Mixed Model, CC" name = "Mixed Model, CC";
    series x = mis y = ancova_ / markers datalabel lineattrs = (color = black pattern = 5 thickness = 2) markerattrs = (color = black symbol = circlefilled)legendlabel = "ANCOVA, MI" name = "ANCOVA, MI";
    series x = mis y = ancova_cc / markers datalabel lineattrs = (color = black pattern = 34 thickness = 2) markerattrs = (color = black symbol = diamondfilled)legendlabel = "ANCOVA, CC" name = "ANCOVA, CC";
    *label mixed_ = "Mixed Model, AA"
	      mixed_cc = "Mixed Model, CC"
		  ancova_ = "ANCOVA, MI"
	      ancova_cc = "ANCOVA, CC";
	keylegend "Mixed Model, AA" "Mixed Model, CC" "ANCOVA, MI" "ANCOVA, CC" / location = inside position = bottomleft across = 2 valueattrs = (size = 14);
	/*title "Power Comparison for &mech. (n = &nsub./Group &waist_hip.)";*/
run;
ods graphics off;
ods html close;
%mend;

%macro data_plot2(nsub = , mech = , waist_hip = );
%data_method(method = mixed, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = );
%data_method(method = mixed, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = cc);
%data_method(method = ancova, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = );
%data_method(method = ancova, nsub = &nsub., mech = &mech., waist_hip = &waist_hip., cc = cc);

data plot_&nsub._&mech._&waist_hip.;
    merge mixed_&nsub._&mech._&waist_hip._
	      mixed_&nsub._&mech._&waist_hip._cc
		  ancova_&nsub._&mech._&waist_hip._
		  ancova_&nsub._&mech._&waist_hip._cc;
run;

title;

ods html file = "plots for thesis.html" gpath = "u:\";
ods graphics on / imagename = "plot_&nsub._&mech._&waist_hip." noborder;
proc sgplot data = plot_&nsub._&mech._&waist_hip.;
	xaxis label = "Percentage of Missing Data" type = discrete labelattrs = (size = 16);
    yaxis label = "Type-I Error Rate" min = .02 max = .08 minor labelattrs = (size = 16);
    series x = mis y = mixed_ / markers datalabel lineattrs = (color = black pattern = 1 thickness = 2) markerattrs = (color = black symbol = circle) legendlabel = "Mixed Model, AA" name = "Mixed Model, AA";
    series x = mis y = mixed_cc / markers datalabel lineattrs = (color = black pattern = 41 thickness = 2) markerattrs = (color = black symbol = diamond) legendlabel = "Mixed Model, CC" name = "Mixed Model, CC";
    series x = mis y = ancova_ / markers datalabel lineattrs = (color = black pattern = 5 thickness = 2) markerattrs = (color = black symbol = circlefilled)legendlabel = "ANCOVA, MI" name = "ANCOVA, MI";
    series x = mis y = ancova_cc / markers datalabel lineattrs = (color = black pattern = 34 thickness = 2) markerattrs = (color = black symbol = diamondfilled)legendlabel = "ANCOVA, CC" name = "ANCOVA, CC";
    *label mixed_ = "Mixed Model, AA"
	      mixed_cc = "Mixed Model, CC"
		  ancova_ = "ANCOVA, MI"
	      ancova_cc = "ANCOVA, CC";
	keylegend "Mixed Model, AA" "Mixed Model, CC" "ANCOVA, MI" "ANCOVA, CC" / location = inside position = bottomleft across = 2 valueattrs = (size = 14);
	/*title "Power Comparison for &mech. (n = &nsub./Group &waist_hip.)";*/
run;
ods graphics off;
ods html close;
%mend;

%data_plot1(nsub = 35,  mech = mcar, waist_hip = );
%data_plot1(nsub = 35,  mech = mcar, waist_hip = wh);
%data_plot2(nsub = 100, mech = mcar, waist_hip = );
%data_plot2(nsub = 100, mech = mcar, waist_hip = wh);

%data_plot1(nsub = 35,  mech = mar_wh, waist_hip = );
%data_plot1(nsub = 35,  mech = mar_wh, waist_hip = wh);
%data_plot2(nsub = 100, mech = mar_wh, waist_hip = );
%data_plot2(nsub = 100, mech = mar_wh, waist_hip = wh);

%data_plot1(nsub = 35,  mech = mar_wh_pre, waist_hip = );
%data_plot1(nsub = 35,  mech = mar_wh_pre, waist_hip = wh);
%data_plot2(nsub = 100, mech = mar_wh_pre, waist_hip = );
%data_plot2(nsub = 100, mech = mar_wh_pre, waist_hip = wh);

%data_plot1(nsub = 35,  mech = mar_wh_pre_tx, waist_hip = );
%data_plot1(nsub = 35,  mech = mar_wh_pre_tx, waist_hip = wh);
%data_plot2(nsub = 100, mech = mar_wh_pre_tx, waist_hip = );
%data_plot2(nsub = 100, mech = mar_wh_pre_tx, waist_hip = wh);

%data_plot1(nsub = 35,  mech = mar_wptpt, waist_hip = );
%data_plot1(nsub = 35,  mech = mar_wptpt, waist_hip = wh);
%data_plot2(nsub = 100, mech = mar_wptpt, waist_hip = );
%data_plot2(nsub = 100, mech = mar_wptpt, waist_hip = wh);









*test;
ods html file = "plots for thesis.html" gpath = "u:\";
ods graphics on / imagename = "plot_35_mcar_" noborder;
proc sgplot data = plot_35_mcar_;
	xaxis label = "Percentage of Missing Data" type = discrete labelattrs = (size = 16);
    yaxis label = "Power" min = .4 max = .8 labelattrs = (size = 16);
    series x = mis y = mixed_ / markers datalabel lineattrs = (color = black pattern = 1 thickness = 2) markerattrs = (color = black symbol = circle) legendlabel = "Mixed Model, AA" name = "Mixed Model, AA";
    series x = mis y = mixed_cc / markers datalabel lineattrs = (color = black pattern = 41 thickness = 2) markerattrs = (color = black symbol = diamond) legendlabel = "Mixed Model, CC" name = "Mixed Model, CC";
    series x = mis y = ancova_ / markers datalabel lineattrs = (color = black pattern = 5 thickness = 2) markerattrs = (color = black symbol = circlefilled)legendlabel = "ANCOVA, MI" name = "ANCOVA, MI";
    series x = mis y = ancova_cc / markers datalabel lineattrs = (color = black pattern = 34 thickness = 2) markerattrs = (color = black symbol = diamondfilled)legendlabel = "ANCOVA, CC" name = "ANCOVA, CC";
    *label mixed_ = "Mixed Model, AA"
	      mixed_cc = "Mixed Model, CC"
		  ancova_ = "ANCOVA, MI"
	      ancova_cc = "ANCOVA, CC";
	keylegend "Mixed Model, AA" "Mixed Model, CC" "ANCOVA, MI" "ANCOVA, CC" / location = inside position = bottomleft across = 2 valueattrs = (size = 14);
	title "Power Comparison for MCAR When n = 35/Group ";
run;
ods graphics off;
ods html close;
