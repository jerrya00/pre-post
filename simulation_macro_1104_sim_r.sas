


/*Macros in this file*/
/*%library -> Call the libraries*/
/*%data20 -> Generate data set with 20% missingness*/
/*%data30 -> Generate data set with 30% missingness*/
/*%data40 -> Generate data set with 40% missingness*/
/*%data50 -> Generate data set with 50% missingness*/
/*%mixed -> Mixed model for fully observed data, complete cases, and available cases*/
/*%ancova -> ANCOVA for fully observed data, complete cases, and available cases (including MI)*/
/*%result -> Analyzing the data using either mixed model or ANCOVA*/





*library;
%macro library(mm = , dd = );
options DLCREATEDIR;
libname data "u:\thesis\master thesis\data"; /*library for experiment data*/
libname sim "u:\thesis\master thesis\simulation\sim&mm.&dd."; /*library for simulation data*/
%mend;






*Data Generation;
/*libname = library name*/
/*dsname = name for created data set*/
/*seed = starting seed value*/
/*nreps = number of replicates*/
/*nsub = number of subjects in each group*/
/*b0 = estimated coefficient for intercept*/
/*b1 = estimated coefficient for time*/
/*b2 = estimated coefficient for waist_hip*/
/*b3 = estimated coefficient for treatment*/
/*b4 = estimated coefficient for treatment * time*/
/*b5 = estimated coefficient for waist_hip * time*/
/*var_b = estimated variance for b_i*/
/*var_e = estimated variance for e_ij*/

*Generate data set with 20% missingness;
%macro data20(libname = , dsname = , seed = , nreps = , nsub = , b0 = , b1 = , b2 = ,
              b3 = , b4 = , b5 = , var_b = , var_e = );
data &dsname._&nsub.;
    retain nreps subid y post waist_hip treatment;
    call streaminit(&seed);
	do nreps = 1 to &nreps;
	    do subid = 1 to 2 * &nsub;
	        if subid <= &nsub then treatment = 0;
		        else treatment = 1;
	     	waist_hip = rand('normal', 0.9381308532, 0.3485664653);
			b_i = rand('normal', 0, sqrt(&var_b));
            do post = 0 to 1;
				e_ij = rand('normal', 0, sqrt(&var_e));
				y = b_i + &b0 + &b1 * post + &b2 * waist_hip + &b3 * treatment 
                   + &b4 * (treatment * post) + &b5 * (waist_hip * post) + e_ij;
				output;
			end;    
	    end;
	end;
run;

/*Set 20% post scores to missing*/
data &libname..&dsname._&nsub.;
    set &dsname._&nsub.;
	call streaminit(32574435);
	y_mcar = y;
	y_mar_wh = y;
	y_mar_wh_pre = y;
	y_mar_wh_pre_tx = y;
	y_mar_wptpt = y;
	p_wh =         exp(-3.251829 + 1.988565 * waist_hip) / 
                  (exp(-3.251829 + 1.988565 * waist_hip) + 1);
    p_wh_pre =     exp(-4.91007 + 1.988565 * waist_hip + 0.0935 * y) / 
                  (exp(-4.91007 + 1.988565 * waist_hip + 0.0935 * y) + 1);
	p_wh_pre_tx =  exp(-5.603217 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) / 
                  (exp(-5.603217 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) + 1);
				  /*from BePHIT*/
	p_wptpt =      exp(-3.250643 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) / 
                  (exp(-3.250643 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) + 1);
				  /*from three equations set log(OR) = b3 + b4 * pre = log(2)*/
	/*p_wptpt =      exp(-5.212413 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) / 
                  (exp(-5.212413 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) + 1);*/
    lag_p_wh_pre = lag(p_wh_pre);
	lag_p_wh_pre_tx = lag(p_wh_pre_tx);
	lag_p_wptpt = lag(p_wptpt);
	if post = 1 then do;
	mcar = rand('bernoulli', .2);
        if mcar = 1 then y_mcar = .;
    mar_wh = rand('bernoulli', p_wh);
	    if mar_wh = 1 then y_mar_wh = .;
	mar_wh_pre = rand('bernoulli', lag_p_wh_pre);
	    if mar_wh_pre = 1 then y_mar_wh_pre = .;
	mar_wh_pre_tx = rand('bernoulli', lag_p_wh_pre_tx);
	    if mar_wh_pre_tx = 1 then y_mar_wh_pre_tx = .;
	mar_wptpt = rand('bernoulli', lag_p_wptpt);
	    if mar_wptpt = 1 then y_mar_wptpt = .;
	end;
	rename waist_hip = wh;
