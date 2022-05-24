


-- *****************************************************************************************************
-- Author: Ijaz Amjad
-- Create date: 15/04/2016
-- Description: Populating table with ALL PayPal Narratives.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0120_Paypal_PopulatingTable]
						
			
AS
BEGIN
	SET NOCOUNT ON;


/******************************************************************************
**************** Populating table with ALL PayPal Narratives ******************
******************************************************************************/
IF OBJECT_ID ('tempdb..Staging.R_0120_Paypal_PopulatingTable') IS NOT NULL DROP TABLE Staging.R_0120_Paypal_PopulatingTable
SELECT	cc.BrandID,
		cc.Narrative,
		cc.MCCID,
		COUNT(1) Transactions,
		SUM(Amount) as TransactionAmount
INTO	Staging.R_0120_Paypal_PopulatingTable
FROM	Relational.ConsumerCombination cc (NOLOCK) 
INNER JOIN Relational.ConsumerTransaction ct (NOLOCK)
	ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	cc.BrandID = 943
	AND ct.TranDate BETWEEN DATEADD(YEAR,-1,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE))))  
			AND DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE))
GROUP BY cc.BrandID, cc.Narrative, cc.MCCID
--HAVING COUNT(1) > 50


SELECT	ppt.*,
		mcc.MCCDesc
FROM	Staging.R_0120_Paypal_PopulatingTable ppt
INNER JOIN Relational.MCCList mcc
	ON	ppt.MCCID = mcc.MCCID
ORDER BY TransactionAmount DESC

END
