

CREATE PROCEDURE [Prototype].[ConsumerTransaction_DD_Update_CJM]
AS
--BEGIN

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#TransactionHistory') IS NOT NULL DROP TABLE #TransactionHistory
SELECT al.[FileID]
		, [RowNum]
		, [OIN]
		, CAST([Narrative] AS VARCHAR(50)) AS [Narrative]
		, [Amount]
		, [Date]
		, [BankAccountID]
		, [FanID]
		, NULL AS [ConsumerCombinationID_DD]
INTO #TransactionHistory
FROM Prototype.OINI_Files f 			
INNER  JOIN Archive_Light.dbo.CBP_DirectDebit_TransactionHistory al			
ON f.FileID = al.FileID 
--	AND f.AddedToMissing = 0 
WHERE f.[FileID] = al.FileID
AND NOT EXISTS (SELECT 1
				FROM [Relational].[ConsumerTransaction_DD] ct
				WHERE al.FileID = ct.FileID 
				AND al.RowNum = ct.RowNum)
AND NOT EXISTS (SELECT 1
				FROM [Staging].[ConsumerTransaction_DD_EntriesMissingFanID] ct
				WHERE al.FileID = ct.FileID
				AND al.RowNum = ct.RowNum)
-- 1,821,921 / 00:01:48

CREATE CLUSTERED INDEX cx_Stuff ON #TransactionHistory (OIN, Narrative)


-- Find CCs
IF OBJECT_ID('tempdb..#Combos') IS NOT NULL DROP TABLE #Combos;
SELECT DISTINCT
		dd.OIN
		, dd.Narrative AS Narrative_RBS
		, vf.Narrative AS Narrative_VF
INTO #Combos
FROM (
	SELECT DISTINCT OIN, Narrative
	FROM #TransactionHistory
) dd
OUTER APPLY (
	SELECT TOP(1) 
		ServiceUserName AS Narrative
	FROM [Staging].[VocaFile_OriginatorRecord_AllEntries] vf
	where dd.OIN = vf.ServiceUserNumber
	ORDER BY StartDate DESC
) vf
-- 43085 / 00:00:06


			
-- insert from #Combos output to #NewCombos
IF OBJECT_ID('tempdb..#NewCombos') IS NOT NULL DROP TABLE #NewCombos
SELECT OIN, Narrative_RBS INTO #NewCombos FROM [Relational].[ConsumerCombination_DD] WHERE 0 = 1

INSERT INTO [Relational].[ConsumerCombination_DD] (OIN, Narrative_RBS, Narrative_VF, BrandID)
	OUTPUT inserted.OIN, inserted.Narrative_RBS INTO #NewCombos
SELECT OIN, Narrative_RBS, Narrative_VF, BrandID = 444 
FROM #Combos
EXCEPT
SELECT OIN, Narrative_RBS, Narrative_VF, BrandID = 444
FROM [Relational].[ConsumerCombination_DD] cc
-- 2093 / 00:00:33

CREATE CLUSTERED INDEX CIX_OIN ON #NewCombos (OIN, Narrative_RBS)


INSERT INTO [Staging].[ConsumerTransaction_DD_EntriesMissingFanID]
SELECT DISTINCT
		[FileID]
		, [RowNum]
		, th.[OIN]
		, [Narrative]
		, [Amount]
		, [Date]
		, [BankAccountID]
		, [FanID]
		, [ConsumerCombinationID_DD] = CASE WHEN nc.OIN IS NULL THEN th.[ConsumerCombinationID_DD] ELSE NULL END
FROM #TransactionHistory th
LEFT JOIN #NewCombos nc
	ON th.OIN = nc.OIN
	AND th.Narrative = nc.Narrative_RBS
-- 1,821,921 / 00:00:39

--UPDATE Prototype.OINI_Files SET AddedToMissing = 1 -- might need a join to #NewCombos


RETURN 0
	












