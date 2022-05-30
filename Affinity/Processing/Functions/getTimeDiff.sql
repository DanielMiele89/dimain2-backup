
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Returns the number of hours to subtract from a datetime to get 
				the file date
				
				NOTE: It is currently set to -12, this means, that it will not 
				become the next day until 12pm i.e. midday instead of 12am i.e. midnight


******************************************************************************/
CREATE FUNCTION [Processing].[getTimeDiff]()
RETURNS INT
AS
BEGIN
	RETURN -12
END