Scalars
ccurt_renew                              /110/
voll                                     /10000/
grid_loss                                /0.01/
interest_rate                            /0.07/
indicator_ramping                        /1/
;

Parameters



*############################################# Input parameter #############################################

********************************************** cap factors **********************************************

capfactor_reservoir_max(year,hour,country)           hourly maximum capacity factor for reservoir feed-in (MWh per MW)
capfactor_reservoir_min(year,hour,country)           hourly minimum capacity factor for reservoir feed-in (MWh per MW)
*capfactor_runofriver(year,hour)              hourly capacity factor for windoffshore feed-in (MWh per MW)
capfactor_solar(year,hour,country)                  hourly capacity factor for solar1 feed-in (MWh per MW)
*capfactor_solar2(year,hour)                  hourly capacity factor for solar2 feed-in (MWh per MW)
*capfactor_solar3(year,hour)                  hourly capacity factor for solar3 feed-in (MWh per MW)
*capfactor_solar4(year,hour)                  hourly capacity factor for solar4 feed-in (MWh per MW)
capfactor_windonshore(year,hour,country)            hourly capacity factor for windonshore1 feed-in (MWh per MW)
*capfactor_windonshore2(year,hour)            hourly capacity factor for windonshore2 feed-in (MWh per MW)
*capfactor_windonshore3(year,hour)            hourly capacity factor for windonshore3 feed-in (MWh per MW)
*capfactor_windonshore4(year,hour)            hourly capacity factor for windonshore4 feed-in (MWh per MW)
capfactor_windoffshore(year,hour,country)            hourly capacity factor for windoffshore feed-in (MWh per MW)


********************************************** hourly load & trade **********************************************

demand(year,hour,country)                              considered demand (MWh per h)
*trade(year,hour)                               considered trade between neighbooring countries (MWh per h)
load(country,year,hour)                                considered load out of demand + trade

********************************************** conv parameters **********************************************

carbonprice_year(year)                                    yearly co2 price (EUR per tonne)
inputdata_conv(conv,*)                                    excel input table for conv
fuelprice_conv_year(year,fuel_conv)                       yearly fuel price (EUR per MWh_th)
carboncontent_conv(fuel_conv)                             emission factor (tCO2 per MWh_th)
outages_conv(conv)                                        country-specific yearly outages (%)
availability_conv(conv,year,hour)                         country-specific availability factor (%)
covernight_conv(conv,year)                                yearly overnight cost for conv (EUR per kW)
cvarom_conv(conv,year)                                    yearly varom cost for conv (EUR per MWh)


********************************************** renew parameters **********************************************

inputdata_renew(renew,*)                                   excel input table for renew
covernight_renew(renew,year)                               overnight investment cost (EUR per kW)
cvarom_renew(renew,year)                                   yearly varom costs for renew (EUR per MWh)
fuelprice_renew_year(year,fuel_renew)                      fuel price (EUR per MWh_th)
carboncontent_renew(fuel_renew)                            emission factor (tCO2 per MWh_th)


********************************************** storage parameters **********************************************

inputdata_stor(stor,*)                                      excel input table for stor
cfix_stor(stor,year)                                        fix costs storages
*cinv_stor(stor,year)                                        investment costs storages
covernight_kW_stor(stor,year)                               overnight investment cost for storage turbine (EUR per kW)
covernight_kWh_stor(stor,year)                              overnight investment cost for storage (EUR per kWh)
storageduration(stor,year)                                  storage duration (hours)
discharge_to_charge_ratio(stor,year)                        discharge (turbine) to charge (pump) ratio (-)


*############################################# Calcluated parameter #############################################

********************************************** conv parameters **********************************************

cfix_conv(conv,year)                                      yearly fix cost (EUR per MW)
cinv_conv(conv,year)                                      annual investment cost (EUR per MW and year)
cramp_conv(conv,year)                                     ramping cost (EUR per MW)
cvar_conv_avg(conv,year)                                  variable generation cost at average capacity (EUR per MWh)
gmin_conv(conv)                                           minimum generation level
                  

********************************************** renew parameters **********************************************

