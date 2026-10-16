function view_phase_a_scope()
% Group Scope traces by physical units; leave plant and controller unchanged.
root=fileparts(mfilename('fullpath')); mdl='liquid_cooling_phase_a';
if ~bdIsLoaded(mdl), load_system(fullfile(root,[mdl '.slx'])); end
cfg=get_param([mdl '/Scope'],'ScopeConfiguration');
if getSimulinkBlockHandle([mdl '/Scope_groups'])==-1
    delete_line(mdl,'Signals/1','Scope/1');
    add_block('simulink/Signal Routing/Demux',[mdl '/Scope_groups'], ...
        'Outputs','[2 2 1]','Position',[1100 345 1105 425]);
    add_block('simulink/Math Operations/Gain',[mdl '/Fan_percent'], ...
        'Gain','100','Position',[1140 370 1190 400]);
    cfg.NumInputPorts='3';
    set_param([mdl '/Scope'],'Position',[1255 340 1325 430]);
    add_line(mdl,'Signals/1','Scope_groups/1','autorouting','on');
    h=add_line(mdl,'Scope_groups/1','Scope/1','autorouting','on');
    set_param(h,'Name','Temperature_C');
    add_line(mdl,'Scope_groups/2','Fan_percent/1','autorouting','on');
    h=add_line(mdl,'Fan_percent/1','Scope/2','autorouting','on');
    set_param(h,'Name','Fan_percent');
    h=add_line(mdl,'Scope_groups/3','Scope/3','autorouting','on');
    set_param(h,'Name','Heater_W');
end
cfg.LayoutDimensions=[3 1]; cfg.TimeSpan='1800';
cfg.Position=[100 80 1100 880]; cfg.AxesScaling='Manual';
titles={'Temperature: channel 1 = chip, channel 2 = coolant', ...
    'Fan: channel 1 = command, channel 2 = actual', ...
    'Heater: 20 W to 40 W at 600 s'};
units={'deg C','percent','W'}; limits={[24 46],[-2 75],[0 45]};
for k=1:3
    cfg.ActiveDisplay=num2str(k); cfg.Title=titles{k};
    cfg.YLabel=units{k}; cfg.YLimits=limits{k};
    cfg.ShowLegend=true; cfg.ShowGrid=true;
end
cfg.ActiveDisplay='1';
save_system(mdl,fullfile(root,[mdl '.slx']));
out=sim(mdl); ts=out.get('phaseA'); t=ts.Time; y=squeeze(ts.Data);
if size(y,1)~=numel(t), y=y'; end
sampleTimes=[0;300;599.99;600;650;700;900;1200;1800];
samples=interp1(t,y,sampleTimes);
report=evalc('disp(array2table([sampleTimes samples],''VariableNames'',{''Time_s'',''Chip_C'',''Coolant_C'',''FanCommand'',''FanActual'',''Heater_W''}))');
idx=find(t>=600); [peak,j]=max(y(idx,1));
report=[report sprintf('\nPeak chip after load step: %.6f C at %.3f s\n',peak,t(idx(j)))];
fid=fopen(fullfile(root,'scope_readings.txt'),'w'); fprintf(fid,'%s',report); fclose(fid);
writetable(array2table([t y],'VariableNames', ...
    {'Time_s','Chip_C','Coolant_C','FanCommand','FanActual','Heater_W'}), ...
    fullfile(root,'scope_latest.csv'));
disp(report); open_system([mdl '/Scope']);
end
