import math
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit


# before recycler tune
dir_name = 'ctags_scan1/'
filename_idx = np.array([1, 2,  3, 4,5, 6,   7, 8 ])
clock_diffs =  np.array([0,12,-12,-6,6,18, -18, 0 ])

# after recycler tune
#dir_name = 'ctags_scan2/'
#filename_idx = np.array([1, 2,  3, 4,5, 6,   7, 8, 9,  10, 11 ])
#clock_diffs =  np.array([0,12,-12,-6,6,18, -18, 0, 24, 30, 36 ])

# cross-check
#dir_name = 'ctags_scan3/'
#filename_idx = np.array([1, 2,  3,   4,  5, 6 ])
#clock_diffs =  np.array([0, 9, 18, -18, -9, 0 ])

# kicker 2
#dir_name = 'ctags_scan4/'
#filename_idx = np.array([1, 2,  3,   4,  5, 7 ])
#clock_diffs =  np.array([0, 6, 12, -12, -6, 0 ])

# 05/22/2021 scan
dir_name = 'ctags_scan5/'
filename_idx = np.array([1,   2,  4,  5,  6,  7,  8 ])
clock_diffs =  np.array([0, -15, 15, 20, 25, 10, 35 ])

# 05/22/2021 scan, validation
#dir_name = 'ctags_scan6/'
#filename_idx = np.array([1,  2,   3, 4,  5, 6  ])
#clock_diffs =  np.array([0, -6, -12, 6, 12, 0  ])

def func(x, N, offset, a):
    return N + a * (x-offset)**2


csv_files = [dir_name + '/ctag_%03d.csv' % i for i in filename_idx]
dfs = [pd.concat([pd.read_csv(csv_files[n]),pd.DataFrame(np.ones([17])*clock_diffs[n], columns=['delay'])], axis=1) for n in range(len(filename_idx))]
data = pd.concat(dfs)  



plt.figure(figsize=[6.4*1.5, 4.8*1.5])
offset_new_ctag_norm = []
ctag_all  = data[data['pulse']=='all']['muonTag'].values
t0_all    = data[data['pulse']=='all']['t0Integrals'].values
delay_all = data[data['pulse']=='all']['delay'].values
for bunch in range(16):
    plt.subplot(4,4,1+bunch)

    ctag  = data[data['pulse']==str(bunch)]['muonTag'].values
    t0    = data[data['pulse']==str(bunch)]['t0Integrals'].values
    delay = data[data['pulse']==str(bunch)]['delay'].values

    plt.errorbar(delay_all,ctag_all/t0_all, yerr=np.sqrt(ctag_all)/t0_all, fmt='x', color='gray', alpha=0.2)
    plt.errorbar(delay,ctag/t0, yerr=np.sqrt(ctag)/t0, fmt='x')
    
    #fit
    popt, pcov = curve_fit(func, delay, ctag/t0, sigma=np.sqrt(ctag)/t0)
    tt = np.arange(delay.min()-0.5, delay.max()+0.6,0.1)
    plt.plot(tt, func(tt, *popt),'--')
    offset_new_ctag_norm.append(popt)

    if bunch%4 != 4:
        plt.setp(plt.gca().get_yticklabels(), visible=False)
    if bunch < 12:
        plt.setp(plt.gca().get_xticklabels(), visible=False)
    else:
        plt.xlabel("c.t. [2ns]")
    plt.ylim([0.0015,0.0023])
    plt.text(0.5, 0.9, "offset: %.1f c.t." % (popt[1]), horizontalalignment='center', verticalalignment='center', transform=plt.gca().transAxes)
    if bunch%4 == 0:
        plt.ylabel("ctags/T0")
    #if bunch in [1]:
    #    plt.title("kicker timing scan")
    #plt.gca().axes.get_yaxis().set_visible(False)
plt.tight_layout()
plt.subplots_adjust(hspace=0.0, wspace=0.0)
plt.savefig("plots/kickerTimingScanCtagOverT0.png")
plt.show()


