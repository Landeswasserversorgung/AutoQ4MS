function generateISPlots(polarity, startDate, endDate, axesStruct, Parameters)

    % --- Vorbereitung ---
    startDateStr = datestr(startDate, 'yyyy-mm-dd HH:MM:SS');
    endDateStr = datestr(endDate, 'yyyy-mm-dd HH:MM:SS');
    
    if polarity == '+'
        
        ISKey = 'IS_pos';
    else
        
        ISKey = 'IS_neg';
    end
    
    markers = repmat({'o-','*-','x-','s-','d-','^-','v-','>-','<-'}',20,1);

    % === Import Internal Standards ===
    optsIS = detectImportOptions(Parameters.path.ISExcel);
    optsIS = setvartype(optsIS, {'ID','Name','Formula','Adduct_pos','Adduct_neg'}, 'string');
    optsIS = setvartype(optsIS, {'IS_pos','IS_neg'}, 'logical');
    optsIS = setvartype(optsIS, {'RT','mz_pos','mz_neg'}, 'double');

    T2 = readtable(Parameters.path.ISExcel, optsIS);

    ISdict = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for i = 1:height(T2)
        is = InternalStandard(T2(i,:));
        ISdict(char(is.ID)) = is;
    end

    %% === RT Deviation ===
    [ISRTTable,~] = SQLRequest(startDateStr, endDateStr, polarity, 'foundRT', 'ISValue', '', '', Parameters);
    ISRTTable = filterIS(ISRTTable, ISdict, ISKey);
    
    columnNames = ISRTTable.Properties.VariableNames;
    for i = 1:numel(columnNames)
        if strcmp(columnNames{i},'datetime_aq'), continue; end
        ISRTTable.(columnNames{i}) = (ISRTTable.(columnNames{i}) - ...
            median(ISRTTable.(columnNames{i}),'omitnan')) * 60;
    end
    
    series = ISRTTable{:, 2:end};
    medianVals = median(series, 2, 'omitnan');
    dates = datetime(ISRTTable.datetime_aq, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    
    ax = axesStruct.RT;
    cla(ax);
    hold(ax, 'on');
    for i = 1:size(series,2)
        plot(ax, dates, series(:,i), markers{i}, 'DisplayName', columnNames{i+1});
    end
    plot(ax, dates, medianVals, '-k', 'DisplayName', 'Median');
    hideYLine(yline(ax, Parameters.DeviceControl.RT_lowerLimit, '--k', 'Lower'));
    hideYLine(yline(ax, 0, '--k'));
    hideYLine(yline(ax, Parameters.DeviceControl.RT_upperLimit, '--k', 'Upper'));
    hold(ax, 'off');
    ylabel(ax, 'Retention time deviation / s');
    xlabel(ax, '') ; 
    title(ax, 'RT Deviation');
    legend(ax, 'Location', 'eastoutside', 'Interpreter', 'none');
    ylim(ax, [-20 20]);

    %% === Mass Accuracy ===
    [ISmassaccuracyTable,~] = SQLRequest(startDateStr, endDateStr, polarity, 'massaccuracy', 'ISValue', '', '', Parameters);
    ISmassaccuracyTable = filterIS(ISmassaccuracyTable, ISdict, ISKey);
    
    series = ISmassaccuracyTable{:, 2:end};
    medianVals = median(series, 2, 'omitnan');
    dates = datetime(ISmassaccuracyTable.datetime_aq, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    
    ax = axesStruct.MA;
    cla(ax);
    hold(ax, 'on');
    for i = 1:size(series,2)
        plot(ax, dates, series(:,i), markers{i}, 'DisplayName', ISmassaccuracyTable.Properties.VariableNames{i+1});
    end
    plot(ax, dates, medianVals, '-k', 'DisplayName', 'Median');
    hideYLine(yline(ax, -Parameters.DeviceControl.massaccuracy, '--k', 'Lower'));
    hideYLine(yline(ax, 0, '--k'));
    hideYLine(yline(ax, Parameters.DeviceControl.massaccuracy, '--k', 'Upper'));
    hold(ax, 'off');
    ylabel(ax, 'Mass accuracy / ppm');
    xlabel(ax, '') ; 
    title(ax, 'Mass Accuracy');
    legend(ax, 'Location', 'eastoutside', 'Interpreter', 'none');
    ylim(ax, [-20 20]);

    %% === Intensity ===
    [normISintensityTable,~] = SQLRequest(startDateStr, endDateStr, polarity, 'normIntensities', 'ISValue', '', '', Parameters);
    normISintensityTable = filterIS(normISintensityTable, ISdict, ISKey);
 
    series = normISintensityTable{:, 2:end};
    medianVals = median(series, 2, 'omitnan');
    dates = datetime(normISintensityTable.datetime_aq, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    
    ax = axesStruct.Intensity;
    cla(ax);
    hold(ax, 'on');
    for i = 1:size(series,2)
        plot(ax, dates, series(:,i), markers{i}, 'DisplayName', normISintensityTable.Properties.VariableNames{i+1});
    end
    plot(ax, dates, medianVals, '-k', 'DisplayName', 'Median');
    hideYLine(yline(ax, Parameters.DeviceControl.intensity_lowerLimit, '--k', 'Lower'));
    hideYLine(yline(ax, 1, '--k'));
    hideYLine(yline(ax, Parameters.DeviceControl.intensity_upperLimit, '--k', 'Upper'));
    set(ax, 'YScale', 'log');
    set(ax, 'YTick', [0.1 0.2 0.3 0.5 1 2 3 5 10]);
    ylim(ax, [0.1, 10]);
    hold(ax, 'off');
    ylabel(ax, 'Relative intensity');
    xlabel(ax, '') ; 
    title(ax, 'Intensity');
    legend(ax, 'Location', 'eastoutside', 'Interpreter', 'none');

end


function hideYLine(h)
    % Entfernt yline aus der Legende
    set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end



