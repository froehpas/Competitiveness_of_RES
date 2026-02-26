Sets
*      set of countries
hour             set of hours
year             set of years    /2015*2024/

fuel_conv
fuel_renew       set of renewable fuels

conv             set of conventional (non-renewable) generation technologies
renew            set of renewable generation technologies
stor             set of storage technologies

*############################## subsets

renew_disp(renew)        set of dispatchable renewable generation technologies
renew_ndisp(renew)       set of non-dispatchable renewable generation technologies
renew_curt(renew)        set of curtailable renewable generation technologies
renew_ncurt(renew)       set of non-curtailable renewable generation technologies

*############################### mapping
map_convfuel(conv,fuel_conv)             maps conv to fuel
map_renewfuel(renew,fuel_renew)          maps renew to fuel
;


Alias    (hour,hour2)


Variables
COST                                         Total costs = objective value
COST_GEN(year)                               Yearly generation costs
COST_INV(year)                               Yearly investment costs
CAP_CONV_RAMP(conv,year,hour)                Ramped capacity of conventional technologies
;

Positive Variables

GEN_CONV(conv,year,hour)                     Generation of conventional technologies
GEN_CONV_FULL(conv,year,hour)                Generation of conventional technologies at full capacity
GEN_CONV_MIN(conv,year,hour)                 Generation of conventional technologies at full minimum capacity
GEN_CONV_YEAR(conv,year)                     yearly Generation of conventional technologies
GEN_RENEW(renew,year,hour)                   Generation of renewable technologies
GEN_RENEW_YEAR(renew,year)                   yearly Generation of renewable technologies

CAP_CONV_RTO(conv,year,hour)                 Capacity ready-to-operate of conventional technologies
CAP_CONV_UP(conv,year,hour)                  Startup capacity of conventional technologies
CAP_CONV_DOWN(conv,year,hour)                Shutdown capacity of conventional technologies
CAP_CONV_INSTALL(conv,year)                  Installed capacity in year of conventional technology
CAP_STOR(stor,year)                          Capacity Storages
CAP_RENEW(renew,year)                        Capacity Renewables

CURT_RENEW(renew,year,hour)                  Renewable curtailment
SHED(year,hour)                              Load curtailment

LEVEL(stor,year,hour)                        Energy level of the storage
CHARGE(stor,year,hour)                       Charge the storage
DISCHARGE(stor,year,hour)                    Discharge the storage

;

$include DE_Data_input.gms

*execute_unload "check.gdx";
*$stop

;


Equations
EQ1_COST                                 Definition of COST
EQ2_COST_GEN                             Definition of COST_GEN
EQ3_COST_INV                             Definition of COST_INV
EQ5_MCC                                  Market clearing condition (Energy balance)
EQ6_CAP_CONV_RTO                         Definition of CAP_CONV_RTO
EQ7_CAP_CONV_RTO_up                      Upper bound for CAP_CONV_RTO
EQ8_GEN_CONV                             Definition of GEN_CONV
EQ9_GEN_CONV_up                          Upper bound for GEN_CONV
EQ10_GEN_CONV_MIN_lo                     Lower bound for GEN_CONV_MIN
EQ12_GEN_RENEW_up                        Upper bound for GEN_RENEW
EQ14_GEN_RENEW_reservoir_up              Upper bound for reservoir generation
EQ15_GEN_RENEW_reservoir_lo              Lower bound for reservoir generation
EQ16_GEN_RENEW_curt                      Definition of GEN_RENEW for curtailable technologies
EQ17_GEN_RENEW_ncurt                     Definition of GEN_RENEW for non-curtailable technologies
EQ18_Stor_Cap                            Definition of storage Capacity with duration
EQ19_LEVEL                               Definition of storage LEVEL
EQ20_LEVEL_start                         Definition of the start condition for LEVEL
EQ21_CHARGE_up                           Upper bound for CHARGE
EQ22_DISCHARGE_up                        Upper bound for DISCHARGE
;


*#######################################################################################################
*
*                                                       Model
*
*#######################################################################################################


*############################################# total costs #############################################

EQ1_COST..                          COST =E= sum(year, (COST_GEN(year) + COST_INV(year)))
;


*############################################# generation costs #############################################

