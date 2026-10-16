function update_phase_a_parameters()
% Copy edited teaching defaults into the saved model's own workspace.
root=fileparts(mfilename('fullpath')); mdl='liquid_cooling_phase_a';
if ~bdIsLoaded(mdl), load_system(fullfile(root,[mdl '.slx'])); end
ws=get_param(mdl,'ModelWorkspace'); assignin(ws,'p',phase_a_parameters());
for b={'Chip_thermal_mass','Coolant_thermal_mass'}
    set_param([mdl '/' b{1}],'T_specify','on','T_priority','High', ...
        'T','p.Tinitial_K','T_unit','K');
end
save_system(mdl,fullfile(root,[mdl '.slx']));
end
