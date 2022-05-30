
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Returns the current date for a file

******************************************************************************/

CREATE FUNCTION [Processing].[getCurrentDate]()
RETURNS DATE
AS
BEGIN
	RETURN DATEADD(HH, Processing.getTimeDiff(), GETDATE())

END