EQ2_COST_GEN(year)..                COST_GEN(year) =E= 
                                                            sum((conv,hour),
                                                                cvar_conv_avg(conv,year) * GEN_CONV(conv,year,hour) 
                                                                + cramp_conv(conv,year) * (CAP_CONV_UP(conv,year,hour)
                                                                + CAP_CONV_DOWN(conv,year,hour)) * indicator_ramping)
                                                                
                                                            + sum((renew,hour),
                                                                cvar_renew(renew,year) * GEN_RENEW(renew,year,hour)
                                                                )                                            
                                                            + sum((renew_curt,hour),                             
                                                                ccurt_renew * CURT_RENEW(renew_curt,year,hour)
                                                                )                        
                                                            + sum((hour),
                                                                voll * SHED(year,hour)
                                                                )          
                                                                      
;


*############################################# investment costs #############################################

EQ3_COST_INV(year)..                COST_INV(year) =E=
                                                            sum(conv,
                                                                cinv_conv(conv,year) * CAP_CONV_INSTALL(conv,year)
                                                                )
                                                            +  sum(renew,
                                                                cinv_renew(renew,year) * CAP_RENEW(renew,year)
                                                                )                                 
                                                            +  sum(stor,
                                                                cinv_MW_stor(stor,year) * CAP_STOR(stor,year)
                                                                )
                                                            +  sum(stor,
                                                                cinv_MWh_stor(stor,year) * (CAP_STOR(stor,year) * duration_stor(stor,year))
                                                                )  
                                                            
;

*############################################# market clearing condition #############################################

EQ5_MCC(year,hour)..                sum(conv,
                                                GEN_CONV(conv,year,hour)
                                                )
                                            + sum(renew,
                                                GEN_RENEW(renew,year,hour)
                                                )
                                            + sum(stor,
                                                DISCHARGE(stor,year,hour) - CHARGE(stor,year,hour)
                                                )
                                                
                                                    =E=

                                            (load(year,hour) - SHED(year,hour))/ (1 - grid_loss)    
;


*############################################# Constraints for conventional (non-renewable) generation technologies #############################################


********************************************** Level of operational generation capacity **********************************************

EQ6_CAP_CONV_RTO(conv,year,hour)..      CAP_CONV_RTO(conv,year,hour) =E= CAP_CONV_RTO(conv,year,hour - 1)
                                                + ( CAP_CONV_UP(conv,year,hour) - CAP_CONV_DOWN(conv,year,hour) ) * indicator_ramping
                                                + CAP_CONV_RAMP(conv,year,hour) * ( 1 - indicator_ramping )
;


********************************************** Limits level of operational generation capacity to the availability **********************************************

EQ7_CAP_CONV_RTO_up(conv,year,hour)..   CAP_CONV_RTO(conv,year,hour) =L= availability_conv(conv,year,hour) * CAP_CONV_INSTALL(conv,year)
;


********************************************** Generation differentiated into operating at full and minimum load **********************************************

EQ8_GEN_CONV(conv,year,hour)..          GEN_CONV(conv,year,hour) =E= GEN_CONV_FULL(conv,year,hour) + GEN_CONV_MIN(conv,year,hour)
;


********************************************** Maximum level of opereational generation **********************************************

EQ9_GEN_CONV_up(conv,year,hour)..       GEN_CONV(conv,year,hour) =L= CAP_CONV_RTO(conv,year,hour)
;


********************************************** Minimum level of opereational generation **********************************************

EQ10_GEN_CONV_MIN_lo(conv,year,hour)..   GEN_CONV_MIN(conv,year,hour) =G= gmin_conv(conv) * ( CAP_CONV_RTO(conv,year,hour)
                                                * indicator_ramping - GEN_CONV_FULL(conv,year,hour) 
                                                )
;


*############################################# Constraints for dispatchable renewables #############################################


********************************************** Generation limited by availability **********************************************

EQ12_GEN_RENEW_up(renew_disp,year,hour)..    GEN_RENEW(renew_disp,year,hour) =L=
                                                    availability_renew(renew_disp,year,hour)* CAP_RENEW(renew_disp,year)                                                                                            
;


********************************************** Maximum level of generation for reservoir **********************************************

