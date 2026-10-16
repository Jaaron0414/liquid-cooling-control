function build_phase_a()
% Reproducible minimal Simscape thermal plant and Simulink PID loop.
root = fileparts(mfilename('fullpath'));
diary(fullfile(root,'build_log.txt'));
try
    p = phase_a_parameters();
    mdl = 'liquid_cooling_phase_a';
    if bdIsLoaded(mdl)
        error('Model already open. Save your edits and close it before rebuilding.');
    end
    if isfile(fullfile(root,[mdl '.slx']))
        error('Saved model exists. Open it, or rename it before rebuilding.');
    end
    load_system('fl_lib'); load_system('nesl_utility'); load_system('simulink');
    new_system(mdl); open_system(mdl);
    ws = get_param(mdl,'ModelWorkspace'); assignin(ws,'p',p);
    set_param(mdl,'Solver','ode23t','StopTime','p.stopTime', ...
        'MaxStep','1','RelTol','1e-5','ReturnWorkspaceOutputs','on');

    add('simulink/Sources/Constant','Target_C',[45 55 105 85],'Value','p.Tset_C');
    add('simulink/Math Operations/Sum','Too_hot_error',[170 110 200 145],'Inputs','+-');
    add('simulink/Continuous/PID Controller','Fan_PID',[255 105 350 150], ...
        'Controller','PID','Form','Parallel','P','p.Kp','I','p.Ki','D','p.Kd','N','p.N', ...
        'LimitOutput','on','UpperSaturationLimit','1','LowerSaturationLimit','0', ...
        'AntiWindupMode','clamping');
    add('simulink/Continuous/Transfer Fcn','Fan_dynamics',[405 105 500 150], ...
        'Numerator','1','Denominator','[p.tauFan 1]');
    add('simulink/Math Operations/Gain','Fan_to_h',[550 105 620 150],'Gain','p.Gfan/0.1');
    add('simulink/Math Operations/Bias','Passive_h',[665 105 735 150],'Bias','p.Gpassive/0.1');
    add(util('Simulink-PS Converter'),'h_to_PS',[785 110 835 145],'Unit','W/(m^2*K)');
    add('simulink/Sources/Step','Heat_load_W',[45 315 110 345], ...
        'Time','p.stepTime','Before','p.Qinitial','After','p.Qfinal');
    add(util('Simulink-PS Converter'),'Heat_to_PS',[155 315 205 345],'Unit','W');

    add(thermal('Thermal Mass'),'Chip_thermal_mass',[340 320 410 390], ...
        'mass','p.mChip','sp_heat','p.cpChip','T','p.Tinitial_K','T_unit','K', ...
        'T_specify','on','T_priority','High');
    add(thermal('Thermal Mass'),'Coolant_thermal_mass',[640 320 710 390], ...
        'mass','p.mWater','sp_heat','p.cpWater','T','p.Tinitial_K','T_unit','K', ...
        'T_specify','on','T_priority','High');
    add(thermal('Thermal Resistance'),'Cold_plate_resistance',[470 245 560 295], ...
        'resistance','p.RchipWater');
    add(thermal('Convective Heat Transfer'),'Radiator_convection',[800 240 890 300], ...
        'thermal_type','2','area','0.1');
    add(thermal('Controlled Heat Flow Rate Source'),'Heater',[250 245 310 300]);
    add(thermal('Temperature Source'),'Ambient_25C',[970 245 1035 305], ...
        'temperature','p.Tambient_C+273.15','temperature_unit','K');
    add(thermal('Thermal Reference'),'Thermal_reference',[245 430 285 470]);
    add(util('Solver Configuration'),'Solver_configuration',[465 430 535 470]);
    add(thermal('Temperature Sensor'),'Chip_sensor',[365 515 425 555], ...
        'temperature_measure','2');
    add(thermal('Temperature Sensor'),'Coolant_sensor',[665 515 725 555], ...
        'temperature_measure','2');
    add(util('PS-Simulink Converter'),'Chip_K',[465 515 515 555],'Unit','K');
    add(util('PS-Simulink Converter'),'Coolant_K',[765 515 815 555],'Unit','K');
    add('simulink/Math Operations/Bias','Chip_C',[550 515 615 555],'Bias','-273.15');
    add('simulink/Math Operations/Bias','Coolant_C',[855 515 920 555],'Bias','-273.15');
    add('simulink/Signal Routing/Mux','Signals',[1060 350 1065 520],'Inputs','5');
    add('simulink/Sinks/Scope','Scope',[1130 385 1200 440]);
    add('simulink/Sinks/To Workspace','Record',[1120 480 1220 520], ...
        'VariableName','phaseA','SaveFormat','Timeseries');

    % Save the draft before wiring, so any build error is recoverable.
    save_system(mdl,fullfile(root,[mdl '.slx']));
    wire_phase_a();
    disp('BUILD_COMPLETE');
catch ME
    disp(getReport(ME,'extended','hyperlinks','off'));
    diary off
    rethrow(ME)
end
diary off

    function add(src,name,pos,varargin)
        add_block(src,[mdl '/' name],'Position',pos,varargin{:});
    end
    function b=thermal(name)
        b=find_system('fl_lib','LookUnderMasks','all','FollowLinks','on','Name',name);
        assert(numel(b)==1,'Expected one thermal block: %s',name); b=b{1};
    end
    function b=util(name)
        b=find_system('nesl_utility','SearchDepth',1,'RegExp','on','Name',strrep(name,' ','\s*'));
        assert(numel(b)==1,'Expected one utility block: %s',name); b=b{1};
    end
end
