

CREATE FUNCTION [dbo].[fn_FormatTimeSpan] (@StartDate datetime, @EndDate datetime)
RETURNS varchar(20)
AS  
BEGIN
	-- Joe Simpson, 1 July 2010

	declare @Days int
	set @Days=0

	while datediff(ms,@StartDate,@EndDate) >= 24*60*60*1000
	begin
		set @StartDate=dateadd(d,1,@StartDate)
		set @Days=@Days+1
	end

	declare @Diff datetime, @H int, @M int, @S int
	set @Diff=dateadd(s,datediff(s,@StartDate,@EndDate),'20000101')

	select @H = DATEPART(hh, @Diff) + @Days*24, @M = datepart(n, @Diff), @S = datepart(s, @Diff)

	return cast(@H + @Days*24 as varchar) + ':' + right('0' + cast(@M as varchar), 2) + ':'  + right('0' + cast(@S as varchar), 2)

END






