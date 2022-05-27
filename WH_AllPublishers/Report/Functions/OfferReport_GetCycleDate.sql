
/******************************************************************************
Author	  Hayden Reid
Created	  01/02/2017
Purpose	  Returns the date of the most recent cycle that completed at least 2
		  weeks ago
	  
Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/
CREATE FUNCTION [Report].[OfferReport_GetCycleDate](
    @retStartDate BIT
)
RETURNS DATE
AS
BEGIN

    /**************************************************************************
    
        User Variables
    
    ***************************************************************************/
    
		DECLARE	@CycleStart DATE = '2016-04-28' --SET a cycles start 
			,	@CycleEnd DATE = '2016-05-25' --... and end date (doesn't matter what the dates are as long as they are representative of a cycle)
			,	@TimeLag INT = 13 -- Number of days that a cycle needs to have finished for (set to 13 instead of 2 weeks so that calculations can run on the tuesday)
			,	@CurrDate DATE = GETDATE() -- The date to get the cycle dates for
    
    
    /**************************************************************************
    
        System variables
    
    ***************************************************************************/   

		DECLARE	@Diff INT -- Holds the number of days between the cycle start and end
			,	@StartDate DATE -- The current cycle start
			,	@EndDate DATE -- ... and end date
			,	@Today DATE -- Holds the day that is considered today i.e. The current date - the number of days in the time lag

		SET @Today = DATEADD(DAY, -@TimeLag, @CurrDate)

		SET @Diff = DATEDIFF(DAY, @CycleStart, @CycleEnd)+1

		SET @EndDate = DATEADD(DAY, (DATEDIFF(DAY, @CycleEnd, @Today)/@Diff)*@Diff, @CycleEnd)
		SET @StartDate = DATEADD(DAY, -(@Diff-1), @EndDate)


		IF GETDATE() < '2021-01-12 19:00:00' SET @StartDate = '2020-12-03'	--	DATEADD(DAY, 28 * 1, @StartDate)
		IF GETDATE() < '2021-01-12 19:00:00' SET @EndDate = '2020-12-30'				--	DATEADD(DAY, 28 * 1, @EndDate)
	
		--SELECT @StartDate, @EndDate

		RETURN 
		   CASE @retStartDate 
			  WHEN 1 
			  THEN @StartDate 
		   ELSE 
			  @EndDate 
		   END
END
