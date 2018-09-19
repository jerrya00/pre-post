***type changed from cs to un 11/4/2015;
*set b3 = b4 = 0 for type I error 11/4/2015;

%include "u:\thesis\master thesis\simulation\simulation_macro_1104_sim_r.sas"; 
%library(mm = 11, dd = 04);




*b0 - b5, var_b, and var_e come from the following mixed model;
proc mixed data = data.mixed noclprint noitprint;
    class subid;
	model t = post waist_hip treatment treatment * post / s ddfm = kenwardroger;
	repeated / type = un subject = subid; ***type changed from cs to un 11/4/2015;
	ods output SolutionF = est_para_original CovParms = est_cov_original;
run;

*Coefficient for p_wh;
proc logistic data = data.ancova;
    class dropout (ref = "0");
    model dropout = waist_hip;
	ods select parameterestimates;
run;
quit;

*Coefficient for p_wh_pre;
proc logistic data = data.ancova;
    class dropout (ref = "0");
    model dropout = waist_hip pre_t;
	ods select parameterestimates;
run;
quit;






*Data generation;
%data20(libname = sim, dsname = sim20, seed = 513471, nreps = 500, nsub = 35, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;
%data20(libname = sim, dsname = sim20, seed = 513471, nreps = 500, nsub = 100, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;

%data30(libname = sim, dsname = sim30, seed = 513471, nreps = 500, nsub = 35, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;
%data30(libname = sim, dsname = sim30, seed = 513471, nreps = 500, nsub = 100, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;

%data40(libname = sim, dsname = sim40, seed = 513471, nreps = 500, nsub = 35, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;
%data40(libname = sim, dsname = sim40, seed = 513471, nreps = 500, nsub = 100, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;

%data50(libname = sim, dsname = sim50, seed = 513471, nreps = 500, nsub = 35, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;
%data50(libname = sim, dsname = sim50, seed = 513471, nreps = 500, nsub = 100, 
      b0 = 17.9464, b1 = -0.8111, b2 = -2, b3 = 0, b4 = 0, b5 = 0, var_b = 3.0689, var_e = 1.0047); *set b3 = b4 = 0 for type I error 11/4/2015;





*Check % missingness;
proc means data = sim.sim20_35;
    var mcar mar_wh mar_wh_pre mar_wh_pre_tx;
run;

proc means data = sim.sim20_100;
    var mcar mar_wh mar_wh_pre mar_wh_pre_tx;
run;

*Check correlation between pre and post scores;
proc corr data = sim.sim20_35_ancova outp = correlation;
    var y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_pre;
	by nreps;
run;
data correlation;
    set correlation;
	where _name_ = "y_pre";
	keep nreps y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre;
run;
proc means data = correlation;
run;



*Analyses;
%result(method = mixed,  mis = 20);
%result(method = ancova, mis = 20);

%result(method = mixed,  mis = 30);
%result(method = ancova, mis = 30);

%result(method = mixed,  mis = 40);
%result(method = ancova, mis = 40);

%result(method = mixed,  mis = 50);
%result(method = ancova, mis = 50);


