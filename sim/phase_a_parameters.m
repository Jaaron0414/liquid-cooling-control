function p = phase_a_parameters()
% Teaching parameters, NOT measurements of the eventual hardware.
p.Tambient_C = 25;
p.Tset_C = 40;
p.Tinitial_K = 298.15;
p.mChip = 0.16;       % kg, effective heater + cold plate mass
p.cpChip = 500;       % J/(kg K), Cchip = 80 J/K
p.mWater = 0.10;      % kg, effective well-mixed coolant inventory
p.cpWater = 4180;     % J/(kg K), Cwater = 418 J/K
p.RchipWater = 0.10;  % K/W at assumed fixed pump flow
p.Gpassive = 0.4;     % W/K, radiator conductance at zero fan command
p.Gfan = 5.0;         % W/K, added conductance at full fan command
p.tauFan = 2;         % s, first-order normalized fan-speed response
p.Kp = 0.06;         % normalized fan command / K
p.Ki = 0.0006;       % normalized fan command / (K s)
p.Kd = 0.10;         % normalized fan command * s / K
p.N = 1;             % 1/s, derivative filter coefficient
p.Qinitial = 20;     % W
p.Qfinal = 40;       % W
p.stepTime = 600;    % s
p.stopTime = 1800;   % s
end
