/******************************************************************************
Author	  Jason Shipp
Created	  27/06/2018
Purpose	  Adds the desired number of working days to a date, excluding weekends and bank holidays
	  
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE FUNCTION [MI].[AddWorkingDays](
    @OriginDate DATE 
	, @WorkingDaysToAdd INT
)
RETURNS DATE

AS
BEGIN

	DECLARE @Count INT = 0 -- Loop counter
	DECLARE @OutputDate DATE -- Loop variable

	SET @OutputDate = @OriginDate -- Start loop at the origin date
	
	WHILE @Count <= @WorkingDaysToAdd
		BEGIN 

			IF @Count < @WorkingDaysToAdd
			BEGIN 
				SET @OutputDate = DATEADD(day, 1, @OutputDate) 
			END
       
			ELSE
			BEGIN 
				BREAK 
			END

			IF 
				DATENAME(dw, @OutputDate) NOT IN ('Saturday', 'Sunday') -- Only add to the count if a weekday
				AND @OutputDate NOT IN (SELECT DATE FROM MI.UK_Bank_Holidays) -- Only add to the count if not a bank holiday

			BEGIN 
				SET @Count = @Count + 1 
			END 
		
		END;
	
	RETURN CAST(@OutputDate AS DATE);
   
END