run;

/*Construct dataset for MI*/
data test;
    if not eof then do;
	set &libname..&dsname._&nsub.
        (firstobs = 2 rename = (y               = y_post_c 
                                y_mcar          = y_post_mcar 
                                y_mar_wh        = y_post_mar_wh 
                                y_mar_wh_pre    = y_post_mar_wh_pre 
								y_mar_wh_pre_tx = y_post_mar_wh_pre_tx
                                y_mar_wptpt     = y_post_mar_wptpt
                                e_ij = e_ij_post)) end = eof;
	end;
	set &libname..&dsname._&nsub.
        (rename = (y_mcar = y_pre e_ij = e_ij_pre));
	by nreps subid;
	if last.subid then y_post = . ;
	if not first.subid then delete;
run;
data &libname..&dsname._&nsub._ancova;
    retain nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
    set test;
	keep nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
run;

/*Calculate the mean of y_pre (for the missing data senario MAR dependent on wh, y_pre, trt, and y_pre * trt)*/
/*
proc means data = &libname..&dsname._&nsub._ancova;
    var y_pre;
	title "Mean of y_pre for dataset &libname..&dsname._&nsub._ancova";
run;
*/
%mend;






*Generate data set with 30% missingness;
%macro data30(libname = , dsname = , seed = , nreps = , nsub = , b0 = , b1 = , b2 = ,
              b3 = , b4 = , b5 = , var_b = , var_e = );
data &dsname._&nsub.;
    retain nreps subid y post waist_hip treatment;
    call streaminit(&seed);
	do nreps = 1 to &nreps;
	    do subid = 1 to 2 * &nsub;
	        if subid <= &nsub then treatment = 0;
		        else treatment = 1;
	     	waist_hip = rand('normal', 0.9381308532, 0.3485664653);
			b_i = rand('normal', 0, sqrt(&var_b));
            do post = 0 to 1;
				e_ij = rand('normal', 0, sqrt(&var_e));
				y = b_i + &b0 + &b1 * post + &b2 * waist_hip + &b3 * treatment 
                   + &b4 * (treatment * post) + &b5 * (waist_hip * post) + e_ij;
				output;
			end;    
	    end;
	end;
run;

/*Set 30% post scores to missing*/
data &libname..&dsname._&nsub.;
    set &dsname._&nsub.;
	call streaminit(32574435);
	y_mcar = y;
	y_mar_wh = y;
	y_mar_wh_pre = y;
	y_mar_wh_pre_tx = y;
	y_mar_wptpt = y;
	p_wh =         exp(-2.712832 + 1.988565 * waist_hip) / 
                  (exp(-2.712832 + 1.988565 * waist_hip) + 1);
    p_wh_pre =     exp(-4.371074 + 1.988565 * waist_hip + 0.0935 * y) / 
                  (exp(-4.371074 + 1.988565 * waist_hip + 0.0935 * y) + 1);
	p_wh_pre_tx =  exp(-5.064221 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) / 
                  (exp(-5.064221 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) + 1);
				  /*from BePHIT*/
	p_wptpt =      exp(- 2.711646 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) / 
                  (exp(- 2.711646 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) + 1);
				  /*from three equations set log(OR) = b3 + b4 * pre = log(2)*/
	/*p_wptpt =      exp(- 4.673416 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) / 
                  (exp(- 4.673416 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) + 1);*/
    lag_p_wh_pre = lag(p_wh_pre);
	lag_p_wh_pre_tx = lag(p_wh_pre_tx);
	lag_p_wptpt = lag(p_wptpt);
	if post = 1 then do;
	mcar = rand('bernoulli', .3);
        if mcar = 1 then y_mcar = .;
    mar_wh = rand('bernoulli', p_wh);
	    if mar_wh = 1 then y_mar_wh = .;
	mar_wh_pre = rand('bernoulli', lag_p_wh_pre);
	    if mar_wh_pre = 1 then y_mar_wh_pre = .;
	mar_wh_pre_tx = rand('bernoulli', lag_p_wh_pre_tx);
	    if mar_wh_pre_tx = 1 then y_mar_wh_pre_tx = .;
	mar_wptpt = rand('bernoulli', lag_p_wptpt);
	    if mar_wptpt = 1 then y_mar_wptpt = .;
	end;
	rename waist_hip = wh;
