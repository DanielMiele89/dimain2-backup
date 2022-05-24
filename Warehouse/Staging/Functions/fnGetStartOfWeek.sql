CREATE FUNCTION [Staging].[fnGetStartOfWeek] ( @pInputDate    DATETIME )
RETURNS DATETIME
BEGIN

    SET @pInputDate = CAST(CONVERT(VARCHAR, @pInputDate, 106) AS DATETIME)
    RETURN DATEADD(DD, 1 - DATEPART(DW, @pInputDate), @pInputDate)

END