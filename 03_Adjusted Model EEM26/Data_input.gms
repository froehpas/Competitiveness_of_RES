$eolcom #
Scalars
ccurt_renew                              /110/
voll                                     /10000/
grid_loss                                /0.01/
cimport                                  /10/
interest_rate                            /0.07/
scenario                                 /2/        # National = 1 , European = 2
;

Parameters



*############################################# Input parameter #############################################

********************************************** hourly capacity factors **********************************************

capfactor_reservoir_max(year,hour,country)           hourly maximum capacity factor for reservoir feed-in (MWh per MW)
capfactor_reservoir_min(year,hour,country)           hourly minimum capacity factor for reservoir feed-in (MWh per MW)
capfactor_runofriver(year,hour,country)              hourly capacity factor for windoffshore feed-in (MWh per MW)
capfactor_solar(year,hour,country)                   hourly capacity factor for solar1 feed-in (MWh per MW)
capfactor_windonshore(year,hour,country)             hourly capacity factor for windonshore1 feed-in (MWh per MW)
capfactor_windoffshore(year,hour,country)            hourly capacity factor for windoffshore feed-in (MWh per MW)
capfactor_biomass(year,hour,country)

********************************************** hourly load  **********************************************

demand(year,hour,country)                              considered demand (MWh per h)
load(country,year,hour)

********************************************** conv parameters **********************************************

carbonprice_year(year)                                    yearly co2 price (EUR per tonne)
inputdata_conv(conv,*)                                    excel input table for conv
fuelprice_conv_year(year,fuel_conv)                       yearly fuel price (EUR per MWh_th)
carboncontent_conv(fuel_conv)                             emission factor (tCO2 per MWh_th)
covernight_conv(conv,year)
cvarom_conv(conv,year)
cinv_conv(conv,year)
cap_conv_install(conv,country)


********************************************** renew parameters **********************************************

inputdata_renew(renew,*)                                   excel input table for renew
covernight_renew(renew,year)                               overnight investment cost (EUR per kW)
cvarom_renew(renew,year)                                   yearly varom costs for renew (EUR per MWh)
fuelprice_renew_year(year,fuel_renew)                      fuel price (EUR per MWh_th)
carboncontent_renew(fuel_renew)                            emission factor (tCO2 per MWh_th)

national_target_emissions(country)                                   national emission target
eu_target_emissions                                                  European emission target

national_target_RES(country)                                   national RES generation target on demand
eu_target_RES                                                  European RES generation target on demand                                   

********************************************** storage parameters **********************************************

inputdata_stor(stor,*)                                      excel input table for stor
covernight_kW_stor(stor,year)                               overnight investment cost for storage turbine (EUR per kW)
covernight_kWh_stor(stor,year)                              overnight investment cost for storage (EUR per kWh)
duration(stor,year)                                         storage duration (hours)
discharge_to_charge_ratio(stor,year)                        discharge (turbine) to charge (pump) ratio (-)

********************************************** hydro capacities **********************************************

cap_hydro(renew,country)
cap_pumpstor(stor,country)

********************************************** ntc **********************************************

ntc(country,country2)                                       net transfer capacity between countries (MW)

*############################################# Calcluated parameter #############################################

********************************************** conv parameters **********************************************

cramp_conv(conv,year)                                     ramping cost (EUR per MW)
cvar_conv_full(conv,year)                                 variable generation cost at full capacity (EUR per MWh)
cvar_conv_min(conv,year)                                  variable generation cost at min capacity (EUR per MWh)
gmin_conv(conv)                                           minimum generation level
availability_conv(conv,year,hour)                         country-specific availability factor (%)
            
********************************************** renew parameters **********************************************

availability_renew(renew,year,hour)                        availability of dispatchable renewables
capfactor_renew_max(country,renew,year,hour)               maximum capacity factor for renewables
capfactor_renew_min(country,renew,year,hour)               minimum capacity factor for renewables
cinv_renew(renew,year)                                     annual investment cost (EUR per MW and year)
cvar_renew(renew,year)                                     variable generation cost (EUR per MWh)
efficiency_renew(renew)                                    efficiency (%)

********************************************** storage parameters **********************************************

avail_stor(stor)                                          average yearly availability
cinv_MW_stor(stor,year)                                   annual investment cost for storage turbine (EUR per MW and year)
cinv_MWh_stor(stor,year)                                  annual investment cost for storage (EUR per MWh and year)
efficiency_stor(stor)                                     efficiency (%)
duration_stor(stor,year)                                  duration to charge the storage (h)
discharge_to_charge_ratio_stor(stor,year)                 discharge (turbine) to charge (pump) ratio (-)

*############################################# input Excel table #############################################

*nochmal alle inputs überprüfuen und ob der Verweis rng in der Mappe sowie Zeilen und Spalten stimmt!

