-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MFDD_LIVE_Household] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'Household -- Start', @time OUTPUT

	IF OBJECT_ID('tempdb..#BankAccountUsers') IS NOT NULL DROP TABLE #BankAccountUsers
	SELECT 
		   ic.SourceUID,
		   iba.BankAccountID,
		   HouseholdID = DENSE_RANK() OVER(ORDER BY BankAccountID),
		   f.ID as FanID
	INTO #BankAccountUsers
	FROM SLC_Report.dbo.Fan f 
	INNER JOIN SLC_Report.dbo.IssuerCustomer ic 
		ON f.SourceUID = ic.SourceUID
	INNER JOIN SLC_Report.dbo.IssuerBankAccount iba 
		ON  ic.ID = iba.IssuerCustomerID
	WHERE  f.ClubID IN (132,138)
	GROUP BY ic.SourceUID, iba.BankAccountID, f.ID
	-- (20638503 rows affected) / 00:00:40

	EXEC Prototype.oo_TimerMessage '#BankAccountUsers', @time OUTPUT

	CREATE CLUSTERED INDEX ucx_Stuff ON #BankAccountUsers (HouseholdID,SourceUID) -- 00:00:00
	CREATE INDEX ix_Stuff1 ON #BankAccountUsers (BankAccountID, HouseholdID)

	EXEC Prototype.oo_TimerMessage '#BankAccountUsers -- Index', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY SourceUID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (6,210,415 rows affected) / 00:01:40

	EXEC Prototype.oo_TimerMessage 'Update 1 -> SourceUID', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY BankAccountID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (837,000 rows affected) / 00:00:54

	EXEC Prototype.oo_TimerMessage 'Update 2 -> BankAccountID ', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY SourceUID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (438,061 rows affected) / 00:00:32

	EXEC Prototype.oo_TimerMessage 'Update 3 -> SourceUID', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY BankAccountID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (38,827 rows affected) / 00:00:18

	EXEC Prototype.oo_TimerMessage 'Update 4 -> BankAccountID ', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY SourceUID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (22,049 rows affected) / 00:00:22

	EXEC Prototype.oo_TimerMessage 'Update 5 -> SourceUID', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY BankAccountID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (3,654 rows affected) / 00:00:17

	EXEC Prototype.oo_TimerMessage 'Update 6 -> BankAccountID ', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY SourceUID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (2,144 rows affected) / 00:00:41

	EXEC Prototype.oo_TimerMessage 'Update 7 -> SourceUID', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY BankAccountID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (405 rows affected) / 00:00:23

	EXEC Prototype.oo_TimerMessage 'Update 8 -> BankAccountID ', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY SourceUID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (263 rows affected) / 00:00:20

	EXEC Prototype.oo_TimerMessage 'Update 9 -> SourceUID', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY BankAccountID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (60 rows affected) / 00:00:18

	EXEC Prototype.oo_TimerMessage 'Update 10 -> BankAccountID ', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY SourceUID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (31 rows affected) / 00:00:18

	EXEC Prototype.oo_TimerMessage 'Update 11 -> SourceUID', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY BankAccountID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (11 rows affected) / 00:00:18

	EXEC Prototype.oo_TimerMessage 'Update 12 -> BankAccountID ', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY SourceUID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- (6 rows affected) / 00:00:18

	EXEC Prototype.oo_TimerMessage 'Update 13 -> SourceUID', @time OUTPUT

	;WITH Updater AS (SELECT *, x = MIN(HouseholdID) OVER(PARTITION BY BankAccountID) FROM #BankAccountUsers b)
		   UPDATE Updater SET HouseholdID = x WHERE x < HouseholdID
	-- 0 / 00:00:18

	EXEC Prototype.oo_TimerMessage 'Update 14 -> BankAccountID ', @time OUTPUT

	---------------------------------------------------------------------
	-- Validate

	---- Find Total Counts
	--SELECT	COUNT(DISTINCT SourceUID) AS TotalSourceUID,
	--		COUNT(DISTINCT BankAccountID) AS TotalBankAccountID
	--FROM	#BankAccountUsers

	---- Validate Profiling 1
	--SELECT 'Profile Household Size (SourceUIDs)'
	--SELECT	HouseholdSize,
	--		COUNT(HouseholdID) AS Households_Normal
	--FROM  (
	--		SELECT	HouseholdID,
	--				COUNT(DISTINCT SourceUID) AS HouseholdSize
	--		FROM	#BankAccountUsers
	--		GROUP BY HouseholdID
	--	  ) a
	--GROUP BY HouseholdSize
	--ORDER BY 1

	---- Validate Profiling 2
	--SELECT 'Profile Household Size (BankAccountIDs)'
	--SELECT	HouseholdSize,
	--		COUNT(HouseholdID) AS Households_Normal
	--FROM  (
	--		SELECT	HouseholdID,
	--				COUNT(DISTINCT BankAccountID) AS HouseholdSize
	--		FROM	#BankAccountUsers
	--		GROUP BY HouseholdID
	--	  ) a
	--GROUP BY HouseholdSize
	--ORDER BY 1

	--SELECT 'Validate All SourceUIDs ONLY live in ONE household -- Below we expect an empty list'
	--SELECT	SourceUID
	--FROM	#BankAccountUsers
	--GROUP BY SourceUID
	--HAVING 1 < COUNT(DISTINCT HouseholdID)

	--SELECT 'Validate All BankAccountIDs ONLY live in ONE household -- Below we expect an empty list'
	--SELECT	BankAccountID
	--FROM	#BankAccountUsers
	--GROUP BY BankAccountID
	--HAVING 1 < COUNT(DISTINCT HouseholdID)

	IF OBJECT_ID('Warehouse.InsightArchive.MFDD_Household') IS NOT NULL DROP TABLE Warehouse.InsightArchive.MFDD_Household
	CREATE TABLE Warehouse.InsightArchive.MFDD_Household
		(
			ID INT PRIMARY KEY IDENTITY(1,1),
			SourceUID VARCHAR(20) NOT NULL,
			BankAccountID INT NOT NULL,
			HouseholdID INT NOT NULL,
			FanID INT NOT NULL
		)

	INSERT INTO Warehouse.InsightArchive.MFDD_Household
		SELECT *
		FROM #BankAccountUsers

	EXEC Prototype.oo_TimerMessage 'Output to : Warehouse.InsightArchive.MFDD_Household ', @time OUTPUT

	-- Add some indexes so that the server doesn't cry
	CREATE INDEX cix_SourceUID ON Warehouse.InsightArchive.MFDD_Household (SourceUID)
	CREATE INDEX cix_HouseholdID_SourceUID ON Warehouse.InsightArchive.MFDD_Household (HouseholdID) INCLUDE (SourceUID)

	EXEC Prototype.oo_TimerMessage 'Index : Warehouse.InsightArchive.MFDD_Household ', @time OUTPUT

	EXEC Prototype.oo_TimerMessage 'Household -- End', @time OUTPUT

END