run;

/*Construct dataset for MI*/
data test;
    if not eof then do;
	set &libname..&dsname._&nsub.
        (firstobs = 2 rename = (y               = y_post_c 
                                y_mcar          = y_post_mcar 
                                y_mar_wh        = y_post_mar_wh 
                                y_mar_wh_pre    = y_post_mar_wh_pre 
								y_mar_wh_pre_tx = y_post_mar_wh_pre_tx
                                y_mar_wptpt     = y_post_mar_wptpt
                                e_ij = e_ij_post)) end = eof;
	end;
	set &libname..&dsname._&nsub.
        (rename = (y_mcar = y_pre e_ij = e_ij_pre));
	by nreps subid;
	if last.subid then y_post = . ;
	if not first.subid then delete;
run;
data &libname..&dsname._&nsub._ancova;
    retain nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
    set test;
	keep nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
run;

/*Calculate the mean of y_pre (for the missing data senario MAR dependent on wh, y_pre, trt, and y_pre * trt)*/
/*
proc means data = &libname..&dsname._&nsub._ancova;
    var y_pre;
	title "Mean of y_pre for dataset &libname..&dsname._&nsub._ancova";
run;
*/
%mend;







*Generate data set with 40% missingness;
%macro data40(libname = , dsname = , seed = , nreps = , nsub = , b0 = , b1 = , b2 = ,
              b3 = , b4 = , b5 = , var_b = , var_e = );
data &dsname._&nsub.;
    retain nreps subid y post waist_hip treatment;
    call streaminit(&seed);
	do nreps = 1 to &nreps;
	    do subid = 1 to 2 * &nsub;
	        if subid <= &nsub then treatment = 0;
		        else treatment = 1;
	     	waist_hip = rand('normal', 0.9381308532, 0.3485664653);
			b_i = rand('normal', 0, sqrt(&var_b));
            do post = 0 to 1;
				e_ij = rand('normal', 0, sqrt(&var_e));
				y = b_i + &b0 + &b1 * post + &b2 * waist_hip + &b3 * treatment 
                   + &b4 * (treatment * post) + &b5 * (waist_hip * post) + e_ij;
				output;
			end;    
	    end;
	end;
run;









/*Set 40% post scores to missing*/
data &libname..&dsname._&nsub.;
    set &dsname._&nsub.;
	call streaminit(32574435);
	y_mcar = y;
	y_mar_wh = y;
	y_mar_wh_pre = y;
	y_mar_wh_pre_tx = y;
	y_mar_wptpt = y;
	p_wh =         exp(-2.271 + 1.988565 * waist_hip) / 
                  (exp(-2.271 + 1.988565 * waist_hip) + 1);
    p_wh_pre =     exp(-3.929241 + 1.988565 * waist_hip + 0.0935 * y) / 
                  (exp(-3.929241 + 1.988565 * waist_hip + 0.0935 * y) + 1);
	p_wh_pre_tx =  exp(-4.622388 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) / 
                  (exp(-4.622388 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) + 1);
				  /*from BePHIT*/
	p_wptpt =      exp(-2.269813 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) / 
                  (exp(-2.269813 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) + 1);
				  /*from three equations set log(OR) = b3 + b4 * pre = log(2)*/
	/*p_wptpt =      exp(-4.231583 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) / 
                  (exp(-4.231583 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) + 1);*/
    lag_p_wh_pre = lag(p_wh_pre);
	lag_p_wh_pre_tx = lag(p_wh_pre_tx);
	lag_p_wptpt = lag(p_wptpt);
	if post = 1 then do;
	mcar = rand('bernoulli', .4);
        if mcar = 1 then y_mcar = .;
    mar_wh = rand('bernoulli', p_wh);
	    if mar_wh = 1 then y_mar_wh = .;
	mar_wh_pre = rand('bernoulli', lag_p_wh_pre);
	    if mar_wh_pre = 1 then y_mar_wh_pre = .;
	mar_wh_pre_tx = rand('bernoulli', lag_p_wh_pre_tx);
	    if mar_wh_pre_tx = 1 then y_mar_wh_pre_tx = .;
	mar_wptpt = rand('bernoulli', lag_p_wptpt);
	    if mar_wptpt = 1 then y_mar_wptpt = .;
	end;
	rename waist_hip = wh;
