

-- =============================================
-- Author:		JEA
-- Create date: 05/12/2016
-- Description:	Gets the last specified weekday
-- =============================================
CREATE FUNCTION [MI].[GetLastOrCurrentWeekday] 
(
	@WeekDayName VARCHAR(50), @StartingDate DATE
)
RETURNS DATE
AS
BEGIN

	/*
	NB: DO NOT USE THIS FUNCTION AS PART OF A SET BASED OPERATION.  IT WILL NOT SCALE.  USE ONLY TO SET VARIABLES, PARAMETERS OR SIMILAR.
	*/

	DECLARE @RtnDate DATE, @RtnDayName VARCHAR(50)
	
	SET @WeekDayName = UPPER(@WeekDayName)
	SET @RtnDate = @StartingDate
	SET @RtnDayName = UPPER(DATENAME(WEEKDAY, @RtnDate))

	WHILE @RtnDayName != @WeekDayName
    BEGIN
		SET @RtnDate = DATEADD(DAY, -1, @RtnDate)
		SET @RtnDayName = UPPER(DATENAME(WEEKDAY, @RtnDate))
	END

	RETURN @RtnDate

END