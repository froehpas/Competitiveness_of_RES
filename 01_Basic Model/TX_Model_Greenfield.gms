Sets
country          set of countries
hour             set of hours
year             set of years    /2024/

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


Alias    (hour,hour2),(country,country2)


Variables
COST                                         Total costs = objective value
COST_GEN(year)                               Yearly generation costs
COST_INV(year)                               Yearly investment costs
CAP_CONV_RAMP(country,conv,year,hour)                Ramped capacity of conventional technologies
;

Positive Variables

GEN_CONV(country,conv,year,hour)                     Generation of conventional technologies
GEN_CONV_FULL(country,conv,year,hour)                Generation of conventional technologies at full capacity
GEN_CONV_MIN(country,conv,year,hour)                 Generation of conventional technologies at full minimum capacity
GEN_CONV_YEAR(country,conv,year)                     yearly Generation of conventional technologies
GEN_RENEW(country,renew,year,hour)                   Generation of renewable technologies
GEN_RENEW_YEAR(country,renew,year)                   yearly Generation of renewable technologies

CAP_CONV_RTO(country,conv,year,hour)                 Capacity ready-to-operate of conventional technologies
CAP_CONV_UP(country,conv,year,hour)                  Startup capacity of conventional technologies
CAP_CONV_DOWN(country,conv,year,hour)                Shutdown capacity of conventional technologies
CAP_CONV_INSTALL(country,conv,year)                  Installed capacity in year of conventional technology
CAP_STOR(country,stor,year)                          Capacity Storages
CAP_RENEW(country,renew,year)                        Capacity Renewables

CURT_RENEW(country,renew,year,hour)                  Renewable curtailment
SHED(country,year,hour)                         Load curtailment

LEVEL(country,stor,year,hour)                        Energy level of the storage
CHARGE(country,stor,year,hour)                       Charge the storage
DISCHARGE(country,stor,year,hour)                    Discharge the storage
FLOW(country,country2,year,hour)                     Flow between nodes of subcounties
;

$include TX_Data_input.gms

execute_unload "check1.gdx";
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
EQ21_LEVEL_end                           Definition of the end condition for LEVEL
EQ22_LINEFLOW_IMP                        
EQ23_LINEFLOW_EXP                            
EQ24_CHARGE_up                           Upper bound for CHARGE
EQ25_DISCHARGE_up                        Upper bound for DISCHARGE
EQ27_GEN_CONV_YEAR                       Yearly generation conv
EQ28_GEN_RENEW_YEAR                      yearly generation renew

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
                                                        sum(country,
                                                            sum((conv,hour),
                                                                cvar_conv_avg(conv,year) * GEN_CONV(country,conv,year,hour) 
                                                                + cramp_conv(conv,year) * (CAP_CONV_UP(country,conv,year,hour)
                                                                + CAP_CONV_DOWN(country,conv,year,hour)) * indicator_ramping)
                                                                
                                                            + sum((renew,hour),
                                                                cvar_renew(renew,year) * GEN_RENEW(country,renew,year,hour)
                                                                )                                            
                                                            + sum((renew_curt,hour),                             
                                                                ccurt_renew * CURT_RENEW(country,renew_curt,year,hour)
                                                                )                        
                                                            + sum((hour),
                                                                voll * SHED(country,year,hour)
                                                                )
                                                                )
                                                                      
;


*############################################# investment costs #############################################

EQ3_COST_INV(year)..                COST_INV(year) =E=
                                                        sum(country,
                                                            sum(conv,
                                                                cinv_conv(conv,year) * CAP_CONV_INSTALL(country,conv,year)
                                                                )
                                                            +  sum(renew,
                                                                cinv_renew(renew,year) * CAP_RENEW(country,renew,year)
                                                                )                                 
                                                            +  sum(stor,
                                                                cinv_MW_stor(stor,year) * CAP_STOR(country,stor,year)
                                                                )
                                                            +  sum(stor,
                                                                cinv_MWh_stor(stor,year) * (CAP_STOR(country,stor,year) * duration_stor(stor,year))
                                                                )
                                                                )
                                                            
;

*############################################# market clearing condition #############################################

EQ5_MCC(country,year,hour)..                sum(conv,
                                                GEN_CONV(country,conv,year,hour)
                                                )
                                            + sum(renew,
                                                GEN_RENEW(country,renew,year,hour)
                                                )
                                            + sum(stor,
                                                DISCHARGE(country,stor,year,hour) - CHARGE(country,stor,year,hour)
                                                )
                                            + sum(country2,
                                                (1-(grid_loss/2)) * FLOW(country,country2,year,hour)
                                                )
                                            -sum(country2,
                                                (1-(grid_loss/2)) * FLOW(country2,country,year,hour)
                                                )
                                                
                                                    =E=

                                            load(country,year,hour) - CURT_LOAD(country,year,hour)    
