### ABCr Sampling routine for crater age distribution properties; Mazrouei et al. 2018.
###
###

import numpy as np
from astropy.io import ascii
from scipy.stats import anderson_ksamp

def f_lt_thresh(gamma, b, xmax, thresh):
	if b >= thresh:
		return gamma * b/xmax
	else: 
		return gamma * b/xmax + (1.0 - gamma) * (thresh-b)/xmax


def bootstrap_abcr(x, xmax, x_earth, N=100000):
	### piecewise-constant
	big_sample_size_target = 10000
	all_params, all_D = [],[]

	big_sample_size = 1.0 * big_sample_size_target
	break_loc  = np.random.uniform(min(x), xmax)
	gamma = np.sin(np.random.uniform(0, np.pi/2.0))**2

	### Given arcsin prior on break location, gamma is for case where intervals are symmetric; modify by weighting to intervals.
	N_left_1 =  gamma * break_loc/xmax 
	N_right_1 = (1.0 - gamma) * (xmax-break_loc)/xmax 
	N_650_1 = f_lt_thresh(gamma, break_loc, xmax, 650.0)

	N_samp_left, N_samp_right, N_samp_650 = (np.sum(x <= break_loc) + np.sum(x_earth <= break_loc), 
											 np.sum(x >  break_loc) + np.sum(x_earth >  break_loc), x_earth.size + np.sum(x <= 650) )

	N_needed = 10.0 * np.array([ N_samp_left / N_left_1, N_samp_right / N_right_1, N_samp_650 / N_650_1])

	big_sample_size = int( round( N_needed.max() ) )

	N_left = int(round( gamma * big_sample_size * break_loc/xmax ))
	N_right = int(round((1.0 - gamma) * big_sample_size * (xmax-break_loc)/xmax ))

	if big_sample_size > 1E5:
		sample_uniform = np.random.uniform(0, xmax, x.shape[0])
		sample_uniform_earth = np.random.uniform(0, 650.0, x_earth.size)

		D2 = anderson_ksamp([x, sample_uniform])[0] + anderson_ksamp([x_earth, sample_uniform_earth])[0]
		return break_loc, gamma, 999.0, D2, 1

	### draw synthetic Lunar crater sample.
	sample_left  = np.random.uniform( 0, break_loc, N_left)
	sample_right = np.random.uniform( break_loc, xmax, N_right )
	full_sample = np.append( sample_left, sample_right )

	sample = np.random.choice( full_sample, x.shape[0], replace=False)
	sample_uniform = np.random.uniform(0, xmax, x.shape[0])
	
	### draw synthetic Earth crater sample.
	sample_left2  = np.random.uniform( 0, break_loc, N_left)
	sample_right2 = np.random.uniform( break_loc, xmax, N_right )
	full_sample2 = np.append( sample_left2, sample_right2 )

	ok_earth = full_sample2[full_sample2 <= 650.0]
	sample_earth = np.random.choice( ok_earth, x_earth.size, replace=False)
	sample_uniform_earth = np.random.uniform(0, 650.0, x_earth.size)

	### Measure distance metrics between synthetic and real samples.
	D = anderson_ksamp([x, sample])[0] + anderson_ksamp([x_earth, sample_earth])[0]
	D2 = anderson_ksamp([x, sample_uniform])[0] + anderson_ksamp([x_earth, sample_uniform_earth])[0]

	return break_loc, gamma, D, D2, 0 #1-p


if __name__ == "__main__":

	### Read Lunar crater data. 
	d_big = ascii.read('RockyCraters_lg10_forBill.csv')

	DIAM_big = np.array(d_big['Diam'])
	ok = np.where( DIAM_big >= 10000.0 ) ### 10 km crater size limit
	RA95_big = np.array(d_big['RA95'])[ok]
	AGES_big = np.array(d_big['Age'])[ok]

	### read Earth crater data.
	d_Earth = ascii.read('terrestrial_650under_052617.csv')
	AGES_Earth = np.array(d_Earth['Age'])

	### Read crater age regression parameter PDF
	d_reg = ascii.read('crater_regression_parameter_pdf.csv')
	ok = np.where( d_reg['lnprob'] > np.percentile(d_reg['lnprob'], 0.1) )
	sample_regress_params = np.array([d_reg['a'][ok], d_reg['b'][ok]]).T

	### Set up arrays to store results from ABCr run
	all_param, all_D, all_D2, all_slope, all_intercept, all_gamma, all_max = [],[],[],[],[],[],[]

	### Set up ABCr run parameters
	min_ra95 = 0.010903895 ### lowest RA95 to consider in big dataset.
	ok_big = np.where( RA95_big >= min_ra95 )
	fail_count = 0
	N_trials = 10000000

	### Perform ABCr trials.
	for i in range(0, N_trials):

		### select an index from the regression PDF sample 
		ind_sample = np.random.randint(0, sample_regress_params.shape[0])
		regress_params = sample_regress_params[ind_sample]

		ages_big = (RA95_big[ok_big]/regress_params[0])**(1.0/regress_params[1])
		max_age  = (min_ra95/regress_params[0])**(1.0/regress_params[1])

		break_age, gamma, D, D2, fc = bootstrap_abcr(ages_big, max_age, AGES_Earth)

		### record outcome of trial
		all_max.append(max_age)
		all_param.append(break_age)
		all_gamma.append(gamma)
		all_D.append(D)
		all_D2.append(D2)
		all_slope.append(regress_params[0])
		all_intercept.append(regress_params[1])

		fail_count += fc
		if i%10000 == 0:
			print('%d out of %d trials complete'%(i, N_trials))


	all_D = np.array(all_D)
	all_D2 = np.array(all_D2)

	ok = np.where(all_D <= np.percentile(all_D, 0.01))
	FILE = open('ABCr_crater_rate_JOINT_MARGINALIZED_OVER_UNCERTAINTY.csv', 'w')
	FILE.write('### Threshold D: %s\n'%(np.percentile(all_D, 0.01)))
	FILE.write('### Number of uniform cases with D<D_thresh: %s\n'%(np.sum(all_D2 <= np.percentile(all_D, 0.01))))
	FILE.write('### Number of broken cases with D<D_thresh: %s\n'%(np.sum(all_D <= np.percentile(all_D, 0.01))))
	FILE.write('### Total number of broken cases: %s\n'%(all_D.shape[0]))
	FILE.write('D_break,a,b,break,gamma\n')
	for i in ok[0]:
		FILE.write('%s,%s,%s,%s,%s\n'%(all_D[i], all_slope[i], all_intercept[i], all_param[i], all_gamma[i]))
	FILE.close()

	print('Complete with %d trial failures out of %d'%(fail_count, N_trials))
	print('Results written in ./ABCr_crater_rate_JOINT_MARGINALIZED_OVER_UNCERTAINTY.csv')