run;

/*Construct dataset for MI*/
data test;
    if not eof then do;
	set &libname..&dsname._&nsub.
        (firstobs = 2 rename = (y               = y_post_c 
                                y_mcar          = y_post_mcar 
                                y_mar_wh        = y_post_mar_wh 
                                y_mar_wh_pre    = y_post_mar_wh_pre 
								y_mar_wh_pre_tx = y_post_mar_wh_pre_tx
                                y_mar_wptpt     = y_post_mar_wptpt
                                e_ij = e_ij_post)) end = eof;
	end;
	set &libname..&dsname._&nsub.
        (rename = (y_mcar = y_pre e_ij = e_ij_pre));
	by nreps subid;
	if last.subid then y_post = . ;
	if not first.subid then delete;
run;
data &libname..&dsname._&nsub._ancova;
    retain nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
    set test;
	keep nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
run;

/*Calculate the mean of y_pre (for the missing data senario MAR dependent on wh, y_pre, trt, and y_pre * trt)*/
/*
proc means data = &libname..&dsname._&nsub._ancova;
    var y_pre;
	title "Mean of y_pre for dataset &libname..&dsname._&nsub._ancova";
run;
*/
%mend;







*Generate data set with 50% missingness;
%macro data50(libname = , dsname = , seed = , nreps = , nsub = , b0 = , b1 = , b2 = ,
              b3 = , b4 = , b5 = , var_b = , var_e = );
data &dsname._&nsub.;
    retain nreps subid y post waist_hip treatment;
    call streaminit(&seed);
	do nreps = 1 to &nreps;
	    do subid = 1 to 2 * &nsub;
	        if subid <= &nsub then treatment = 0;
		        else treatment = 1;
	     	waist_hip = rand('normal', 0.9381308532, 0.3485664653);
			b_i = rand('normal', 0, sqrt(&var_b));
            do post = 0 to 1;
				e_ij = rand('normal', 0, sqrt(&var_e));
				y = b_i + &b0 + &b1 * post + &b2 * waist_hip + &b3 * treatment 
                   + &b4 * (treatment * post) + &b5 * (waist_hip * post) + e_ij;
				output;
			end;    
	    end;
	end;
run;

/*Set 50% post scores to missing*/
data &libname..&dsname._&nsub.;
    set &dsname._&nsub.;
	call streaminit(32574435);
	y_mcar = y;
	y_mar_wh = y;
	y_mar_wh_pre = y;
	y_mar_wh_pre_tx = y;
	y_mar_wptpt = y;
	p_wh =         exp(-1.865534 + 1.988565 * waist_hip) / 
                  (exp(-1.865534 + 1.988565 * waist_hip) + 1);
    p_wh_pre =     exp(-3.523776 + 1.988565 * waist_hip + 0.0935 * y) / 
                  (exp(-3.523776 + 1.988565 * waist_hip + 0.0935 * y) + 1);
	p_wh_pre_tx =  exp(-4.216923 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) / 
                  (exp(-4.216923 + 1.988565 * waist_hip + 0.0935 * y + 1.386294 * treatment) + 1);
				  /*from BePHIT*/
	p_wptpt =      exp(- 1.864348 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) / 
                  (exp(- 1.864348 + 1.988565 * waist_hip - 0.03915 * y - 3.318855 * treatment + 0.2653 * y * treatment) + 1);
				  /*from three equations set log(OR) = b3 + b4 * pre = log(2)*/
	/*p_wptpt =      exp(- 3.826118 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) / 
                  (exp(- 3.826118 + 1.988565 * waist_hip + 0.07146447 * y + 0.604685 * treatment + 0.04407105 * y * treatment) + 1);*/
    lag_p_wh_pre = lag(p_wh_pre);
	lag_p_wh_pre_tx = lag(p_wh_pre_tx);
	lag_p_wptpt = lag(p_wptpt);
	if post = 1 then do;
	mcar = rand('bernoulli', .5);
        if mcar = 1 then y_mcar = .;
    mar_wh = rand('bernoulli', p_wh);
	    if mar_wh = 1 then y_mar_wh = .;
	mar_wh_pre = rand('bernoulli', lag_p_wh_pre);
	    if mar_wh_pre = 1 then y_mar_wh_pre = .;
	mar_wh_pre_tx = rand('bernoulli', lag_p_wh_pre_tx);
	    if mar_wh_pre_tx = 1 then y_mar_wh_pre_tx = .;
	mar_wptpt = rand('bernoulli', lag_p_wptpt);
	    if mar_wptpt = 1 then y_mar_wptpt = .;
	end;
	rename waist_hip = wh;