********************************************** hourly data **********************************************

$onecho > Input1.txt
set=country                      rng=demand!D2:AX2               rdim=0  cdim=1
set=hour                         rng=hour!B6:B8789               rdim=1  cdim=0
par=demand                       rng=demand!B2:AX8786            rdim=2  cdim=1
par=capfactor_reservoir_max      rng=reservoir_max!B2:AX8786     rdim=2  cdim=1
par=capfactor_reservoir_min      rng=reservoir_min!B2:AX8786     rdim=2  cdim=1
par=capfactor_solar              rng=solar!B2:AX8786             rdim=2  cdim=1
par=capfactor_windonshore        rng=windonshore!B2:AX8786       rdim=2  cdim=1
par=capfactor_windoffshore       rng=windoffshore!B2:AX8786      rdim=2  cdim=1
par=capfactor_runofriver         rng=runofriver!B2:AX8786        rdim=2  cdim=1
par=capfactor_biomass            rng=biomass!B2:AX8786           rdim=2  cdim=1

$offecho
$onUNDF
$call  gdxxrw Input_hourly.xlsx @Input1.txt
$gdxIn Input_hourly.gdx
$load  country,hour,capfactor_reservoir_max,capfactor_reservoir_min,demand
$load  capfactor_windonshore,capfactor_solar
$load  capfactor_windoffshore,capfactor_runofriver,capfactor_biomass
$GDXin
$offUndf

;
execute_unload "check_hourly.gdx";
*$stop

** renew ohne geothermal und biogas porbiert!
********************************************** yearly data **********************************************

$onecho > Input2.txt
set=fuel_conv                            rng=fuel_conv!C4:G4                     rdim=0  cdim=1
set=fuel_renew                           rng=fuel_renew!B4:F4                    rdim=0  cdim=1
set=conv                                 rng=tech_conv!B4:B9                     rdim=1  cdim=0
set=renew                                rng=tech_renew!B4:B10                   rdim=1  cdim=0
set=stor                                 rng=tech_stor!B4:B6                     rdim=1  cdim=0
set=map_convfuel                         rng=tech_conv!M4:N9                     rdim=2  cdim=0
set=map_renewfuel                        rng=tech_renew!M4:N10                   rdim=2  cdim=0
par=carbonprice_year                     rng=co2!C5:D6                           rdim=1  cdim=0
par=inputdata_conv                       rng=tech_conv!B4:I10                    rdim=1  cdim=1
par=carboncontent_conv                   rng=fuel_conv!B21:C25                   rdim=1  cdim=0
par=fuelprice_conv_year                  rng=fuel_conv!C4:H5                     rdim=1  cdim=1
par=covernight_conv                      rng=tech_conv!B13:C19                   rdim=1  cdim=1
par=cvarom_conv                          rng=tech_conv!B21:C27                   rdim=1  cdim=1
par=inputdata_renew                      rng=tech_renew!B4:G12                   rdim=1  cdim=1
par=covernight_renew                     rng=tech_renew!B23:C31                  rdim=1  cdim=1
par=cvarom_renew                         rng=tech_renew!B41:C49                  rdim=1  cdim=1
par=fuelprice_renew_year                 rng=fuel_renew!B4:H5                    rdim=1  cdim=1
par=carboncontent_renew                  rng=fuel_renew!B16:C18                  rdim=1  cdim=0
par=inputdata_stor                       rng=tech_stor!B4:E6                     rdim=1  cdim=1
par=covernight_kW_stor                   rng=tech_stor!B9:C11                    rdim=1  cdim=1
par=covernight_kWh_stor                  rng=tech_stor!B14:C16                   rdim=1  cdim=1
par=duration                             rng=tech_stor!B19:C21                   rdim=1  cdim=1
par=discharge_to_charge_ratio            rng=tech_stor!B24:C26                   rdim=1  cdim=1
par=ntc                                  rng=ntc!B2:AW49                         rdim=1  cdim=1
par=cap_hydro                            rng=cap_hydro!B2:AW4                    rdim=1  cdim=1
par=cap_pumpstor                         rng=cap_pumpstor!B2:AW3                 rdim=1  cdim=1
par=cap_conv_install                     rng=cap_conv!B2:AW3                     rdim=1  cdim=1
par=national_target_emissions            rng=targets!L4:M50                      rdim=1  cdim=0
par=eu_target_emissions                  rng=targets!P4                          rdim=0  cdim=0
par=national_target_RES                  rng=targets!R4:S50                      rdim=1  cdim=0
par=eu_target_RES                        rng=targets!V4                          rdim=0  cdim=0


