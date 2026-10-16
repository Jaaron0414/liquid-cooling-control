function apply_phase_a_pid_tuning()
% Apply the last tested candidate; baseline defaults and backup are retained.
root=fileparts(mfilename('fullpath')); mdl='liquid_cooling_phase_a';
d=load(fullfile(root,'pid_tuning_trials.mat'));
selected=5; g=d.gains(selected,:);
assert(d.results.Peak_C(selected)<d.results.Peak_C(1),'Candidate did not reduce peak');
load_system(fullfile(root,[mdl '.slx'])); ws=get_param(mdl,'ModelWorkspace');
p=getVariable(ws,'p'); p.Kp=g(1); p.Ki=g(2); p.Kd=g(3);
assignin(ws,'p',p);
set_param([mdl '/Fan_PID'],'P','p.Kp','I','p.Ki','D','p.Kd');
save_system(mdl,fullfile(root,[mdl '.slx']));
view_phase_a_scope();
% Present a focused before/after figure in addition to the five-step figure.
f=figure('Name','PID before and after - 600 s load step','Color','w', ...
    'Position',[100 70 1150 850]);
tiledlayout(3,1,'TileSpacing','compact');
b=d.runs{1}; a=d.runs{selected};
nexttile; plot(b.t,b.y(:,1),'LineWidth',1.6); hold on;
plot(a.t,a.y(:,1),'LineWidth',1.6); yline(40,':k'); xline(600,':k');
grid on; xlim([550 1300]); ylabel('Chip (deg C)');
legend('Before: P=.06, I=.0006, D=.1','After: P=.24, I=.0012, D=.5', ...
    'Target','Load step','Location','northeast');
title('600 s load step: peak 43.52 -> 42.01 deg C');
nexttile; plot(b.t,b.y(:,2),'LineWidth',1.5); hold on;
plot(a.t,a.y(:,2),'LineWidth',1.5); xline(600,':k');
grid on; xlim([550 1300]); ylabel('Coolant (deg C)'); legend('Before','After');
nexttile; plot(b.t,100*b.y(:,4),'LineWidth',1.5); hold on;
plot(a.t,100*a.y(:,4),'LineWidth',1.5); xline(600,':k');
grid on; xlim([550 1300]); ylabel('Actual fan (%)'); xlabel('Simulation time (s)');
legend('Before','After','Location','southeast');
exportgraphics(f,fullfile(root,'pid_before_after.png'),'Resolution',150);
savefig(f,fullfile(root,'pid_before_after.fig'));
fprintf('APPLIED: P=%.4g, I=%.4g, D=%.4g\n',g);
end
