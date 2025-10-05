function Table = filterIS(Table, ISdic, ISKey)
            for col = Table.Properties.VariableNames
                if strcmp(col{1}, 'datetime_aq'), continue; end
                if ~ISdic(col{1}).(ISKey)
                    Table.(col{1}) = [];
                end
            end

end

