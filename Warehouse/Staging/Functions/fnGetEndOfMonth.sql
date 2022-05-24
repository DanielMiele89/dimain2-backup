

CREATE FUNCTION [Staging].[fnGetEndOfMonth] ( @MyDate    DATETIME )
RETURNS DATETIME
AS
BEGIN

    RETURN DATEADD("ss", -1, DATEADD("m", 1, Staging.fnGetStartOfMonth(@MyDate)))
END