% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function plotDeviceMetric(dataTable, lowerLimit, upperLimit, yLabelStr, titleStr, markers, logScale)
%PLOTDEVICEMETRIC  Plot a device performance metric with limits and median.
%
%   plotDeviceMetric(dataTable, lowerLimit, upperLimit, yLabelStr, titleStr, markers, logScale)
%   Plots time series data from a table, including individual series,
%   median values, and control limits.
%
%   Inputs:
%     dataTable  - Table containing a datetime column 'datetime_aq' and
%                  metric columns starting from column 2
%     lowerLimit - Lower control limit (numeric)
%     upperLimit - Upper control limit (numeric)
%     yLabelStr  - Y-axis label (string or char)
%     titleStr   - Plot title (string or char)
%     markers    - Cell array of line/marker styles
%     logScale   - Logical flag to enable logarithmic y-axis (optional)
%
%   Behavior:
%     - Automatically selects subplot position based on titleStr
%     - Plots all series, median line, and limit lines
%     - Uses logarithmic scaling for intensity-type metrics if enabled
%

    if nargin < 7
        logScale = false;
    end

    % Select subplot based on metric title
    subplot(3, 1, find(strcmp( ...
        titleStr, ...
        { ...
            'Internal Standard Retention Time Deviation', ...
            'Internal Standard Mass Accuracy', ...
            'Internal Standard Intensity' ...
        } ...
    )));
    hold on;

    % Extract data
    dates  = datetime(dataTable.datetime_aq, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    series = dataTable{:, 2:end};
    names  = dataTable.Properties.VariableNames(2:end);

    % Compute median across series
    medianValues = median(series, 2, 'omitnan');

    % Plot individual series
    for i = 1:size(series, 2)
        plot(dates, series(:, i), markers{i}, 'DisplayName', names{i});
    end

    % Plot control limits and median
    yline(lowerLimit, '--k', 'Lower Limit', 'HandleVisibility', 'off');
    yline(mean([lowerLimit, upperLimit]), '--k', 'HandleVisibility', 'off');
    yline(upperLimit, '--k', 'Upper Limit', 'HandleVisibility', 'off');
    plot(dates, medianValues, '-k', 'DisplayName', 'Median');

    hold off;

    % Axis labels and title
    ylabel(yLabelStr);
    title(titleStr);
    legend('Location', 'eastoutside', 'Interpreter', 'none');

    % Axis scaling
    if logScale
        set(gca, 'YScale', 'log');
        set(gca, 'YTick', [0.1 0.2 0.3 0.5 1 2 3 5 10]);
        ylim([0.1, 10]);
    else
        ylim([-20 20]);
    end
end
