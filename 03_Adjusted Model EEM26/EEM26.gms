Sets
country          set of countries
hour             set of hours
year             set of years    /2030/

fuel_conv        set of conventional fuels
fuel_renew       set of renewable fuels

conv             set of conventional (non-renewable) generation technologies
renew            set of renewable generation technologies
stor             set of storage technologies

*############################## subsets

renew_disp(renew)        set of dispatchable renewable generation technologies
renew_ndisp(renew)       set of non-dispatchable renewable generation technologies

*############################### mapping
map_convfuel(conv,fuel_conv)             maps conv to fuel
map_renewfuel(renew,fuel_renew)          maps renew to fuel
;


Alias    (country,country2)


Variables
COST                                         Total costs = objective value
COST_GEN(year)                               Yearly generation costs
COST_INV(year)                               Yearly investment costs
CAP_CONV_RAMP(country,conv,year,hour)        Ramped capacity of conventional technologies
;

Positive Variables

GEN_CONV(country,conv,year,hour)                     Generation of conventional technologies
GEN_CONV_FULL(country,conv,year,hour)                Generation of conventional technologies at full capacity
GEN_CONV_MIN(country,conv,year,hour)                 Generation of conventional technologies at full minimum capacity
GEN_RENEW(country,renew,year,hour)                   Generation of renewable technologies

CAP_CONV_RTO(country,conv,year,hour)                 Capacity ready-to-operate of conventional technologies
CAP_CONV_UP(country,conv,year,hour)                  Startup capacity of conventional technologies
CAP_CONV_DOWN(country,conv,year,hour)                Shutdown capacity of conventional technologies

CAP_CONV(country,conv,year)                      Capacity COnventionals   
CAP_STOR(country,stor,year)                      Capacity Storages
CAP_RENEW(country,renew,year)                    Capacity Renewables

CURT_RENEW(country,renew,year,hour)                  Renewable curtailment
SHED_LOAD(country,year,hour)                         Load shedding

LEVEL(country,stor,year,hour)                        Energy level of the storage
CHARGE(country,stor,year,hour)                       Charge the storage
DISCHARGE(country,stor,year,hour)                    Discharge the storage
FLOW(country,country2,year,hour)                     Flow between nodes of subcounties
;

$include Data_input.gms

execute_unload "check.gdx";
*$stop


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
EQ12_GEN_RENEW_up                        Upper bound for GEN_RENEW for dispatchable technologies
EQ14_GEN_RENEW_reservoir_up              Upper bound for reservoir generation
EQ15_GEN_RENEW_reservoir_lo              Lower bound for reservoir generation
EQ16_GEN_RENEW_ndisp                     Definition of GEN_RENEW for non-dispatchable technologies
*EQ17_GEN_RENEW_ncurt                     Definition of GEN_RENEW for non-curtailable technologies
EQ18_Stor_Cap                            Definition of storage Capacity with duration
EQ19_LEVEL                               Definition of storage LEVEL
EQ20_LEVEL_start                         Definition of the start condition for LEVEL
EQ21_LEVEL_end                           Definition of the end condition for LEVEL
EQ22_LINEFLOW_IMP                        Import flow via NTC
EQ23_LINEFLOW_EXP                        Export flow via NTC
EQ24_CHARGE_up                           Upper bound for CHARGE
EQ25_DISCHARGE_up                        Upper bound for DISCHARGE
EQ26_NATIONAL_TARGET
EQ27_EU_TARGET
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
                                                                cvar_conv_full(conv,year) * GEN_CONV_FULL(country,conv,year,hour)
                                                                + cvar_conv_min(conv,year) * GEN_CONV_MIN(country,conv,year,hour)
                                                                + cramp_conv(conv,year) * (CAP_CONV_UP(country,conv,year,hour)
                                                                + CAP_CONV_DOWN(country,conv,year,hour)))
                                                                
                                                            + sum((renew,hour),
                                                                cvar_renew(renew,year) * GEN_RENEW(country,renew,year,hour)
                                                                )                                            
                                                            + sum((renew_ndisp,hour),                             
                                                                ccurt_renew * CURT_RENEW(country,renew_ndisp,year,hour)
                                                                )                        
                                                            + sum((hour),
                                                                voll * SHED_LOAD(country,year,hour)
                                                                )
                                                            + sum((country2,hour),
                                                                cimport * FLOW(country2,country,year,hour)
                                                                )
                                                                )
                                                                      
;


*############################################# investment costs #############################################