EQ14_GEN_RENEW_reservoir_up(year,hour)..     GEN_RENEW('reservoir',year,hour) =L= capfactor_renew_max('reservoir',year,hour)
                                                    * CAP_RENEW('reservoir',year)
;


********************************************** Minimum level of generation for reservoir **********************************************

EQ15_GEN_RENEW_reservoir_lo(year,hour)..     GEN_RENEW('reservoir',year,hour) =G= capfactor_renew_min('reservoir',year,hour)
                                                    * CAP_RENEW('reservoir',year)
;


*############################################# Constraints for non-dispatchable renewables #############################################


********************************************** Generation by curtailable technologies **********************************************

EQ16_GEN_RENEW_curt(renew_curt,year,hour)..      GEN_RENEW(renew_curt,year,hour) + CURT_RENEW(renew_curt,year,hour) =E=
                                                        capfactor_renew_max(renew_curt,year,hour) * CAP_RENEW(renew_curt,year)
;


********************************************** Generation by non-curtailable technologies **********************************************

EQ17_GEN_RENEW_ncurt(renew_ncurt,year,hour)..    GEN_RENEW(renew_ncurt,year,hour) =E= capfactor_renew_max(renew_ncurt,year,hour)
                                                        * CAP_RENEW(renew_ncurt,year)
;

*############################################# Constraints for storage technologies #############################################


********************************************** Storage capacity **********************************************

EQ18_Stor_Cap(stor,year,hour)..                  LEVEL(stor,year,hour) =l= CAP_STOR(stor,year) * duration_stor(stor,year)

;

********************************************** Storage level **********************************************

EQ19_LEVEL(stor,year,hour)$(ord(hour) gt 1)..

         LEVEL(stor,year,hour)

         =E=

         LEVEL(stor,year,hour - 1)

         +

         CHARGE(stor,year,hour) * efficiency_stor(stor)

         -

         DISCHARGE(stor,year,hour) * ( 1 / efficiency_stor(stor) )

;


********************************************** initial storage level **********************************************

EQ20_LEVEL_start(stor,year,hour)$( ord(hour) eq 1)..

         LEVEL(stor,year,hour)

         =E=
         
            0

;


********************************************** limited charging by the availability **********************************************

EQ21_CHARGE_up(stor,year,hour)..

         CHARGE(stor,year,hour)

         =L=

         avail_stor(stor) * CAP_STOR(stor,year)

;


********************************************** limited discharging by the availability **********************************************

EQ22_DISCHARGE_up(stor,year,hour)..

         DISCHARGE(stor,year,hour)

         =L=

         avail_stor(stor) * CAP_STOR(stor,year) * discharge_to_charge_ratio_stor(stor,year)

;


MODEL Investment
/
EQ1_COST
EQ2_COST_GEN
EQ3_COST_INV
EQ5_MCC
EQ6_CAP_CONV_RTO
EQ7_CAP_CONV_RTO_up
EQ8_GEN_CONV
EQ9_GEN_CONV_up
EQ10_GEN_CONV_MIN_lo
EQ12_GEN_RENEW_up
EQ14_GEN_RENEW_reservoir_up
EQ15_GEN_RENEW_reservoir_lo
EQ16_GEN_RENEW_curt
EQ17_GEN_RENEW_ncurt
EQ18_Stor_Cap
EQ19_LEVEL
EQ20_LEVEL_start
EQ21_CHARGE_up
EQ22_DISCHARGE_up
/;




*############################################# Capacity limits #############################################


********************************************** conventional capacities  **********************************************

*CAP_CONV_INSTALL.up('lignite',year) = 21160
*;

*CAP_CONV_INSTALL.up('nuclear',year) = 12068
*;

*CAP_CONV_INSTALL.up('hardcoal',year) = 26190
*;

*CAP_CONV_INSTALL.up('ocgt',year) = 7616
*;

*CAP_CONV_INSTALL.up('ccgt',year) = 24118
*;


********************************************** renewable capacity potentials  **********************************************

CAP_RENEW.up('windonshore1',year) = 68000
;

CAP_RENEW.up('windonshore2',year) = 87000
;

CAP_RENEW.up('windonshore3',year) = 10000
;

CAP_RENEW.up('windonshore4',year) = 9000
;

CAP_RENEW.up('solar1',year) = 247000
;

CAP_RENEW.up('solar2',year) = 332000
;