;


*############################################# Constraints for conventional (non-renewable) generation technologies #############################################


********************************************** Level of operational generation capacity **********************************************

EQ6_CAP_CONV_RTO(country,conv,year,hour)..      CAP_CONV_RTO(country,conv,year,hour) =E= CAP_CONV_RTO(country,conv,year,hour - 1)
                                                + ( CAP_CONV_UP(country,conv,year,hour) - CAP_CONV_DOWN(country,conv,year,hour) ) * indicator_ramping
                                                + CAP_CONV_RAMP(country,conv,year,hour) * ( 1 - indicator_ramping )
;


********************************************** Limits level of operational generation capacity to the availability **********************************************

EQ7_CAP_CONV_RTO_up(country,conv,year,hour)..   CAP_CONV_RTO(country,conv,year,hour) =L= availability_conv(conv,year,hour) * CAP_CONV_INSTALL(country,conv,year)
;


********************************************** Generation differentiated into operating at full and minimum load **********************************************

EQ8_GEN_CONV(country,conv,year,hour)..          GEN_CONV(country,conv,year,hour) =E= GEN_CONV_FULL(country,conv,year,hour) + GEN_CONV_MIN(country,conv,year,hour)
;


********************************************** Maximum level of opereational generation **********************************************

EQ9_GEN_CONV_up(country,conv,year,hour)..       GEN_CONV(country,conv,year,hour) =L= CAP_CONV_RTO(country,conv,year,hour)
;


********************************************** Minimum level of opereational generation **********************************************

EQ10_GEN_CONV_MIN_lo(country,conv,year,hour)..   GEN_CONV_MIN(country,conv,year,hour) =G= gmin_conv(conv) * ( CAP_CONV_RTO(country,conv,year,hour)
                                                * indicator_ramping - GEN_CONV_FULL(country,conv,year,hour) 
                                                )
;


*############################################# Constraints for dispatchable renewables #############################################


********************************************** Generation limited by availability **********************************************

EQ12_GEN_RENEW_up(country,renew_disp,year,hour)..    GEN_RENEW(country,renew_disp,year,hour) =L=
                                                    availability_renew(renew_disp,year,hour)* CAP_RENEW(country,renew_disp,year)                                                                                            
;


********************************************** Maximum level of generation for reservoir **********************************************

EQ14_GEN_RENEW_reservoir_up(country,year,hour)..     GEN_RENEW(country,'reservoir',year,hour) =L= capfactor_renew_max(country,'reservoir',year,hour)
                                                    * CAP_RENEW(country,'reservoir',year)
;


********************************************** Minimum level of generation for reservoir **********************************************

EQ15_GEN_RENEW_reservoir_lo(country,year,hour)..     GEN_RENEW(country,'reservoir',year,hour) =G= capfactor_renew_min(country,'reservoir',year,hour)
                                                    * CAP_RENEW(country,'reservoir',year)
;


*############################################# Constraints for non-dispatchable renewables #############################################


********************************************** Generation by curtailable technologies **********************************************

EQ16_GEN_RENEW_curt(country,renew_curt,year,hour)..      GEN_RENEW(country,renew_curt,year,hour) + CURT_RENEW(country,renew_curt,year,hour) =E=
                                                        capfactor_renew_max(country,renew_curt,year,hour) * CAP_RENEW(country,renew_curt,year)
;


********************************************** Generation by non-curtailable technologies **********************************************

EQ17_GEN_RENEW_ncurt(country,renew_ncurt,year,hour)..    GEN_RENEW(country,renew_ncurt,year,hour) =E= capfactor_renew_max(country,renew_ncurt,year,hour)
                                                        * CAP_RENEW(country,renew_ncurt,year)
;


*############################################# Constraints for storage technologies #############################################


********************************************** Storage capacity **********************************************

EQ18_Stor_Cap(country,stor,year,hour)..                  LEVEL(country,stor,year,hour) =l= CAP_STOR(country,stor,year) * duration_stor(stor,year)

;

********************************************** Storage level **********************************************

EQ19_LEVEL(country,stor,year,hour)$(ord(hour) gt 1)..

         LEVEL(country,stor,year,hour)

         =E=

         LEVEL(country,stor,year,hour - 1)

         +

         CHARGE(country,stor,year,hour) * efficiency_stor(stor)

         -

         DISCHARGE(country,stor,year,hour) * ( 1 / efficiency_stor(stor) )

;


********************************************** initial storage level **********************************************

EQ20_LEVEL_start(country,stor,year,hour)$( ord(hour) eq 1)..

         LEVEL(country,stor,year,hour)

         =E=
