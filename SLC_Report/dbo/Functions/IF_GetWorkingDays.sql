CREATE FUNCTION dbo.IF_GetWorkingDays
/* =============================================================================
10/17/2017 ChrisM    
============================================================================= */
(
    @BegDate DATETIME,
    @EndDate DATETIME
)
RETURNS TABLE WITH SCHEMABINDING AS
RETURN 



	 SELECT
	   WorkingDays = (DATEDIFF(dd, @BegDate, @EndDate) + 1)
				- (DATEDIFF(wk, @BegDate, @EndDate) * 2)
				- (CASE WHEN DATENAME(dw, @BegDate) = 'Sunday' THEN 1 ELSE 0 END)
				- (CASE WHEN DATENAME(dw, @EndDate) = 'Saturday' THEN 1 ELSE 0 END)
 
     

