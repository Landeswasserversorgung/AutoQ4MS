function plotDeviceMetric(dataTable, lowerLimit, upperLimit, yLabelStr, titleStr, markers, logScale)
            if nargin < 7
                logScale = false;
            end
        
            subplot(3, 1, find(strcmp(titleStr, {'Internal Standard Retention Time Deviation', 'Internal Standard Mass Accuracy', 'Internal Standard Intensity'})));
            hold on;
        
            dates = datetime(dataTable.datetime_aq, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
            series = dataTable{:, 2:end};
            names = dataTable.Properties.VariableNames(2:end);
            medianValues = median(series, 2, 'omitnan');
        
            for i = 1:size(series, 2)
                plot(dates, series(:, i), markers{i}, 'DisplayName', names{i});
            end
        
            yline(lowerLimit, '--k', 'Lower Limit', 'HandleVisibility', 'off');
            yline(mean([lowerLimit, upperLimit]), '--k', 'HandleVisibility', 'off');
            yline(upperLimit, '--k', 'Upper Limit', 'HandleVisibility', 'off');
            plot(dates, medianValues, '-k', 'DisplayName', 'Median');
            hold off;
        
            ylabel(yLabelStr);
            legend('Location', 'eastoutside', 'Interpreter', 'none');
            title(titleStr);
            if logScale
                set(gca, 'YScale', 'log');
                set(gca, 'YTick', [0.1 0.2 0.3 0.5 1 2 3 5 10]);
                ylim([0.1, 10]);
            else
                ylim([-20 20]);
            end
        end

