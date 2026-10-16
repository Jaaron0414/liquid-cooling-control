function preview_phase_a()
% Refresh readable signal labels and export the saved model diagram.
root=fileparts(mfilename('fullpath')); mdl='liquid_cooling_phase_a';
if ~bdIsLoaded(mdl), load_system(fullfile(root,[mdl '.slx'])); end
names={'Chip_C','Coolant_C','Fan_PID','Fan_dynamics','Heat_load_W'};
labels={'','','','',''};
for k=1:5
    ph=get_param([mdl '/' names{k}],'PortHandles');
    set_param(get_param(ph.Outport(1),'Line'),'Name',labels{k});
end
set_param([mdl '/Solver_configuration'],'Position',[465 430 535 470]);
set_param(mdl,'ZoomFactor','FitSystem');
save_system(mdl,fullfile(root,[mdl '.slx']));
print(['-s' mdl],'-dpng','-r150',fullfile(root,'phase_a_diagram.png'));
open_system(mdl);
end
