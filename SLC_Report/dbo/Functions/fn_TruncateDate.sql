CREATE FUNCTION [dbo].[fn_TruncateDate] (@Date datetime)
RETURNS datetime
AS  
BEGIN
	return DATEADD(d, DATEDIFF(d, 0, @Date), 0)
--	if @Date is null return null
--	return(cast(dbo.fn_formatdate(@Date,'dd-mmm-yyy') as datetime))
END