*starting level =0
            0

*         + CHARGE(stor,year,hour) * efficiency_stor(stor)

         

*         - DISCHARGE(stor,year,hour) * ( 1 / efficiency_stor(stor) )

;


********************************************** final storage level **********************************************

EQ21_LEVEL_end(country,stor,year,hour)$( ord(hour) eq 8760)..

         LEVEL(country,stor,year,hour)

         =E=

        0

;


********************************************** final storage level **********************************************

EQ22_LINEFLOW_IMP(country,country2,year,hour)..

         FLOW(country,country2,year,hour)

         =L=

         ntc(country,country2)

;


********************************************** final storage level **********************************************

EQ23_LINEFLOW_EXP(country2,country,year,hour)..

         FLOW(country2,country,year,hour)

         =L=

         ntc(country2,country)

;


********************************************** limited charging by the availability **********************************************

EQ24_CHARGE_up(country,stor,year,hour)..

         CHARGE(country,stor,year,hour)

         =L=

         avail_stor(stor) * CAP_STOR(country,stor,year)

;


********************************************** limited discharging by the availability **********************************************

EQ25_DISCHARGE_up(country,stor,year,hour)..

         DISCHARGE(country,stor,year,hour)

         =L=

         avail_stor(stor) * CAP_STOR(country,stor,year) * discharge_to_charge_ratio_stor(stor,year)

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
*EQ21_LEVEL_end
EQ22_LINEFLOW_IMP
EQ23_LINEFLOW_EXP
EQ24_CHARGE_up
EQ25_DISCHARGE_up
/;


$ontext

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

$offtext
********************************************** renewable capacities  **********************************************

**wind onshore

CAP_RENEW.up('NOR','windonshore',year) = 57500
;
CAP_RENEW.up('FAW','windonshore',year) = 71000
;
CAP_RENEW.up('WES','windonshore',year) = 38250
;
CAP_RENEW.up('NCE','windonshore',year) = 57500
;
CAP_RENEW.up('SOC','windonshore',year) = 38250
;
CAP_RENEW.up('COA','windonshore',year) = 38250
;
CAP_RENEW.up('SOU','windonshore',year) = 38250
;


**solar

CAP_RENEW.up('NOR','solar',year) = 149000
;
CAP_RENEW.up('FAW','solar',year) = 481000
;
CAP_RENEW.up('WES','solar',year) = 149000
;
CAP_RENEW.up('NCE','solar',year) = 273500
;
CAP_RENEW.up('SOC','solar',year) = 166000
;
CAP_RENEW.up('COA','solar',year) = 166000
;
CAP_RENEW.up('SOU','solar',year) = 273500
;



**hydro

CAP_RENEW.fx('WES','reservoir',year) = 184
;
CAP_RENEW.fx('SOC','reservoir',year) = 554
;
CAP_RENEW.fx('NOR','reservoir',year) = 0
;
CAP_RENEW.fx('FAW','reservoir',year) = 0
;
CAP_RENEW.fx('NCE','reservoir',year) = 0
;
CAP_RENEW.fx('COA','reservoir',year) = 0
;
CAP_RENEW.fx('SOU','reservoir',year) = 0
;


*$offText

CAP_RENEW.fx(country,'runofriver',year) = 0
;

**other

CAP_RENEW.up(country,'waste',year) = 0
;

CAP_RENEW.up(country,'marine',year) = 0
;

CAP_RENEW.up(country,'othergas',year) = 0
;

********************************************** storage capacities  **********************************************

CAP_STOR.fx(country,'pumpstorage',year) = 0
;

*$offtext
Investment.optfile = 1;

option lp = cplex;

Solve Investment using LP minimizing COST
;

execute_unload "Check_model_test.gdx"
;

*$stop

Parameter
*report(*,*,*,*)
report_capacity(country,year,*)
report_renew_total(country,year)
report_conv_total(country,year)
report_stor_total(country,year)
*report_total_disp(year)
report_total_windonshore(year)
report_total_windoffshore(year)
report_total_solar(year)

report_generation(year,hour,*,country)
report_yearly_gen(year,*,country)
report_level(year,hour,*,country)
*report_yearly_disp(year)

report_hourly_prices(year,hour,country) 
report_avg_prices(year,country)

report_trade(year,hour,country,country2)
;

*############################################# output declerations #############################################


********************************************** capacity report  **********************************************

report_capacity(country,year,renew) = CAP_RENEW.l(country,renew,year)/1000
;

report_capacity(country,year,conv) = CAP_CONV_INSTALL.l(country,conv,year)/1000
;

report_capacity(country,year,stor) = CAP_STOR.l(country,stor,year)/1000
;

