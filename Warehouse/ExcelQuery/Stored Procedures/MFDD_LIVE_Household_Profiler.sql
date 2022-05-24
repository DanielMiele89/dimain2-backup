-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.MFDD_LIVE_Household_Profiler
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'Household Profiler -- Start', @time OUTPUT

	---------------------------------------------------------------------
	-- Validate

	-- Find Total Counts
	SELECT	COUNT(DISTINCT SourceUID) AS TotalSourceUID,
			COUNT(DISTINCT BankAccountID) AS TotalBankAccountID
	FROM	Warehouse.InsightArchive.MFDD_Household

	-- Validate Profiling 1
	SELECT 'Profile Household Size (SourceUIDs)'
	SELECT	HouseholdSize,
			COUNT(HouseholdID) AS Households_Normal
	FROM  (
			SELECT	HouseholdID,
					COUNT(DISTINCT SourceUID) AS HouseholdSize
			FROM	Warehouse.InsightArchive.MFDD_Household
			GROUP BY HouseholdID
		  ) a
	GROUP BY HouseholdSize
	ORDER BY 1

	-- Validate Profiling 2
	SELECT 'Profile Household Size (BankAccountIDs)'
	SELECT	HouseholdSize,
			COUNT(HouseholdID) AS Households_Normal
	FROM  (
			SELECT	HouseholdID,
					COUNT(DISTINCT BankAccountID) AS HouseholdSize
			FROM	Warehouse.InsightArchive.MFDD_Household
			GROUP BY HouseholdID
		  ) a
	GROUP BY HouseholdSize
	ORDER BY 1

	SELECT 'Validate All SourceUIDs ONLY live in ONE household -- Below we expect an empty list'
	SELECT	SourceUID
	FROM	Warehouse.InsightArchive.MFDD_Household
	GROUP BY SourceUID
	HAVING 1 < COUNT(DISTINCT HouseholdID)

	SELECT 'Validate All BankAccountIDs ONLY live in ONE household -- Below we expect an empty list'
	SELECT	BankAccountID
	FROM	Warehouse.InsightArchive.MFDD_Household
	GROUP BY BankAccountID
	HAVING 1 < COUNT(DISTINCT HouseholdID)

	EXEC Prototype.oo_TimerMessage 'Household Profiler - End', @time OUTPUT

END