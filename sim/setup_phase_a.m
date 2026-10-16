function setup_phase_a()
% Add this portable folder and keep generated caches inside the repository.
root=fileparts(mfilename('fullpath'));
addpath(root);
assert(exist('sim','file')~=0,'Simulink is required.');
assert(exist('fl_lib','file')~=0,'Simscape Foundation Library is required.');
Simulink.fileGenControl('set','CacheFolder',fullfile(root,'.cache'), ...
    'CodeGenFolder',fullfile(root,'.codegen'),'createDir',true);
fprintf('Phase A ready. Tested with MATLAB R2026a, Simulink and Simscape.\n');
fprintf('Open liquid_cooling_phase_a.slx for the tuned PID.\n');
end
