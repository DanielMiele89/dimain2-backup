

-- *********************************************
-- Author: Suraj Chahal
-- Create date: 04/11/2014
-- Description: Shows any customers who has a Pending balance less than Available
-- *********************************************
CREATE PROCEDURE [Staging].[SSRS_R0054_ClubCashPending_LessThan_Available]
			
AS
BEGIN
	SET NOCOUNT ON;


SELECT	FanID,
	ClubCashPending,
	ClubCashAvailable,
	[Date] as TodaysDate
FROM Warehouse.Staging.Customer_CashbackBalances
WHERE	[Date] = CAST(GETDATE() AS DATE)
	AND ClubCashPending < ClubCashAvailable

END