report_renew_total(country,year) = sum(renew,
                                    CAP_RENEW.l(country,renew,year)
                                )/1000
;

report_conv_total(country,year) = sum(conv,
                                CAP_CONV_INSTALL.l(country,conv,year)
                                )/1000
;

report_stor_total(country,year) = sum(stor,
                                CAP_STOR.l(country,stor,year)
                                )/1000
;

*report_total_disp(year) = (report_conv_total(country,year) + CAP_RENEW.l(country,'bioenergy',year) + CAP_RENEW.l(country,'runofriver',year) + CAP_RENEW.l(country,'reservoir',year) + CAP_RENEW.l(country,'waste',year) + CAP_RENEW.l(country,'geothermal',year) + CAP_RENEW.l(country,'othergas',year))/1000 
*;

report_total_windonshore(year) =   sum(country,CAP_RENEW.l(country,'windonshore',year))/1000
;

report_total_windoffshore(year)= sum(country,CAP_RENEW.l(country,'windoffshore',year))/1000
;

report_total_solar(year) =  sum(country,CAP_RENEW.l(country,'solar',year))/1000
;

********************************************** generation report  **********************************************

report_generation(year,hour,conv,country) = GEN_CONV.l(country,conv,year,hour)
;

report_generation(year,hour,renew,country) = GEN_RENEW.l(country,renew,year,hour)
;

report_generation(year,hour,stor,country) = CHARGE.l(country,stor,year,hour) - DISCHARGE.l(country,stor,year,hour)
;

report_yearly_gen(year,conv,country) = sum(hour,
                                        GEN_CONV.l(country,conv,year,hour)
                                    )/1000000                                       
;

report_yearly_gen(year,renew,country) = sum(hour,
                                        GEN_RENEW.l(country,renew,year,hour)
                                    )/1000000                                       
;

report_yearly_gen(year,stor,country) = sum(hour,
                                       CHARGE.l(country,stor,year,hour) - DISCHARGE.l(country,stor,year,hour)
                                    )/1000000                                      
;

*report_yearly_disp(year) = (sum(conv, report_yearly_gen(year,conv))  + sum(hour, GEN_RENEW.l('bioenergy',year,hour)) + sum(hour, GEN_RENEW.l('runofriver',year,hour)) + sum(hour, GEN_RENEW.l('reservoir',year,hour)) + sum(hour, GEN_RENEW.l('geothermal',year,hour)) + sum(hour, GEN_RENEW.l('waste',year,hour)) + sum(hour, GEN_RENEW.l('othergas',year,hour)))/1000000 
*;

report_level(year,hour,stor,country) = LEVEL.l(country,stor,year,hour) + eps
;


********************************************** prices report  **********************************************
                                       
report_avg_prices(year,country) = sum(hour,
                                EQ5_MCC.m(country,year,hour))/card(hour)
;

report_hourly_prices(year,hour,country)  =  EQ5_MCC.m(country,year,hour)
;

report_trade(year,hour,country,country2)= FLOW.l(country,country2,year,hour) +eps
;

EXECUTE_UNLOAD 'Output.gdx'
report_capacity,
report_renew_total,
report_conv_total,
report_stor_total,
report_total_windonshore,
report_total_windoffshore,
report_total_solar,

report_generation,
report_level,
report_yearly_gen,

report_avg_prices,
report_hourly_prices,
report_trade
;


$onecho >out.tmp

         par=report_capacity            rng=CAP!A1          rdim=2 cdim=1
         par=report_renew_total         rng=CAP_RENEW!A1    rdim=1 cdim=1
         par=report_conv_total          rng=CAP_CONV!A1     rdim=1 cdim=1
         par=report_stor_total          rng=CAP_STOR!A1     rdim=1 cdim=1 
         par=report_total_windonshore   rng=CAP_WINDON!A1   rdim=1 cdim=0
         par=report_total_windoffshore  rng=CAP_WINDOFF!A1  rdim=1 cdim=0
         par=report_total_solar         rng=CAP_PV!A1       rdim=1 cdim=0
         
         par=report_generation          rng=GENH!A1         rdim=2 cdim=2
         par=report_yearly_gen          rng=GENY!A1         rdim=2 cdim=1
         par=report_level               rng=LVL!A1          rdim=2 cdim=2

         par=report_avg_prices          rng=PRICEY!A1       rdim=1 cdim=1
         par=report_hourly_prices       rng=PRICEH!A1       rdim=2 cdim=1         
         
         par=report_trade               rng=TRADE!A1        rdim=2 cdim=2
         
         
$offecho

EXECUTE 'gdxxrw Output.gdx o=OPEN.xlsx  @out.tmp'
;

$stop