run;

/*Construct dataset for MI*/
data test;
    if not eof then do;
	set &libname..&dsname._&nsub.
        (firstobs = 2 rename = (y               = y_post_c 
                                y_mcar          = y_post_mcar 
                                y_mar_wh        = y_post_mar_wh 
                                y_mar_wh_pre    = y_post_mar_wh_pre 
								y_mar_wh_pre_tx = y_post_mar_wh_pre_tx
                                y_mar_wptpt     = y_post_mar_wptpt
                                e_ij = e_ij_post)) end = eof;
	end;
	set &libname..&dsname._&nsub.
        (rename = (y_mcar = y_pre e_ij = e_ij_pre));
	by nreps subid;
	if last.subid then y_post = . ;
	if not first.subid then delete;
run;
data &libname..&dsname._&nsub._ancova;
    retain nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
    set test;
	keep nreps subid y_post_c y_post_mcar y_post_mar_wh y_post_mar_wh_pre y_post_mar_wh_pre_tx y_post_mar_wptpt y_pre treatment wh b_i e_ij_post e_ij_pre;
run;

/*Calculate the mean of y_pre (for the missing data senario MAR dependent on wh, y_pre, trt, and y_pre * trt)*/
/*
proc means data = &libname..&dsname._&nsub._ancova;
    var y_pre;
	title "Mean of y_pre for dataset &libname..&dsname._&nsub._ancova";
run;
*/
%mend;
















*Mixed model;
/*libname = library name*/
/*dsname = data set name*/
    /*dsname = sim20, sim30, sim40, or sim50*/
/*nsub = number of subject per group*/
    /*nsub = 35 or 100*/
/*mech = missing data mechanism*/
    /*mech =   , mcar, mar_wh, mar_wh_pre, mar_wh_pre_tx, or mar_wptpt*/
/*waist_hip = whether or not include waist hip in the analysis model*/
    /*waist_hip = wh or  */
/*cc = whether or not it is for complete case analysis*/
    /*cc = cc or  */

%macro mixed(libname = , dsname = , nsub = , mech = , waist_hip = , cc = );
proc sort data = &libname..&dsname._&nsub. out = sim_&nsub._mixed;
    by nreps subid post;
run;
%if &cc. = cc %then %do; /*Complete Cases*/
data &mech._&cc._&nsub._mixed;
    set sim_&nsub._mixed;
    if y_&mech. = . then getout = subid;
run;
data &mech._&cc._&nsub._mixed2;
    set &mech._&cc._&nsub._mixed;
    set &mech._&cc._&nsub._mixed (firstobs = 2 keep = getout rename = (getout = next_getout))
	    &mech._&cc._&nsub._mixed (     obs = 1 drop = _all_                                 );
	next_getout = ifn(last.subid, (.), next_getout );
run;
data &mech._&cc._&nsub._mixed;
    set &mech._&cc._&nsub._mixed2;
	if getout ne . or next_getout ne . then delete;
	drop getout next_getout;
run;
proc mixed data = &mech._&cc._&nsub._mixed noclprint noitprint;
    class subid;
    model y_&mech. = post &waist_hip. treatment treatment * post / s ddfm = kenwardroger;
	repeated / type = un subject = subid; *type changed to un 11/4/2015;
	by nreps;
	ods output SolutionF = &libname..&dsname._&nsub._&waist_hip.;
run;
%end;
%else %if &cc. =   %then %do; /*Available Cases*/
proc mixed data = sim_&nsub._mixed noclprint noitprint;
    class subid;
    model y_&mech. = post &waist_hip. treatment treatment * post / s ddfm = kenwardroger;
    repeated / type = un subject = subid; *type changed to un 11/4/2015;
	by nreps;
	ods output SolutionF = &libname..&dsname._&nsub._&waist_hip.;
run;
%end;
proc means data = &libname..&dsname._&nsub._&waist_hip. mean std;
    var estimate stderr tvalue;
	class effect;
	output out=sumstat;
