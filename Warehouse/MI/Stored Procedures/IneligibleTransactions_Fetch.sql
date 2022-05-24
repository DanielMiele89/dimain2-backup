-- =============================================
-- Author:		JEA
-- Create date: 14/08/2013
-- Description:	List of ineligible transactions 
-- for SchemeUpliftTrans population
-- =============================================
CREATE PROCEDURE MI.IneligibleTransactions_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT FileID, RowNum
	FROM MI.TransMatchIneligible

END