plt.figure(figsize=[6.4*1.5, 4.8*1.5])
offset_new_ctag = []
n_all    = data[data['pulse']=='all']['nshots'].values
for bunch in range(16):
    plt.subplot(4,4,1+bunch)

    ctag  = data[data['pulse']==str(bunch)]['muonTag'].values
    n  =   data[data['pulse']==str(bunch)]['nshots'].values
    delay = data[data['pulse']==str(bunch)]['delay'].values


    plt.errorbar(delay_all,ctag_all/n_all, yerr=np.sqrt(ctag_all)/n_all, fmt='x', color='gray', alpha=0.2)
    plt.errorbar(delay,ctag/n, yerr=np.sqrt(ctag)/n, fmt='x')
    
    #fit
    popt, pcov = curve_fit(func, delay, ctag/n, sigma=np.sqrt(ctag)/n)
    tt = np.arange(delay.min()-0.5, delay.max()+0.6,0.1)
    plt.plot(tt, func(tt, *popt),'--')
    offset_new_ctag.append(popt)

    plt.text(0.5, 0.9, "offset: %.1f c.t." % (popt[1]), horizontalalignment='center', verticalalignment='center', transform=plt.gca().transAxes)
    if bunch%4 != 0:
        plt.setp(plt.gca().get_yticklabels(), visible=False)
    else:
        plt.yticks([400, 450,500,550,600],["","450","500","550",""])
    if bunch < 12:
        plt.setp(plt.gca().get_xticklabels(), visible=False)
    else:
        plt.xlabel("c.t. [2ns]")
    if bunch%4 == 0: 
        plt.ylabel("ctags")
    plt.ylim([400,600])
    
    #if bunch in [1]:
    #    plt.title("kicker timing scan")
    #plt.gca().axes.get_yaxis().set_visible(False)
plt.tight_layout()
plt.subplots_adjust(hspace=0.0, wspace=0.0)
plt.savefig("plots/kickerTimingScanCtag.png")
plt.show()

for bunch in range(16):
    print('bunch %d, correction: %d(%d) clock ticks' % (bunch+1, round(offset_new_ctag_norm[bunch][1]), round(offset_new_ctag[bunch][1])))
#    #print('python delay_triggers.py 1-3 %d,%d %d triggers_scan_work.csv; ' % (bunch, bunch + 8, round(offset_new[bunch - 1]) ))
#    print('./delayKickers.sh  %d %d,%d triggers_scan_work.csv; ' % (round(offset_new[bunch - 1]), bunch, bunch + 8 ))

#fit_f = r.TF1('pol2', 'pol2', -20, 20)
#
#offset_new = []
#
#for bunch in range(1, 17):
#    ctag_gr = r.TGraphErrors( len(csv_files) )
#
#    for offset in range(len(csv_files)):
#        csv_df = pd.read_csv(csv_files[offset])
#        ctag = csv_df.at[bunch, 'muonTag']
#        t0 = csv_df.at[bunch, 't0Integrals']
#
#        ctag_gr.SetPoint(offset, clock_diffs[offset], ctag / t0)
#        ctag_gr.SetPointError(offset, 0, math.sqrt(ctag) / t0)
#
#    ctag_gr.Fit(fit_f, 'R')
#    offset_new.append(fit_f.GetMaximumX())
#
#    c = r.TCanvas('c', 'c')
#    ctag_gr.SetTitle('CTAG / T0 for bunch %d' % bunch)
#    ctag_gr.GetXaxis().SetTitle('clock ticks; 1ct = 2ns')
#    ctag_gr.Draw("AP")
#
#    c.SaveAs(dir_name + '/ctag_bunch_%02d.pdf' % bunch)
#
#
#for bunch in range(1, 9):
#    print('bunch %d, correction: %d clock ticks' % (bunch, round(offset_new[bunch - 1])))
#
if True:
  for bunch in range(16):
  #    #print('python delay_triggers.py 1-3 %d,%d %d triggers_scan_work.csv; ' % (bunch, bunch + 8, round(offset_new[bunch - 1]) ))
      print('python delay_triggers_python3.py 1-3 %d %d kicker-timings-plot_opt.csv' % ((bunch+1, round(offset_new_ctag_norm[bunch][1]))))
trg_id = 41#None
if trg_id:
  for bunch in range(16):
      print('update gm2trigger_analog_a6_2019 set delay=delay+%d where id=%i and channel <=3 AND pulse_index=1 AND sequence=%d returning delay;' % (round(offset_new_ctag_norm[bunch][1]), trg_id, bunch+1))
