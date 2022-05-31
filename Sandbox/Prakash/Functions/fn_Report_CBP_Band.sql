create function [Prakash].fn_Report_CBP_Band(@cash money)
returns nvarchar(256)
as
begin
    declare @ret nvarchar(256)
    set @ret=case 
          when isnull(@cash,0) <= 0 then '  £ 0.00'
          when @cash <  0.5 then '< £ 0.50'
          when @cash <  1   then '< £ 1.00'
          when @cash <  1.5 then '< £ 1.50'
          when @cash <  2   then '< £ 2.00'
          when @cash <  3   then '< £ 3.00'
          when @cash <  4   then '< £ 4.00'
          when @cash <  5   then '< £ 5.00'
          when @cash <  6   then '< £ 6.00'
          when @cash <  7   then '< £ 7.00'
          when @cash <  8   then '< £ 8.00'
          when @cash <  9   then '< £ 9.00'
          when @cash < 10   then '< £10.00'
          when @cash < 15   then '< £15.00'
          when @cash < 20   then '< £20.00'
          when @cash < 25   then '< £25.00'
          when @cash < 50   then '< £50.00'
          when @cash < 100 then '< £100.00'
          else '> £100.01'
          end
    return @ret
end
