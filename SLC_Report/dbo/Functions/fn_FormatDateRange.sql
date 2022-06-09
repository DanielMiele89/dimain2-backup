
CREATE FUNCTION [dbo].[fn_FormatDateRange] (@StartDate datetime, @EndDate datetime)
RETURNS varchar(256)
AS  
BEGIN 

	return
		case when @startdate = dbo.fn_truncatedate(@enddate) then 
			''
		else
			dbo.fn_formatdate(@startdate,'d') + 
			case when datepart(year, @startdate) = datepart(year, @enddate)
				and   datepart(month,@startdate) = datepart(month,@enddate) 
				then '' else dbo.fn_formatdate(@startdate,' mmmm')
			end +
			case when datepart(year, @startdate) = datepart(year, @enddate)
				then '' else dbo.fn_formatdate(@startdate,' yyy')
			end +
			'-'
		end + dbo.fn_formatdate(@enddate,'d mmmm yyy')

END







