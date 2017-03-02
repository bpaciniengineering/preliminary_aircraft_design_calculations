%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Bernardo Pacini                                                       %%
%% MAE 332 - Aircraft Design                                             %%
%% Preliminary Design Calculations                                       %%
%% Feb. 27, 2017 Thur                                                    %%
%%                                                                       %%
%% Description: This code will output preliminary aircraft design        %%
%% calculations to a .txt file.                                          %%
%%                                                                       %%
%% Extra Dependencies: | aircraft_mass.m | atmos.m |                     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;
clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SELECT WORKING DIRECTORY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%folder_name = uigetdir('C:\','Select Working Directory');
%cd(folder_name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INPUT VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Trial_Name  = 'Trial 1' ;
Description = ''        ;

M_cruise    = 0.85       ; 
R           = 6500      ; %nm
AR          = 8         ; %assume about 8                       %ESTIMATE
e           = 0.8       ; %Oswald efficiency factor, assume 0.8 (Raymer 92)
tsfc        = 0.7       ; %0.45<=tsfc<=1.2 - check engine manufacturer
altitude_ci = 35000     ; %cruise altitude, ft
altitude_fi = 0         ; % airfield alitude, ft
passengers  = 210       ; %persons
crew        = 6         ; %persons
baggage     = [4000 1]  ; %lbs allotment passenger or crew
loiter_dur  = 0         ; %sec

weight_max  = 1e6       ; %max of weight range
graph       = 1         ; %1/0 for plot on/off

V_stall     = 137       ; %knots
V_approach  = 150       ; %knots
Clmax       = 1.8       ; %assumed
L_takeoff   = 10500     ; %ft REQUIREMENT
L_landing   = 3600      ; %ft REQUIREMENT
rate_climb  = 3500      ; %ft/min
theta_app   = 3         ; %approach angle, deg

% cruise parameters
C_D0_c  = 0.02          ; % assumed (at cruise)
C_DR_c  = 0             ; % assumed (clean configuration at cruise)
K1_c    = 1/(pi*AR*e)   ; % induced drag correction factor
K2_c    = 0             ; % viscous drag correction factor
gamma   = 1.4           ; % specific heat ratio cp/cv, for air
TR      = 1             ; % assumed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%DO NOT MODIFY BELOW THIS POINT%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCTION CALLING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Take-off Weight
[W_TO, W_fuel, W_empty] = aircraft_mass(M_cruise, R, AR, tsfc,...
    altitude_ci, passengers, crew, baggage, loiter_dur, weight_max, graph);

disp(sprintf('%0.0f Takeoff Weight', W_TO)); 
disp(sprintf('%0.0f Fuel Weight', W_fuel));
disp(sprintf('%0.0f Empty Weight', W_empty));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Surface Area
%[] = aircraft_surfacearea();
altitude_c = altitude_ci*0.3048;
[airDens_c, airPres_c, temp_c, soundSpeed_c] = Atmos(altitude_ci);%kg/m^3 N/m^2 K m/s
[airDens_f, airPres_f, temp_f, soundSpeed_f] = Atmos(altitude_fi);
[airDens_sl, airPres_sl, temp_sl, soundSpeed_sl] = Atmos(0);

% Convert values from SI to Imperial
airDens_ci    = airDens_c * 0.0624;         %lbm/ft^3
airPres_ci    = airPres_c * 0.000145038;    %PSI
temp_ci       = (9/5)*(temp_c - 273) + 32;  %F
soundSpeed_ci = soundSpeed_c*2.23694;       %convert to mph
airDens_fi    = airDens_f * 0.0624;         %lb/ft^3
airPres_fi    = airPres_f * 0.000145038;    %PSI
temp_fi       = (9/5)*(temp_f - 273) + 32;  %F
soundSpeed_fi = soundSpeed_f*2.23694;       %convert to mph
airDens_sli = airDens_sl * 0.0624;          %air density at sea level
sigma = airDens_fi/airDens_sli;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stall
figure()
hax=axes; 
title('Constraint Plane (T/W - W/S)');
xlabel('Wing Loading [W_g/S], lb/ft^2');
ylabel('Thrust Loading [T_0/W_g]');
hold on;
V_stall = V_stall * 1.68781; %convert to ft/s
WS_stall = ((V_stall^2)*airDens_sli*Clmax)/(2*32.174);
% Plotted later for cosmetic reasons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Take-off
WS = linspace(1,200);
TW_takeoff = ((20.9.*WS)/(sigma*Clmax)).*...
    (L_takeoff-69.6.*(WS./(sigma*Clmax)).^(.5)).^(-1);

plot(WS, TW_takeoff);
line([WS_stall WS_stall],get(hax,'YLim'),'Color',[1 0 0]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constant Cruise Flight
% beta = 
% alpha =
% k1 = 
% k2 = 
q = dynamic_viscosity(altitude_c);

% TW_CCF = (beta/alpha)*(k1*(beta/q)*WS + k2 + (CD_O + CD_R)/((beta/q)*WS));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Climb-performance
% beta = 
% alpha =
% k1 = 
% k2 = 
q = dynamic_viscosity(altitude_c);
dHdt = rate_climb;

%TW_CP = (beta/alpha)*(k1*(beta/q)*WS + k2 + (CD_O + CD_R)/((beta/q)*WS)...
 %   + (1/V)*(dHdt));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cruise-performance
% ISSUE: some of this is copied from aircraft_mass.m
% Solution: Think about restructuring the architecture to use code more efficiently

g = 32.174; %ft/s^2
V_c = (soundSpeed_c*3.28084)*M_cruise; % ft/s
q = 0.5*(airDens_ci/g)*V_c^2; % note: 1 lbm = 1/g slugs

if M_cruise < 1
    L_D = AR + 10;
else
    L_D = 11/sqrt(M_cruise);
end
% Breguet Range Equation
% R = (V/tsfc) * (L_D) * ln(Wi/Wf) %lbfuel/h/lbt
beta_c = 1/(exp(R*6076.12*((tsfc/3600)/(V_c))/(L_D)));

% calculate alpha_tilde (for high bypass ratio turbofan engine)
theta0 = (temp_c/temp_sl)*(1+0.5*(gamma-1)*M_cruise^2);
delta0 = (airPres_c/airPres_sl)*...
    (1+0.5*(gamma-1)*M_cruise^2)^(gamma/(gamma-1))
if theta0 <= TR
    alpha_c = delta0*(1 - 0.49*M_cruise^0.5);
else
    alpha_c = delta0*(1 - 0.49*M_cruise^0.5 - 3*(theta0-TR)/(1.5+M_cruise));
end

TW_cruise = (beta_c/alpha_c)*(K1_c*beta_c*WS/q + K2_c + ...
    (C_D0_c+C_DR_c)./(beta_c*WS/q));

plot(WS, TW_cruise, 'g');
%ylim([0 0.5]);

%n = sqrt(1 + ((V^2))/g*R); % - here we assume n = 1 (no turning)

%TW_CLT = (beta/alpha)*(k1*n^2*(beta/q)*WS + k2*n + ...
  % (CD_O + CD_R)/((beta/q)*WS));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Landing

%WS_landing = (s_L - 50/tan(deg2rad(theta_app)))*sigma*Clmax/79.4;
%line([WS_landing WS_landing], get(hax,'YLim'),'Color',[0 1 0]);

%SL = 
%theta = 

%WS_landing = ((sigma * Clmax)/(79.4)) *(SL  - 50/tan(theta))

plot(WS, TW_takeoff);
title('Constraint Plane (T/W - W/S)');
xlabel('Wing Loading [W_g/S], lb/ft^2');
ylabel('Thrust Loading [T_0/W_g]');
line([WS_stall WS_stall],get(hax,'YLim'),'Color',[1 0 0]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT TO TEXT FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
text = sprintf('Perliminary Aircraft Design Calculations - %s.txt',...
    Trial_Name);
fid = fopen(text,'w');
fprintf(fid, sprintf('Perliminary Aircraft Design Calculations- %s',...
    Trial_Name));
fprintf(fid, sprintf('\n')); 
fprintf(fid, sprintf('%s',Description));
fprintf(fid, sprintf('\n\n'));

fprintf(fid, sprintf('%0.0f Takeoff Weight', W_TO)); 
fprintf(fid, sprintf('\n')); 
fprintf(fid, sprintf('%0.0f Fuel Weight', W_fuel));
fprintf(fid, sprintf('\n')); 
fprintf(fid, sprintf('%0.0f Empty Weight', W_empty));
fprintf(fid, sprintf('\n')); 
