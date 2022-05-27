

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 23/07/2015
-- Description: Shows MIDs for a brands which have received trans in last 6 months
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0091_BrandedMIDs_TransInLast6Months] (
				@BrandID INT)
									
AS
BEGIN
	SET NOCOUNT ON;


IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT	ConsumerCombinationID,
	cc.BrandID,
	b.BrandName,
	MID,
	Narrative,
	LocationCountry
INTO #CCIDs
FROM Warehouse.Relational.ConsumerCombination cc
INNER JOIN Warehouse.Relational.Brand b
	ON cc.BrandID = b.BrandID
WHERE cc.BrandID = @BrandID
--(98 row(s) affected)



SELECT	BrandID,
	BrandName,
	MID,
	Narrative,
	LocationCountry,
	CASE
		WHEN ct.CardholderPresentData = 5 THEN 'Online'
		WHEN ct.CardholderPresentData = 9 THEN 'Unknown'
		ELSE 'Offline'
	END as TransactionChannel,
	COUNT(1) as TransactionCount,
	MIN(TranDate) as FirstTransaction,
	MAX(TranDate) as LastTransaction
FROM Warehouse.Relational.ConsumerTransaction ct (NOLOCK)
INNER JOIN #CCIDs cc
	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
GROUP BY BrandID,BrandName,MID,Narrative,LocationCountry,
	CASE
		WHEN ct.CardholderPresentData = 5 THEN 'Online'
		WHEN ct.CardholderPresentData = 9 THEN 'Unknown'
		ELSE 'Offline'
	END
HAVING MAX(TranDate) > DATEADD(MM,-6,CAST(GETDATE() AS DATE))


END