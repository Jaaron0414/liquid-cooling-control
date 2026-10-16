function run_phase_a()
% Run the saved model, compare with a fixed fan, and check physical results.
root=fileparts(mfilename('fullpath'));
diary(fullfile(root,'simulation_log.txt'));
try
    mdl='liquid_cooling_phase_a';
    load_system(fullfile(root,[mdl '.slx']));
    ws=get_param(mdl,'ModelWorkspace'); p=getVariable(ws,'p');
    pidOut=sim(mdl);
    ts=pidOut.get('phaseA');
    t=ts.Time; y=squeeze(ts.Data);
    if size(y,1)~=numel(t), y=y'; end
    save(fullfile(root,'phase_a_raw.mat'),'p','ts');
    fprintf('Final raw channels: %s\n',mat2str(y(end,:),8));
    assert(size(y,2)==5,'Unexpected signal dimensions.');
    assert(all(abs(y(1,1:2)-(p.Tinitial_K-273.15))<1e-6), ...
        'Initial temperatures do not match the configured physical state targets.');
    % Channels: Tchip_C, Twater_C, fan command, actual fan fraction, Qheater_W.
    assert(all(isfinite(y(:))),'Simulation contains non-finite values.');
    assert(abs(y(end,1)-p.Tset_C)<0.1,'Final temperature error exceeds 0.1 K.');
    assert(all(y(:,3)>-1e-6 & y(:,3)<1+1e-6),'Fan command is outside [0,1].');
    assert(all(y(:,4)>-1e-6 & y(:,4)<1+1e-6),'Fan response is outside [0,1].');
    uExpected=(p.Qfinal/(p.Tset_C-p.Qfinal*p.RchipWater-p.Tambient_C)-p.Gpassive)/p.Gfan;
    assert(abs(y(end,4)-uExpected)<0.01,'Final fan speed disagrees with heat balance.');
    qRad=(p.Gpassive+p.Gfan*y(:,4)).*(y(:,2)-p.Tambient_C);
    stored=p.mChip*p.cpChip*(y(:,1)-y(1,1))+p.mWater*p.cpWater*(y(:,2)-y(1,2));
    % Exact heater integral avoids integrating across the discontinuity with trapz.
    heaterEnergy=p.Qinitial*min(t,p.stepTime)+p.Qfinal*max(t-p.stepTime,0);
    energyResidual=stored-heaterEnergy+cumtrapz(t,qRad);
    assert(max(abs(energyResidual))<0.002*heaterEnergy(end), ...
        'Energy balance residual exceeds 0.2 percent of input energy.');

    uFixed=(p.Qinitial/(p.Tset_C-p.Qinitial*p.RchipWater-p.Tambient_C)-p.Gpassive)/p.Gfan;
    fixedIn=Simulink.SimulationInput(mdl);
    fixedIn=fixedIn.setBlockParameter([mdl '/Fan_PID'],'P','0');
    fixedIn=fixedIn.setBlockParameter([mdl '/Fan_PID'],'I','0');
    fixedIn=fixedIn.setBlockParameter([mdl '/Fan_PID'],'D','0');
    fixedIn=fixedIn.setBlockParameter([mdl '/Fan_PID'],'InitialConditionForIntegrator',num2str(uFixed,16));
    fixedOut=sim(fixedIn);
    fixedTs=fixedOut.get('phaseA'); fixedY=squeeze(fixedTs.Data);
    if size(fixedY,1)~=numel(fixedTs.Time), fixedY=fixedY'; end
    assert(max(abs(fixedY(:,3)-uFixed))<1e-8,'Fixed fan comparison is not constant.');
    assert(fixedY(end,1)>y(end,1)+10,'Expected fixed fan comparison did not heat up.');

    f=figure('Name','Phase A - PID cooling baseline','Color','w','Position',[150 80 1100 800]);
    tiledlayout(3,1,'TileSpacing','compact');
    nexttile; plot(t,y(:,1),'LineWidth',1.6); hold on;
    plot(t,y(:,2),'LineWidth',1.4);
    plot(fixedTs.Time,fixedY(:,1),'--','LineWidth',1.3);
    yline(p.Tset_C,':k'); xline(p.stepTime,':'); grid on;
    ylabel('Temperature (deg C)');
    legend('Chip - PID','Coolant - PID','Chip - fixed fan','Target','Load step','Location','best');
    title('Teaching model: 20 W to 40 W at 600 s; ambient 25 deg C');
    nexttile; plot(t,y(:,3:4)*100,'LineWidth',1.3); hold on;
    yline(uFixed*100,'--'); xline(p.stepTime,':'); grid on; ylim([-5 105]);
    ylabel('Fan (%)'); legend('Command','Actual','Fixed baseline','Location','best');
    nexttile; plot(t,y(:,5),'LineWidth',1.3); hold on; plot(t,qRad,'LineWidth',1.3);
    grid on; ylabel('Heat flow (W)'); xlabel('Time (s)'); legend('Heater','Radiator','Location','best');
    exportgraphics(f,fullfile(root,'phase_a_results.png'),'Resolution',150);
    savefig(f,fullfile(root,'phase_a_results.fig'));
    save(fullfile(root,'phase_a_results.mat'),'p','ts','fixedTs','energyResidual');
    writetable(array2table([t y qRad],'VariableNames', ...
        {'Time_s','Chip_C','Coolant_C','FanCommand','FanActual','Heater_W','Radiator_W'}), ...
        fullfile(root,'phase_a_results.csv'));
    report=sprintf(['PASS: Phase A Simscape simulation\n' ...
        'Final chip: %.4f C\nFinal coolant: %.4f C\n' ...
        'Final fan: %.4f %% (heat-balance prediction %.4f %%)\n' ...
        'Peak chip after load step: %.4f C\nFixed-fan final chip: %.4f C\n' ...
        'Max energy residual: %.4f J (%.6f %% of heater input)\n'], ...
        y(end,1),y(end,2),100*y(end,4),100*uExpected, ...
        max(y(t>=p.stepTime,1)),fixedY(end,1),max(abs(energyResidual)), ...
        100*max(abs(energyResidual))/heaterEnergy(end));
    fid=fopen(fullfile(root,'verification.txt'),'w'); fprintf(fid,'%s',report); fclose(fid);
    disp(report);
    open_system(mdl);
catch ME
    disp(getReport(ME,'extended','hyperlinks','off'));
    diary off
    rethrow(ME)
end
diary off
end
