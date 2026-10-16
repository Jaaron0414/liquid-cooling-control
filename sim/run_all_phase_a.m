function run_all_phase_a()
% Reproduce the baseline, fixed-fan comparison, five trials and tuned result.
% This intentionally restores baseline defaults before repeating experiments.
setup_phase_a();
root=fileparts(mfilename('fullpath')); mdl='liquid_cooling_phase_a';
if isfile(fullfile(root,[mdl '.slx']))
    load_system(fullfile(root,[mdl '.slx']));
    update_phase_a_parameters();
else
    build_phase_a();
end
run_phase_a();
tune_phase_a_pid();
apply_phase_a_pid_tuning();
disp('All Phase A experiments complete; the model now contains the tuned PID.');
end