availability_renew(renew,year,hour)                        availability of dispatchable renewables
capfactor_renew_max(country,renew,year,hour)                       maximum capacity factor for renewables
capfactor_renew_min(country,renew,year,hour)                       minimum capacity factor for renewables
cfix_renew(renew,year)                                     yearly fix cost (EUR per MW)
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

***new
ntc(country,country2)


*############################################# input Excel table #############################################


********************************************** hourly data **********************************************

*Input ändern für verschiedene Szeanrien!!!

$onecho > Input1.txt
set=country                      rng=demand!D2:J2                rdim=0  cdim=1
set=hour                         rng=hour!B5:B8765               rdim=1  cdim=0
par=demand                       rng=demand!B2:J87602            rdim=2  cdim=1
par=capfactor_reservoir_max      rng=reservoir_max!B2:J87602     rdim=2  cdim=1
par=capfactor_reservoir_min      rng=reservoir_min!B2:J87602     rdim=2  cdim=1
par=capfactor_solar              rng=solar!B2:J87602             rdim=2  cdim=1
par=capfactor_windonshore        rng=windonshore!B2:J87602       rdim=2  cdim=1
par=capfactor_windoffshore       rng=windoffshore!B2:J87602      rdim=2  cdim=1

$offecho
$onUNDF
$call  gdxxrw Input_hourly.xlsx @Input1.txt
$gdxIn Input_hourly.gdx
$load  country,hour,capfactor_reservoir_max,capfactor_reservoir_min,demand
$load  capfactor_windonshore,capfactor_solar
$load  capfactor_windoffshore
$GDXin
$offUndf

;
*execute_unload "check_hourly.gdx";
*$stop

********************************************** yearly data **********************************************

*Input ändern für verschiedene Szeanrien!!!

$onecho > Input2.txt
set=fuel_conv                            rng=fuel_conv!C4:G4                     rdim=0  cdim=1
set=fuel_renew                           rng=fuel_renew!B4:I4                    rdim=0  cdim=1
set=conv                                 rng=tech_conv!B4:B9                     rdim=1  cdim=0
set=renew                                rng=tech_renew!B4:B14                   rdim=1  cdim=0
set=stor                                 rng=tech_stor!B4:B6                     rdim=1  cdim=0
set=map_convfuel                         rng=tech_conv!M4:N9                     rdim=2  cdim=0
set=map_renewfuel                        rng=tech_renew!M4:N14                   rdim=2  cdim=0
par=carbonprice_year                     rng=co2!C5:D15                          rdim=1  cdim=0
par=inputdata_conv                       rng=tech_conv!B4:H9                     rdim=1  cdim=1
par=covernight_conv                      rng=tech_conv!B12:L17                   rdim=1  cdim=1
par=cvarom_conv                          rng=tech_conv!B19:L24                   rdim=1  cdim=1
par=outages_conv                         rng=outages_conv!D4:E9                  rdim=1  cdim=0
par=carboncontent_conv                   rng=fuel_conv!B21:C25                   rdim=1  cdim=0
par=fuelprice_conv_year                  rng=fuel_conv!C4:G14                    rdim=1  cdim=1
par=inputdata_renew                      rng=tech_renew!B4:H14                   rdim=1  cdim=1
par=covernight_renew                     rng=tech_renew!B23:L33                  rdim=1  cdim=1
par=cvarom_renew                         rng=tech_renew!B41:L51                  rdim=1  cdim=1
par=fuelprice_renew_year                 rng=fuel_renew!B4:I14                   rdim=1  cdim=1
par=carboncontent_renew                  rng=fuel_renew!B16:C18                  rdim=1  cdim=0
par=inputdata_stor                       rng=tech_stor!B4:F6                     rdim=1  cdim=1
par=covernight_kW_stor                   rng=tech_stor!B9:L11                    rdim=1  cdim=1
par=covernight_kWh_stor                  rng=tech_stor!B14:L16                   rdim=1  cdim=1
par=storageduration                      rng=tech_stor!B19:L21                   rdim=1  cdim=1
par=discharge_to_charge_ratio            rng=tech_stor!B24:L26                   rdim=1  cdim=1
par=ntc                                  rng=ntc!B3:I10                          rdim=1  cdim=1