EQ3_COST_INV(year)..                COST_INV(year) =E=
                                                        sum(country,
                                                            sum(conv,
                                                                cinv_conv(conv,year) * CAP_CONV(country,conv,year)
                                                                )
                                                            +  sum(renew,
                                                                cinv_renew(renew,year) * CAP_RENEW(country,renew,year)
                                                                )                                 
                                                            +  sum(stor,
                                                                cinv_MW_stor(stor,year) * CAP_STOR(country,stor,year)
                                                                )
                                                            +  sum(stor,
                                                                cinv_MWh_stor(stor,year) * (CAP_STOR(country,stor,year) * duration(stor,year))
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
                                                (1-(grid_loss/2)) * FLOW(country2,country,year,hour)
                                                )
                                            - sum(country2,
                                                (1-(grid_loss/2)) * FLOW(country,country2,year,hour)
                                                )
                                                
                                                    =E=

                                            load(country,year,hour) - SHED_LOAD(country,year,hour)  
;


*############################################# Constraints for conventional (non-renewable) generation technologies #############################################


********************************************** Level of operational generation capacity **********************************************

EQ6_CAP_CONV_RTO(country,conv,year,hour)..      CAP_CONV_RTO(country,conv,year,hour) =E= CAP_CONV_RTO(country,conv,year,hour - 1)
                                                + ( CAP_CONV_UP(country,conv,year,hour) - CAP_CONV_DOWN(country,conv,year,hour) )
                                                
;


********************************************** Limits level of operational generation capacity to the availability **********************************************

EQ7_CAP_CONV_RTO_up(country,conv,year,hour)..   CAP_CONV_RTO(country,conv,year,hour) =L= availability_conv(conv,year,hour) * CAP_CONV(country,conv,year)
;


********************************************** Generation differentiated into operating at full and minimum load **********************************************

EQ8_GEN_CONV(country,conv,year,hour)..          GEN_CONV(country,conv,year,hour) =E= GEN_CONV_FULL(country,conv,year,hour) + GEN_CONV_MIN(country,conv,year,hour)
;


********************************************** Maximum level of opereational generation **********************************************

EQ9_GEN_CONV_up(country,conv,year,hour)..       GEN_CONV(country,conv,year,hour) =L= CAP_CONV_RTO(country,conv,year,hour)
;


********************************************** Minimum level of opereational generation **********************************************

EQ10_GEN_CONV_MIN_lo(country,conv,year,hour)..   GEN_CONV_MIN(country,conv,year,hour) =G= gmin_conv(conv) * ( CAP_CONV_RTO(country,conv,year,hour)
                                                 - GEN_CONV_FULL(country,conv,year,hour) 
                                                )
;


*############################################# Constraints for dispatchable renewables #############################################


********************************************** Generation limited by availability **********************************************

EQ12_GEN_RENEW_up(country,renew_disp,year,hour)..    GEN_RENEW(country,renew_disp,year,hour) =L=
                                                    availability_renew(renew_disp,year,hour) * CAP_RENEW(country,renew_disp,year)                                                                                            
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

EQ16_GEN_RENEW_ndisp(country,renew_ndisp,year,hour)..      GEN_RENEW(country,renew_ndisp,year,hour) + CURT_RENEW(country,renew_ndisp,year,hour) =E=
                                                           capfactor_renew_max(country,renew_ndisp,year,hour) * CAP_RENEW(country,renew_ndisp,year)
;

********************************************** Generation by non-curtailable technologies **********************************************

*EQ17_GEN_RENEW_ncurt(country,renew_ncurt,year,hour)..    GEN_RENEW(country,renew_ncurt,year,hour) =E= capfactor_renew_max(country,renew_ncurt,year,hour)
*                                                        * CAP_RENEW(country,renew_ncurt,year)
*;


*############################################# Constraints for storage technologies #############################################


********************************************** Storage capacity **********************************************

EQ18_Stor_Cap(country,stor,year,hour)..                  LEVEL(country,stor,year,hour) =l=  avail_stor(stor) * CAP_STOR(country,stor,year) * duration(stor,year)

;

********************************************** Storage level **********************************************

EQ19_LEVEL(country,stor,year,hour)$(ord(hour) gt 1)..

         LEVEL(country,stor,year,hour)

         =E=

         LEVEL(country,stor,year,hour - 1)

         +

         CHARGE(country,stor,year,hour) * efficiency_stor(stor)

         -

         DISCHARGE(country,stor,year,hour)

;


********************************************** initial storage level **********************************************

EQ20_LEVEL_start(country,stor,year,hour)$( ord(hour) eq 1)..

         LEVEL(country,stor,year,hour)

         =E=
*starting level =0
*            0
         CAP_STOR(country,stor,year) * avail_stor(stor) * 0.3 * duration(stor,year) 

         + CHARGE(country,stor,year,hour) * efficiency_stor(stor)
       
         - DISCHARGE(country,stor,year,hour)

;


********************************************** final storage level **********************************************

EQ21_LEVEL_end(country,stor,year,hour)$( ord(hour) eq 8760)..

         LEVEL(country,stor,year,hour)

         =E=

         CAP_STOR(country,stor,year) * avail_stor(stor) * 0.3 * duration(stor,year)

;


********************************************** final storage level **********************************************

EQ22_LINEFLOW_IMP(country,country2,year,hour)..

         FLOW(country,country2,year,hour)

         =L=

         ntc(country2,country)

;


********************************************** final storage level **********************************************

EQ23_LINEFLOW_EXP(country2,country,year,hour)..

         FLOW(country2,country,year,hour)

         =L=

         ntc(country,country2)

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

         avail_stor(stor) * CAP_STOR(country,stor,year) * discharge_to_charge_ratio(stor,year)

;

*############################################# Constraints for country and EU RES share targets #############################################

EQ26_NATIONAL_TARGET(country,year)$(scenario eq 1)..
        sum((renew,hour), GEN_RENEW(country,renew,year,hour)) =E= national_target(country)
;


EQ27_EU_TARGET(year)$(scenario eq 2)..
        sum((country,renew,hour), GEN_RENEW(country,renew,year,hour)) =E= eu_target
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
EQ16_GEN_RENEW_ndisp
*EQ17_GEN_RENEW_ncurt
EQ18_Stor_Cap
EQ19_LEVEL
EQ20_LEVEL_start
EQ21_LEVEL_end
EQ22_LINEFLOW_IMP
EQ23_LINEFLOW_EXP
EQ24_CHARGE_up
EQ25_DISCHARGE_up
EQ26_NATIONAL_TARGET
EQ27_EU_TARGET
/;

CAP_RENEW.fx(country,'reservoir',year) = cap_hydro('reservoir',country)
;

CAP_RENEW.fx(country,'runofriver',year) = cap_hydro('runofriver',country)
;

CAP_STOR.fx(country,'pumpstorage',year) = cap_pumpstor('pumpstorage',country)
;

CAP_CONV.fx(country,'nuclear',year) = cap_conv_install('nuclear',country)
;

*Investment.optfile = 1;

option lp = gurobi;

Solve Investment using LP minimizing COST
;

execute_unload "Check_model_test.gdx"
;

*$stop

Parameter
*report(*,*,*,*)
report_capacity(country,year,*)

report_generation(year,hour,*,country)
report_yearly_gen(year,*,country)
report_level(year,hour,*,country)

report_avg_prices(year,country)
report_hourly_prices(year,hour,country) 

report_trade_imp(year,hour,country2,country)
report_trade_exp(year,hour,country,country2)

report_RES_share(year,country)
report_Emissions(year,country)
;

*############################################# output declerations #############################################

********************************************** capacity report  **********************************************

report_capacity(country,year,conv) = CAP_CONV.l(country,conv,year)/1000
;

report_capacity(country,year,renew) = CAP_RENEW.l(country,renew,year)/1000 
;

report_capacity(country,year,stor) = CAP_STOR.l(country,stor,year)/1000
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

report_level(year,hour,stor,country) = LEVEL.l(country,stor,year,hour) + eps
;

********************************************** prices **********************************************
                                       
report_avg_prices(year,country) = sum(hour,
                                EQ5_MCC.m(country,year,hour))/card(hour)
;

report_hourly_prices(year,hour,country)  =  EQ5_MCC.m(country,year,hour)
;

********************************************** export & import **********************************************

report_trade_imp(year,hour,country2,country)= FLOW.l(country,country2,year,hour) + eps
;

report_trade_exp(year,hour,country,country2)= FLOW.l(country2,country,year,hour) + eps
;

********************************************** RES share **********************************************

report_RES_share(year,country) = sum((renew,hour), GEN_RENEW.l(country,renew,year,hour)) /
                                   (sum((renew,hour), GEN_RENEW.l(country,renew,year,hour))  + sum((conv,hour), GEN_CONV.l(country,conv,year,hour)) + eps) 
;

report_Emissions(year,country) = sum((conv,fuel_conv,hour)$(map_convfuel(conv,fuel_conv)), carboncontent_conv(fuel_conv) * GEN_CONV.l(country,conv,year,hour))
                                + sum((renew,fuel_renew,hour)$(map_renewfuel(renew,fuel_renew)), carboncontent_renew(fuel_renew) * GEN_RENEW.l(country,renew,year,hour))
;

EXECUTE_UNLOAD 'Output.gdx'
report_capacity,
*report_capacity_add,

report_generation,
report_yearly_gen,
report_level,

report_avg_prices,
report_hourly_prices,

report_trade_imp,
report_trade_exp

report_RES_share
report_Emissions
;


$onecho >out.tmp

         par=report_capacity            rng=CAP!A1          rdim=2 cdim=1
         
         par=report_generation          rng=GENH!A1         rdim=2 cdim=2
         par=report_yearly_gen          rng=GENY!A1         rdim=2 cdim=1
         par=report_level               rng=LVL!A1          rdim=2 cdim=2

         par=report_avg_prices          rng=PRICEY!A1       rdim=1 cdim=1
         par=report_hourly_prices       rng=PRICEH!A1       rdim=2 cdim=1         
         
         par=report_trade_imp           rng=IMPORT!A1       rdim=2 cdim=2
         par=report_trade_exp           rng=EXPORT!A1       rdim=2 cdim=2
         
         par=report_RES_share           rng=SHARE!A1        rdim=1 cdim=1
         par=report_Emissions           rng=EMISSIONS!A1    rdim=1 cdim=1
         
         
$offecho

EXECUTE 'gdxxrw Output.gdx o=RESULTS.xlsx  @out.tmp'
;

$stop

