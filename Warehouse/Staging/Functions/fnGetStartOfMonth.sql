
CREATE FUNCTION [Staging].[fnGetStartOfMonth] ( @MyDate    DATETIME )
RETURNS DATETIME
AS
BEGIN

    RETURN CONVERT(DATETIME,'1-' + CAST(datepart("mm", @MyDate) AS VARCHAR(2)) + '-' + CAST(datepart("yyyy", @MyDate) AS CHAR(4)),103)
END