run;
data &mech._&cc._&nsub._&waist_hip.;
    set sumstat;
	where _stat_ in ("MEAN" "STD") & effect ne " ";
	drop _type_ _freq_;
	condition = "&mech._&cc._&nsub._&waist_hip.";
run;
data &mech._&cc._&nsub._&waist_hip.;
    retain condition int_est int_se int_t post_est post_se post_t tx_est tx_se tx_t ptx_est ptx_est_sd ptx_se ptx_se_sd ptx_t wh_est wh_se wh_t;
    set &mech._&cc._&nsub._&waist_hip.;
	by condition;
	if effect = "Intercept" & _stat_ = "MEAN" then do;
	    int_est = estimate;
        int_se = stderr;
        int_t = tvalue;
	end;
	if effect = "post" & _stat_ = "MEAN" then do;
	    post_est = estimate;
        post_se = stderr;
        post_t = tvalue;
	end;
	if effect = "post*treatment" & _stat_ = "MEAN" then do;
	    ptx_est = estimate;
        ptx_se = stderr;
        ptx_t = tvalue;
	end;
	if effect = "post*treatment" & _stat_ = "STD" then do;
		ptx_est_sd = estimate;
        ptx_se_sd = stderr;
	end;
	if effect = "treatment" & _stat_ = "MEAN" then do;
	    tx_est = estimate;
        tx_se = stderr;
        tx_t = tvalue;
	end;

	if effect = "wh" & _stat_ = "MEAN" then do;
	    wh_est = estimate;
        wh_se = stderr;
        wh_t = tvalue;
	end; 
	if last.condition then output;
    keep condition int_est int_se int_t post_est post_se post_t tx_est tx_se tx_t ptx_est ptx_est_sd ptx_se ptx_se_sd ptx_t wh_est wh_se wh_t;
run;
%mend;



*ANCOVA;
/*libname = library name*/
/*dsname = data set name*/
    /*dsname = sim20, sim30, sim40, or sim50*/
/*nsub = number of subject per group*/
    /*nsub = 35 or 100*/
/*mech = missing data mechanism*/
    /*mech =  , mcar, mar_wh, mar_wh_pre, mar_wh_pre_tx, or mar_wptpt*/
/*waist_hip = whether or not include waist hip in the analysis model*/
    /*waist_hip = wh or  */
/*cc = whether or not it is for complete case analysis*/
    /*cc = cc or  */

%macro ancova(libname = , dsname = , nsub = , mech = , waist_hip = , cc = );
%if &cc. = cc  %then %do; /*Complete Cases*/
data &mech._&cc._&nsub._ancova;
    set &libname..&dsname._&nsub._ancova;
	if y_post_&mech. = . then delete;
run; 
proc reg data = &mech._&cc._&nsub._ancova outest = &mech._&cc._&nsub._ancova_&waist_hip. tableout noprint;
    model y_post_&mech. = y_pre &waist_hip. treatment;
	by nreps;
run;
quit;
data &libname..ancova_&nsub._&mech._&cc._&waist_hip.;
    set &mech._&cc._&nsub._ancova_&waist_hip.;
	where _type_ in ('PARMS' 'STDERR' 'T' 'PVALUE');
    keep nreps _type_ intercept y_pre &waist_hip. treatment;
	rename _type_ = type;
run;
proc means data = &libname..ancova_&nsub._&mech._&cc._&waist_hip. mean std;
    var intercept y_pre &waist_hip. treatment;
	class type;
	output out=sumstat;
run;
data sumstat;
    retain type intercept treatment &waist_hip. y_pre;
    set sumstat;
	where _stat_ in ("MEAN" "STD") & type in ('PARMS' 'STDERR' 'T');
	drop _freq_ _type_;
run;
proc transpose data = sumstat out = &mech._&cc._&nsub._&waist_hip.;
run;
data &mech._&cc._&nsub._&waist_hip.;
    set &mech._&cc._&nsub._&waist_hip.;
    condition = "&mech._&cc._&nsub._&waist_hip.";
	rename col1 = est_mn col2 = est_std col3 = se_mn col4 = se_std col5 = t_mn col6 = t_std;
	drop _label_;
run;
%end;
%else %if &cc. =   %then %do; /*Available Cases*/
proc mi data = &libname..&dsname._&nsub._ancova nimpute = 20 seed = 32435345 out = &libname..&mech._&nsub._mi;
    class treatment;
	monotone reg (y_post_&mech. = y_pre treatment wh y_pre * treatment 
                             y_pre * wh treatment * wh / details);
	var y_pre treatment wh y_post_&mech.;
	by nreps;
	/*ods output VarianceInfo = fmi;*/
