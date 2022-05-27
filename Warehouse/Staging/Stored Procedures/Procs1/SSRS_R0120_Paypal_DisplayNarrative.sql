


-- *****************************************************************************************************
-- Author: Ijaz Amjad
-- Create date: 15/04/2016
-- Description: Displays report.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0120_Paypal_DisplayNarrative](
			@TranAmount int)
						
			
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @TA int

SET @TA = @TranAmount

/******************************************************************************
** Pulls back Paypal narratives that have more than XXXXX Transaction amount **
******************************************************************************/
IF OBJECT_ID ('Staging.R_0120_Paypal_StatsLastYear') IS NOT NULL DROP TABLE Staging.R_0120_Paypal_StatsLastYear
SELECT	ppt.*,
		mcc.MCCDesc
INTO	Staging.R_0120_Paypal_StatsLastYear
FROM	Staging.R_0120_Paypal_PopulatingTable ppt
INNER JOIN Relational.MCCList mcc
	ON	ppt.MCCID = mcc.MCCID
--WHERE	TransactionAmount > 20000
ORDER BY Transactions DESC


SELECT	*
FROM	Staging.R_0120_Paypal_StatsLastYear
WHERE	Narrative NOT IN ('PAYPAL%','PAYPAL')
	AND TransactionAmount > @TA
ORDER BY TransactionAmount DESC

END