$offecho
$onUNDF
$call  gdxxrw Input_yearly.xlsx @Input2.txt
$gdxIn Input_yearly.gdx
$load  fuel_conv,fuel_renew,conv,renew,stor,map_convfuel,map_renewfuel,covernight_conv,cvarom_conv,cvarom_renew 
$load  carbonprice_year,inputdata_conv,outages_conv
$load  carboncontent_conv,fuelprice_conv_year
$load  inputdata_renew,covernight_renew,fuelprice_renew_year,carboncontent_renew,inputdata_stor,covernight_kW_stor,covernight_kWh_stor
$load  storageduration,discharge_to_charge_ratio,ntc
$GDXin
$offUndf

;
*execute_unload "check_yearly.gdx";
*$stop

load(country,year,hour) = demand(year,hour,country) 
;

*############################################# conventional power plants #############################################

cvar_conv_avg(conv,year) = ((sum(fuel_conv$(map_convfuel(conv,fuel_conv)), fuelprice_conv_year(year,fuel_conv)
                                        + carboncontent_conv(fuel_conv)* carbonprice_year(year)) / inputdata_conv(conv,'efficiency') )
                                        )
;

cramp_conv(conv,year) = inputdata_conv(conv,'startup_fuelconsumption')
                                   * sum(fuel_conv$(map_convfuel(conv,fuel_conv)), fuelprice_conv_year(year,fuel_conv))
                                    + inputdata_conv(conv,'startup_fixcost')
;

availability_conv(conv,year,hour) = outages_conv(conv)                                           
;

gmin_conv(conv) = inputdata_conv(conv,'gmin')
;

cinv_conv(conv,year) = (interest_rate * covernight_conv(conv,year) * 1000) / (1 - exp(-interest_rate * inputdata_conv(conv,'lifetime_eco'))) + cvarom_conv(conv,year)*1000 
;


*############################################# renewable energy sources #############################################

renew_curt(renew) = yes
;

capfactor_renew_max(country,'solar',year,hour) = capfactor_solar(year,hour,country)
;

capfactor_renew_max(country,'windonshore',year,hour) = capfactor_windonshore(year,hour,country)
;

capfactor_renew_max(country,'windoffshore',year,hour) = capfactor_windoffshore(year,hour,country)
;

capfactor_renew_max(country,'reservoir',year,hour) = capfactor_reservoir_max(year,hour,country)
;

renew_disp(renew)$(inputdata_renew(renew,'renew_disp') eq 1) = YES
;

cvar_renew(renew,year) = ( (sum(fuel_renew$(map_renewfuel(renew,fuel_renew)), fuelprice_renew_year(year,fuel_renew)
                                    + carboncontent_renew(fuel_renew) * carbonprice_year(year)) /  inputdata_renew(renew,'efficiency'))
                                    )
;

availability_renew(renew,year,hour)  = inputdata_renew(renew,'avail')
;

efficiency_renew(renew) = inputdata_renew(renew,'efficiency')
;


capfactor_renew_min(country,'reservoir',year,hour) = capfactor_reservoir_min(year,hour,country)
;

renew_ncurt(renew)$((inputdata_renew(renew,'renew_curt') eq 0) AND (inputdata_renew(renew,'renew_disp') eq 0)) = YES
;

cinv_renew(renew,year) = (interest_rate * covernight_renew(renew,year) * 1000 ) / (1 - exp(-interest_rate * inputdata_renew(renew,'lifetime_eco'))) + cvarom_renew(renew,year)*1000
;


*############################################# storage sources #############################################

avail_stor(stor) = inputdata_stor(stor,'avail')
;

efficiency_stor(stor) = inputdata_stor(stor,'efficiency')
;

cinv_MW_stor(stor,year) = (interest_rate * covernight_kW_stor(stor,year) * 1000 ) / ( 1- exp(-interest_rate * inputdata_stor(stor,'lifetime_eco')))
;

cinv_MWh_stor(stor,year) = (interest_rate * covernight_kWh_stor(stor,year) * 1000 ) / ( 1- exp(-interest_rate * inputdata_stor(stor,'lifetime_eco')))
;

duration_stor(stor,year) = storageduration(stor,year)
;

discharge_to_charge_ratio_stor(stor,year) = discharge_to_charge_ratio(stor,year)
;