$offecho
$onUNDF
$call  gdxxrw Input_yearly.xlsx @Input2.txt
$gdxIn Input_yearly.gdx
$load  fuel_conv,fuel_renew,conv,renew,stor,map_convfuel,map_renewfuel,cvarom_renew 
$load  carbonprice_year,inputdata_conv,covernight_conv,cvarom_conv
$load  carboncontent_conv,fuelprice_conv_year
$load  inputdata_renew,covernight_renew,fuelprice_renew_year,carboncontent_renew,inputdata_stor,covernight_kW_stor,covernight_kWh_stor
$load  duration,discharge_to_charge_ratio,ntc
$load  national_target_emissions,eu_target_emissions,cap_hydro,cap_pumpstor,cap_conv_install  
$GDXin
$offUndf

;



execute_unload "check_yearly.gdx";
*$stop

load(country,year,hour) = demand(year,hour,country)
;

*############################################# conventional power plants #############################################

cvar_conv_full(conv,year) = ((sum(fuel_conv$(map_convfuel(conv,fuel_conv)), fuelprice_conv_year(year,fuel_conv)
                                        + carboncontent_conv(fuel_conv)* carbonprice_year(year)) / inputdata_conv(conv,'efficiency') )
                                        )
;

cvar_conv_min(conv,year) = ((sum(fuel_conv$(map_convfuel(conv,fuel_conv)), fuelprice_conv_year(year,fuel_conv)
                                        + carboncontent_conv(fuel_conv)* carbonprice_year(year)) / inputdata_conv(conv,'efficiency_min') )
                                        )
;

cramp_conv(conv,year) = inputdata_conv(conv,'startup_fuelconsumption')
                                   * sum(fuel_conv$(map_convfuel(conv,fuel_conv)), fuelprice_conv_year(year,fuel_conv))
                                    + inputdata_conv(conv,'startup_fixcost')
;

availability_conv(conv,year,hour) = inputdata_conv(conv,'avail')                                           
;

gmin_conv(conv) = inputdata_conv(conv,'gmin')
;

cinv_conv(conv,year) = (interest_rate * covernight_conv(conv,year) * 1000) / (1 - exp(-interest_rate * inputdata_conv(conv,'lifetime_eco'))) + cvarom_conv(conv,year)*1000 
;

*############################################# renewable energy sources #############################################

renew_ndisp(renew)$(inputdata_renew(renew,'renew_ndisp') eq 1) = YES
;

renew_disp(renew)$(inputdata_renew(renew,'renew_disp') eq 1) = YES
;

capfactor_renew_max(country,'solar',year,hour) = capfactor_solar(year,hour,country)
;

capfactor_renew_max(country,'windonshore',year,hour) = capfactor_windonshore(year,hour,country)
;

capfactor_renew_max(country,'windoffshore',year,hour) = capfactor_windoffshore(year,hour,country)
;

capfactor_renew_max(country,'runofriver',year,hour) = capfactor_runofriver(year,hour,country)
;

capfactor_renew_max(country,'biomass',year,hour) = capfactor_biomass(year,hour,country)
;

capfactor_renew_max(country,'reservoir',year,hour) = capfactor_reservoir_max(year,hour,country)
;

capfactor_renew_min(country,'reservoir',year,hour) = capfactor_reservoir_min(year,hour,country)
;

cvar_renew(renew,year) = ( (sum(fuel_renew$(map_renewfuel(renew,fuel_renew)), fuelprice_renew_year(year,fuel_renew)
                                    + carboncontent_renew(fuel_renew) * carbonprice_year(year)) /  inputdata_renew(renew,'efficiency'))
                                    )
;

availability_renew(renew,year,hour)  = inputdata_renew(renew,'avail')
;

efficiency_renew(renew) = inputdata_renew(renew,'efficiency')
;

cinv_renew(renew,year) = (interest_rate * covernight_renew(renew,year) * 1000 ) / (1 - exp(-interest_rate * inputdata_renew(renew,'lifetime_eco')))
;

*renew_ncurt(renew)$((inputdata_renew(renew,'renew_curt') eq 0) AND (inputdata_renew(renew,'renew_disp') eq 0)) = YES
*;

*############################################# storage sources #############################################

avail_stor(stor) = inputdata_stor(stor,'avail')
;

efficiency_stor(stor) = inputdata_stor(stor,'efficiency')
;

cinv_MW_stor(stor,year) = (interest_rate * covernight_kW_stor(stor,year) * 1000 ) / ( 1- exp(-interest_rate * inputdata_stor(stor,'lifetime_eco')))
;

cinv_MWh_stor(stor,year) = (interest_rate * covernight_kWh_stor(stor,year) * 1000 ) / ( 1- exp(-interest_rate * inputdata_stor(stor,'lifetime_eco')))
;

*duration_stor(stor,year) = storageduration(stor,year)
*;

*discharge_to_charge_ratio_stor(stor,year) = discharge_to_charge_ratio(stor,year)
*;
