

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 15/09/2015
-- Description: DD Report 
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0103_DirectDebit_Exceptions_Report]
									
AS
BEGIN
	SET NOCOUNT ON;


SELECT	Warehouse.Staging.fnGetStartOfMonth(TransactionDate) as SMonth,
	ClubID,
	FanID,
	CIN,
	OIN,
	Narrative,
	COUNT(1) as Transactions,
	SUM(TransactionAmount) as TransactionAmount
FROM Warehouse.Staging.R0103_DirectDebitExceptions
GROUP BY Warehouse.Staging.fnGetStartOfMonth(TransactionDate), ClubID,FanID,CIN,OIN,Narrative


END