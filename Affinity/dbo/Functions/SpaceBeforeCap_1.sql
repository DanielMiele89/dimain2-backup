/******************************************************************************
https://stackoverflow.com/a/60941286
******************************************************************************/

CREATE FUNCTION dbo.SpaceBeforeCap
    (@examine nvarchar(max))
returns nvarchar(max)
as
begin

DECLARE @index as INT

SET @index = PatIndex( '%[^ ][A-Z]%', @examine COLLATE Latin1_General_BIN)
WHILE @index > 0 BEGIN

    SET @examine = SUBSTRING(@examine, 1, @index) + ' ' + SUBSTRING(@examine, @index + 1, LEN(@examine))
    SET @index = PatIndex( '%[^ ][A-Z]%', @examine COLLATE Latin1_General_BIN)

END

RETURN LTRIM(@examine)

end