CAP_RENEW.up('solar3',year) = 170000
;

CAP_RENEW.up('solar4',year) = 102000
;

CAP_RENEW.fx('reservoir',year) = 1381
;

CAP_RENEW.fx('runofriver',year) = 3731
;

*CAP_RENEW.up('bioenergy',year) = 8577
*;

CAP_RENEW.up('waste',year) = 0
;

*CAP_RENEW.up('geothermal',year) = 54
*;

CAP_RENEW.up('marine',year) = 0
;

CAP_RENEW.up('othergas',year) = 0
;

********************************************** storage capacities  **********************************************

CAP_STOR.fx('pumpstorage',year) = 9449
;

Investment.optfile = 1;

option lp = cplex;

Solve Investment using LP minimizing COST
;

execute_unload "Check_model_test.gdx"
;


Parameter
*report(*,*,*,*)
report_capacity(year,*)
report_renew_total(year)
report_conv_total(year)
report_stor_total(year)
report_total_disp(year)
report_total_windonshore(year)
report_total_windoffshore(year)
report_total_solar(year)

report_generation(year,hour,*)
report_level(year,hour,*)
report_hourly_windonshore(year,hour)
report_hourly_solar(year,hour)
report_yearly_gen(year,*)
report_yearly_disp(year)
report_yearly_windonshore(year)
report_yearly_windoffshore(year)
report_yearly_solar(year)
report_load(year,hour)
report_resload(year,hour)

report_hourly_prices(year,hour) 
report_avg_prices(year)


;

*############################################# output declerations #############################################


********************************************** capacity report  **********************************************

report_capacity(year,renew) = CAP_RENEW.l(renew,year)
;

report_capacity(year,conv) = CAP_CONV_INSTALL.l(conv,year)
;

report_capacity(year,stor) = CAP_STOR.l(stor,year)
;

report_renew_total(year) = sum(renew,
                                    CAP_RENEW.l(renew,year)
                                )
;

report_conv_total(year) = sum(conv,
                                CAP_CONV_INSTALL.l(conv,year)
                                )
;

report_stor_total(year) = sum(stor,
                                CAP_STOR.l(stor,year)
                                )
;

report_total_disp(year) = (report_conv_total(year) + CAP_RENEW.l('bioenergy',year) + CAP_RENEW.l('runofriver',year) + CAP_RENEW.l('reservoir',year) + CAP_RENEW.l('waste',year) + CAP_RENEW.l('geothermal',year) + CAP_RENEW.l('othergas',year))/1000 
;

report_total_windonshore(year) =   (CAP_RENEW.l('windonshore1',year)
                                            + CAP_RENEW.l('windonshore2',year)
                                            + CAP_RENEW.l('windonshore3',year)
                                            + CAP_RENEW.l('windonshore4',year))/1000
;

report_total_windoffshore(year)= (CAP_RENEW.l('windoffshore',year))/1000
;

report_total_solar(year) =  (CAP_RENEW.l('solar1',year)
                                            + CAP_RENEW.l('solar2',year)
                                            + CAP_RENEW.l('solar3',year)
                                            + CAP_RENEW.l('solar4',year))/1000
;

********************************************** generation report  **********************************************

report_generation(year,hour,conv) = GEN_CONV.l(conv,year,hour)
;

report_generation(year,hour,renew) = GEN_RENEW.l(renew,year,hour)
;

report_generation(year,hour,stor) = CHARGE.l(stor,year,hour) - DISCHARGE.l(stor,year,hour)
;

report_hourly_windonshore(year,hour) = GEN_RENEW.l('windonshore1',year,hour)
                                        + GEN_RENEW.l('windonshore2',year,hour)
                                        + GEN_RENEW.l('windonshore3',year,hour)
                                        + GEN_RENEW.l('windonshore4',year,hour)
;

report_hourly_solar(year,hour) = GEN_RENEW.l('solar1',year,hour)
                                         + GEN_RENEW.l('solar2',year,hour)
                                         + GEN_RENEW.l('solar3',year,hour)
                                         + GEN_RENEW.l('solar4',year,hour)
;

report_yearly_gen(year,conv) = sum(hour,
                                        GEN_CONV.l(conv,year,hour)
                                    )                                       
;