run;
proc reg data = &libname..&mech._&nsub._mi outest = &libname..&mech._&nsub._&waist_hip._reg covout noprint;
    model y_post_&mech. = y_pre treatment &waist_hip.;
	by nreps _imputation_;
run;
quit;
proc mianalyze data = &libname..&mech._&nsub._&waist_hip._reg;
    modeleffects intercept y_pre treatment &waist_hip.;
	ods output ParameterEstimates = ancova_&nsub._&mech._&waist_hip. VarianceInfo = fmi;
	by nreps;
run;
data &libname..ancova_&nsub._&mech._&waist_hip.;
    set ancova_&nsub._&mech._&waist_hip.;
	keep nreps parm estimate stderr tvalue probt;
run;
proc means data = &libname..ancova_&nsub._&mech._&waist_hip. mean std;
    var estimate stderr tvalue;
	class parm;
	output out = sumstat;
run;
data &mech._&cc._&nsub._&waist_hip.;
    set sumstat;
	where _stat_ in ("MEAN" "STD") & parm ne " ";
	drop _type_ _freq_;
	condition = "&mech._&cc._&nsub._&waist_hip.";
run;
data fmi;
    set fmi;
	where parm = "treatment";
run;
proc means data = fmi;
    var fracmiss;
	output out = fmi&mech.&nsub.&waist_hip.;
run;
data fmi&mech.&nsub.&waist_hip.;
    length condition $ 21;
    set fmi&mech.&nsub.&waist_hip.;
	where _stat_ = "MEAN";
	drop _type_;
	condition = "&mech.&nsub.&waist_hip.";
run;
%end;
data &mech._&cc._&nsub._&waist_hip.;
    retain condition int_est int_se int_t pre_est pre_se pre_t tx_est tx_est_sd tx_se tx_se_sd tx_t wh_est wh_se wh_t;
    set &mech._&cc._&nsub._&waist_hip.;
	by condition;
	if _name_ = "intercept" then do;
	    int_est = est_mn;
        int_se = se_mn;
        int_t = t_mn;
	end;
	if _name_ = "y_pre" then do;
	    pre_est = est_mn;
        pre_se = se_mn;
        pre_t = t_mn;
	end;
	if _name_ = "treatment" then do;
	    tx_est = est_mn;
		tx_est_sd = est_std;
        tx_se = se_mn;
        tx_se_sd = se_std;
        tx_t = t_mn;        
	end;
	if _name_ = "wh" then do;
	    wh_est = est_mn;
        wh_se = se_mn;
        wh_t = t_mn;
	end; 
	if parm = "intercept" & _stat_ = "MEAN" then do;
	    int_est = estimate;
        int_se = stderr;
        int_t = tvalue;
	end;
	if parm = "y_pre" & _stat_ = "MEAN" then do;
	    pre_est = estimate;
        pre_se = stderr;
        pre_t = tvalue;
	end;
	if parm = "treatment" & _stat_ = "MEAN" then do;
	    tx_est = estimate;
        tx_se = stderr;
        tx_t = tvalue;
	end;
	if parm = "treatment" & _stat_ = "STD" then do;
	    tx_est_sd = estimate;
        tx_se_sd = stderr;
	end;
	if parm = "wh" & _stat_ = "MEAN" then do;
	    wh_est = estimate;
        wh_se = stderr;
        wh_t = tvalue;
	end; 
	if last.condition then output;
    keep condition int_est int_se int_t pre_est pre_se pre_t tx_est tx_est_sd tx_se tx_se_sd tx_t wh_est wh_se wh_t;
run;
%mend;




*Analysis Result;
/*method = analysis method*/
    /*method = mixed or ancova*/
/*mis = % of missingness*/
    /*mis = 20, 30, 40, or 50*/

%macro result(method = , mis = );
/*%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = ,              waist_hip = wh, cc =   );*/
/*%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = ,              waist_hip =   , cc =   );*/
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mcar,          waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mcar,          waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mcar,          waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mcar,          waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh,        waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh,        waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh,        waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh,        waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre,    waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre,    waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre,    waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre,    waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre_tx, waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre_tx, waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre_tx, waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wh_pre_tx, waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wptpt,     waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wptpt,     waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wptpt,     waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 35, mech = mar_wptpt,     waist_hip =   , cc =   );


