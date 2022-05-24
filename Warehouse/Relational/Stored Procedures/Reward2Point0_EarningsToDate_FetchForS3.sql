/******************************************************************************
Author: Jason Shipp
Created: 04/12/2019
Purpose: 
	- For Reward 3.0 reporting
	- Fetches total earnings do date for Reward 2.0 direct debits (legacy), for uploading to S3, from the Warehouse.Relational.AdditionalCashbackAward table
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Relational.Reward2Point0_EarningsToDate_FetchForS3
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
	CAST(GETDATE() AS date) AS CalculationDate
	, SUM(a.CashbackEarned) AS Earnings_Reward2Point0
	FROM Warehouse.Relational.AdditionalCashbackAward a
	WHERE 
	a.AdditionalCashbackAwardTypeID IN (8,10,25); -- FROM Warehouse.Relational.AdditionalCashbackAwardType WHERE Title LIKE '%Direct Debit%'
	
END