report_yearly_gen(year,renew) = sum(hour,
                                        GEN_RENEW.l(renew,year,hour)
                                    )                                       
;

report_yearly_gen(year,stor) = sum(hour,
                                       CHARGE.l(stor,year,hour) - DISCHARGE.l(stor,year,hour)
                                    )                                      
;

report_yearly_disp(year) = (sum(conv, report_yearly_gen(year,conv))  + sum(hour, GEN_RENEW.l('bioenergy',year,hour)) + sum(hour, GEN_RENEW.l('runofriver',year,hour)) + sum(hour, GEN_RENEW.l('reservoir',year,hour)) + sum(hour, GEN_RENEW.l('geothermal',year,hour)) + sum(hour, GEN_RENEW.l('waste',year,hour)) + sum(hour, GEN_RENEW.l('othergas',year,hour)))/1000000 
;

report_yearly_windonshore(year) = (sum(hour,
                                    report_hourly_windonshore(year,hour)
                                ))/1000000
;

report_yearly_windoffshore(year) = (sum(hour,
                                    GEN_RENEW.l('windoffshore',year,hour)
                                ))/1000000
;

report_yearly_solar(year) = (sum(hour,
                                    report_hourly_solar(year,hour)
                                ))/1000000
;

report_level(year,hour,stor) = LEVEL.l(stor,year,hour) + eps
;

report_load(year,hour) = load(year,hour)
;

report_resload(year,hour) = load(year,hour) - sum(renew,
                                                        GEN_RENEW.l(renew,year,hour)
                                                  )
;

********************************************** prices report  **********************************************
                                             
report_avg_prices(year) = sum(hour,
                                EQ5_MCC.m(year,hour))/card(hour)
;

report_hourly_prices(year,hour)  =  EQ5_MCC.m(year,hour)
;


EXECUTE_UNLOAD 'Output.gdx'
report_capacity,
report_renew_total,
report_conv_total,
report_total_disp,
report_stor_total,
report_total_windonshore,
report_total_windoffshore,
report_total_solar,

report_generation,
report_level,
report_hourly_windonshore,
report_hourly_solar,
report_yearly_gen,
report_yearly_disp,
report_yearly_windonshore,
report_yearly_windoffshore,
report_yearly_solar,
report_load,
report_resload,

report_avg_prices,
report_hourly_prices
;


$onecho >out.tmp

         par=report_capacity            rng=CAP!A1    rdim=2 cdim=0
         par=report_renew_total         rng=CAP!F1    rdim=1 cdim=0
         par=report_conv_total          rng=CAP!J1    rdim=1 cdim=0
         par=report_stor_total          rng=VSCAP!Q1  rdim=1 cdim=0
         par=report_total_disp          rng=VSCAP!A1  rdim=1 cdim=0
         par=report_total_windonshore   rng=VSCAP!I1  rdim=1 cdim=0
         par=report_total_windoffshore  rng=VSCAP!M1  rdim=1 cdim=0
         par=report_total_solar         rng=VSCAP!E1  rdim=1 cdim=0
         
         par=report_generation          rng=GENH!A1   rdim=2 cdim=1
         par=report_hourly_windonshore  rng=GENW!A1   rdim=2 cdim=0
         par=report_hourly_solar        rng=GENS!A1   rdim=2 cdim=0
         par=report_yearly_gen          rng=VSGEN!Q1  rdim=2 cdim=0
         par=report_yearly_disp         rng=VSGEN!A1  rdim=1 cdim=0
         par=report_yearly_windonshore  rng=VSGEN!I1  rdim=1 cdim=0
         par=report_yearly_windoffshore rng=VSGEN!M1  rdim=1 cdim=0
         par=report_yearly_solar        rng=VSGEN!E1  rdim=1 cdim=0
         
         par=report_level               rng=LVL!A1    rdim=2 cdim=1
         par=report_load                rng=RES!A1    rdim=2 cdim=0
         par=report_resload             rng=RES!F1    rdim=2 cdim=0
         
         par=report_avg_prices          rng=VSPRICE!A1  rdim=1 cdim=0
         par=report_hourly_prices       rng=PRICE!P1    rdim=2 cdim=0         
         
         
         
$offecho

EXECUTE 'gdxxrw Output.gdx o=RESULTS.xlsx  @out.tmp'
;

$stop