/*%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = ,              waist_hip = wh, cc =   );*/
/*%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = ,              waist_hip =   , cc =   );*/
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mcar,          waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mcar,          waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mcar,          waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mcar,          waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh,        waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh,        waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh,        waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh,        waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre,    waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre,    waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre,    waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre,    waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre_tx, waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre_tx, waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre_tx, waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wh_pre_tx, waist_hip =   , cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wptpt,     waist_hip = wh, cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wptpt,     waist_hip = wh, cc =   );
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wptpt,     waist_hip =   , cc = cc);
%&method.(libname = sim, dsname = sim&mis., nsub = 100, mech = mar_wptpt,     waist_hip =   , cc =   );


data sim.&method.&mis.;
    set mcar_cc_35_wh   mcar__35_wh
        mcar_cc_35_     mcar__35_
        mcar_cc_100_wh  mcar__100_wh
        mcar_cc_100_    mcar__100_
        mar_wh_cc_35_wh   mar_wh__35_wh
        mar_wh_cc_35_     mar_wh__35_
        mar_wh_cc_100_wh  mar_wh__100_wh
        mar_wh_cc_100_    mar_wh__100_ 
        mar_wh_pre_cc_35_wh   mar_wh_pre__35_wh
        mar_wh_pre_cc_35_     mar_wh_pre__35_  
        mar_wh_pre_cc_100_wh  mar_wh_pre__100_wh
        mar_wh_pre_cc_100_    mar_wh_pre__100_
		mar_wh_pre_tx_cc_35_wh  mar_wh_pre_tx__35_wh
        mar_wh_pre_tx_cc_35_    mar_wh_pre_tx__35_
		mar_wh_pre_tx_cc_100_wh  mar_wh_pre_tx__100_wh
        mar_wh_pre_tx_cc_100_    mar_wh_pre_tx__100_
		mar_wptpt_cc_35_wh      mar_wptpt__35_wh
        mar_wptpt_cc_35_        mar_wptpt__35_
        mar_wptpt_cc_100_wh      mar_wptpt__100_wh
        mar_wptpt_cc_100_        mar_wptpt__100_;
run;

%if &method. = mixed %then %do;
ods rtf file = "U:\&method.&mis..rtf" bodytitle;
proc print data = sim.&method.&mis.;
    format int_est 7.2 int_se 7.2 int_t 7.2 post_est 7.2 post_se 7.2 post_t 7.2 tx_est 7.2 tx_se 7.2 tx_t 7.2 
           ptx_est 7.2 ptx_est_sd 7.2       ptx_se 7.2   ptx_se_sd 7.2          ptx_t 7.2 wh_est 7.2 wh_se 7.2 wh_t 7.2;
run;
ods rtf close;
%end;

%else %if &method. = ancova %then %do;
ods rtf file = "U:\&method.&mis..rtf" bodytitle;
proc print data = sim.&method.&mis.;
    format int_est 7.2 int_se 7.2 int_t 7.2 pre_est 7.2 pre_se 7.2 pre_t 7.2 
           tx_est 7.2  tx_est_sd 7.2        tx_se 7.2   tx_se_sd 7.2 tx_t 7.2 wh_est 7.2 wh_se 7.2 wh_t 7.2;
run;
ods rtf close;

/*fmi*/
data sim.fmi_mean_&mis.;
    set fmimcar35wh 
        fmimcar35
        fmimcar100wh
        fmimcar100
        fmimar_wh35wh
        fmimar_wh35
        fmimar_wh100wh
        fmimar_wh100 
        fmimar_wh_pre35wh
        fmimar_wh_pre35  
        fmimar_wh_pre100wh
        fmimar_wh_pre100
		fmimar_wh_pre_tx35wh
        fmimar_wh_pre_tx35
		fmimar_wh_pre_tx100wh
        fmimar_wh_pre_tx100
        fmimar_wptpt35wh
        fmimar_wptpt35
		fmimar_wptpt100wh
        fmimar_wptpt100;
run;

ods rtf file = "U:\fmi_mean_&mis..rtf" bodytitle;
proc print data = sim.fmi_mean_&mis.;
run;
ods rtf close;
%end;
%mend;
