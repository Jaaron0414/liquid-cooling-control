function wire_phase_a()
% Complete the draft. Refuse to modify any model that already has lines.
root=fileparts(mfilename('fullpath')); mdl='liquid_cooling_phase_a';
diary(fullfile(root,'wiring_log.txt'));
try
    if ~bdIsLoaded(mdl), load_system(fullfile(root,[mdl '.slx'])); end
    assert(isempty(find_system(mdl,'FindAll','on','Type','line')), ...
        'Model already wired: refusing to add duplicate lines.');
    sl('Target_C/1','Too_hot_error/2');
    sl('Chip_C/1','Too_hot_error/1');
    sl('Too_hot_error/1','Fan_PID/1');
    sl('Fan_PID/1','Fan_dynamics/1');
    sl('Fan_dynamics/1','Fan_to_h/1');
    sl('Fan_to_h/1','Passive_h/1');
    sl('Passive_h/1','h_to_PS/1');
    sl('Heat_load_W/1','Heat_to_PS/1');

    % Port mappings verified against the actual R2026a block diagrams.
    % Heater: top B=LConn1, bottom S=RConn1, bottom A=RConn2.
    phys('Heat_to_PS','RConn',1,'Heater','RConn',1);
    phys('Heater','RConn',2,'Thermal_reference','LConn',1);
    phys('Thermal_reference','LConn',1,'Solver_configuration','RConn',1);
    phys('Heater','LConn',1,'Chip_thermal_mass','LConn',1);
    phys('Chip_thermal_mass','LConn',1,'Cold_plate_resistance','LConn',1);
    phys('Chip_thermal_mass','LConn',1,'Chip_sensor','LConn',1);
    phys('Cold_plate_resistance','RConn',1,'Coolant_thermal_mass','LConn',1);
    phys('Coolant_thermal_mass','LConn',1,'Coolant_sensor','LConn',1);
    % Variable convection: A=LConn1, K=LConn2, B=RConn1.
    phys('Coolant_thermal_mass','LConn',1,'Radiator_convection','LConn',1);
    phys('h_to_PS','RConn',1,'Radiator_convection','LConn',2);
    phys('Radiator_convection','RConn',1,'Ambient_25C','LConn',1);
    phys('Chip_sensor','RConn',1,'Chip_K','LConn',1);
    phys('Coolant_sensor','RConn',1,'Coolant_K','LConn',1);
    sl('Chip_K/1','Chip_C/1'); sl('Coolant_K/1','Coolant_C/1');
    sources={'Chip_C','Coolant_C','Fan_PID','Fan_dynamics','Heat_load_W'};
    labels={'','','','',''};
    for k=1:5
        h=sl([sources{k} '/1'],sprintf('Signals/%d',k));
        set_param(h,'Name',labels{k});
    end
    sl('Signals/1','Scope/1'); sl('Signals/1','Record/1');
    a=Simulink.Annotation(mdl, ...
        sprintf('PHASE A | Simscape thermal plant + PID fan control\nTeaching parameters: target 40 deg C; ambient 25 deg C; heater 20 -> 40 W at 600 s'));
    a.Position=[45 -35]; a.FontSize=13;
    a=Simulink.Annotation(mdl, ...
        sprintf('Fixed pump flow approximation\nTwo thermal masses + cold-plate resistance + variable radiator convection\nNot yet a Thermal Liquid pressure/flow network.'));
    a.Position=[450 625]; a.FontSize=11;
    set_param(mdl,'ZoomFactor','FitSystem');
    set_param(mdl,'SimulationCommand','update');
    save_system(mdl,fullfile(root,[mdl '.slx']));
    open_system(mdl); disp('WIRED_AND_COMPILED');
catch ME
    disp(getReport(ME,'extended','hyperlinks','off'));
    diary off
    rethrow(ME)
end
diary off
    function h=sl(src,dst)
        h=add_line(mdl,src,dst,'autorouting','on');
    end
    function phys(b1,f1,i1,b2,f2,i2)
        x=get_param([mdl '/' b1],'PortHandles'); y=get_param([mdl '/' b2],'PortHandles');
        add_line(mdl,x.(f1)(i1),y.(f2)(i2),'autorouting','on');
    end
end
