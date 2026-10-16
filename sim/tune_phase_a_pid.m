function tune_phase_a_pid()
% One-parameter-at-a-time experiments. Saved model is not edited by trials.
root=fileparts(mfilename('fullpath')); mdl='liquid_cooling_phase_a';
diary(fullfile(root,'pid_tuning_log.txt'));
try
load_system(fullfile(root,[mdl '.slx']));
ws=get_param(mdl,'ModelWorkspace'); p=getVariable(ws,'p');
% Preserve the exact pre-tuning model once.
backup=fullfile(root,'liquid_cooling_phase_a_before_tuning.slx');
if ~isfile(backup), copyfile(fullfile(root,[mdl '.slx']),backup); end
gains=[0.06 0.0006 0.10; 0.12 0.0006 0.10; ...
       0.24 0.0006 0.10; 0.24 0.0012 0.10; 0.24 0.0012 0.50];
names={'Baseline','P x2','P x4','Then I x2','Then D x5'};
runs=cell(5,1); settledRuns=cell(5,1); metrics=zeros(5,10);
for k=1:5
    runs{k}=trial(gains(k,:),600,1800);
    % A second experiment lets the 20 W startup settle before the step.
    settledRuns{k}=trial(gains(k,:),1800,3000);
    [m1,~]=measure(runs{k},600); [m2,~]=measure(settledRuns{k},1800);
    metrics(k,:)=[gains(k,:) m1 m2(1:2)];
    fprintf('%s: peak %.4f C; settle %.1f s; settled-start peak %.4f C\n', ...
        names{k},m1(1),m1(2),m2(1));
end
results=array2table(metrics,'VariableNames',{'P','I','D','Peak_C', ...
    'RecoveryTo02C_s','T_at_600_C','PeakFan_pct','FinalError_C', ...
    'SettledStartPeak_C','SettledStartRecovery_s'});
results.Name=names'; results=movevars(results,'Name','Before','P');
writetable(results,fullfile(root,'pid_tuning_metrics.csv'));
save(fullfile(root,'pid_tuning_trials.mat'),'p','gains','names','runs','settledRuns','results');
disp(results);
f=figure('Name','PID tuning - one parameter at a time','Color','w', ...
    'Position',[80 60 1200 900]);
tiledlayout(3,1,'TileSpacing','compact'); colors=lines(5);
nexttile; hold on;
for k=1:5, plot(runs{k}.t,runs{k}.y(:,1),'Color',colors(k,:),'LineWidth',1.5); end
yline(40,':k'); xline(600,':k'); grid on; xlim([550 1250]);
ylabel('Chip (deg C)'); title('Original experiment: cold start at 25 deg C, load step at 600 s');
legend(names,'Location','northeast');
nexttile; hold on;
for k=1:5, plot(runs{k}.t,100*runs{k}.y(:,4),'Color',colors(k,:),'LineWidth',1.4); end
xline(600,':k'); grid on; xlim([550 1250]); ylabel('Actual fan (%)');
nexttile; hold on;
for k=1:5, plot(settledRuns{k}.t-1800,settledRuns{k}.y(:,1),'Color',colors(k,:),'LineWidth',1.4); end
yline(40,':k'); grid on; xlim([-30 600]); ylabel('Chip (deg C)');
xlabel('Time relative to settled load step (s)');
title('Cross-check: same load step after the 20 W operating point settles');
exportgraphics(f,fullfile(root,'pid_tuning_comparison.png'),'Resolution',150);
savefig(f,fullfile(root,'pid_tuning_comparison.fig'));
disp('PID_TUNING_TRIALS_COMPLETE');
catch ME
diary off; rethrow(ME)
end
diary off
    function r=trial(g,step,stop)
        si=Simulink.SimulationInput(mdl);
        si=si.setBlockParameter([mdl '/Fan_PID'],'P',num2str(g(1),16));
        si=si.setBlockParameter([mdl '/Fan_PID'],'I',num2str(g(2),16));
        si=si.setBlockParameter([mdl '/Fan_PID'],'D',num2str(g(3),16));
        si=si.setBlockParameter([mdl '/Heat_load_W'],'Time',num2str(step));
        si=si.setModelParameter('StopTime',num2str(stop));
        o=sim(si); ts=o.get('phaseA'); r.t=ts.Time; r.y=squeeze(ts.Data);
        if size(r.y,1)~=numel(r.t), r.y=r.y'; end
        assert(all(isfinite(r.y(:))),'Non-finite simulation output');
        assert(all(r.y(:,3)>=-1e-6 & r.y(:,3)<=1+1e-6),'Fan exceeds bounds');
    end
    function [m,peakTime]=measure(r,step)
        post=find(r.t>=step); [pk,j]=max(r.y(post,1)); peakTime=r.t(post(j));
        bad=find(r.t>=step & abs(r.y(:,1)-40)>0.2,1,'last');
        if isempty(bad), recovery=0;
        elseif bad==numel(r.t), recovery=NaN;
        else, recovery=r.t(bad+1)-step; end
        before=interp1(r.t,r.y(:,1),step);
        m=[pk recovery before max(r.y(post,4))*100 r.y(end,1)-40];
    end
end
