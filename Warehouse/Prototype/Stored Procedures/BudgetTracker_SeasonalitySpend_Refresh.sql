-- =============================================
-- Author:		Sam Weber
-- Create date: 07/10/2021
-- Description:	<Including DD data to the budget tracker seasonality,,>
-- =============================================
CREATE PROCEDURE [Prototype].[BudgetTracker_SeasonalitySpend_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MinDate DATE, @MaxDate DATE

	SELECT @MinDate = MIN(DayDate), @MaxDate = MAX(DayDate)
	FROM Prototype.BudgetTracker_DayNumber

    CREATE TABLE #Brands (BrandID SMALLINT PRIMARY KEY)

	INSERT INTO #Brands(BrandID)
	SELECT BrandID
	FROM Prototype.BudgetTracker_AMYearlyInput
	UNION
	SELECT BrandID
	FROM Prototype.BudgetTracker_AMCampaignInput
	EXCEPT
	SELECT DISTINCT BrandID
	FROM Prototype.BudgetTracker_SeasonSpend

	CREATE TABLE #Combos(ConsumerCombinationID INT PRIMARY KEY, BrandID SMALLINT NOT NULL)

	INSERT INTO #Combos(ConsumerCombinationID, BrandID)
	SELECT c.ConsumerCombinationID, c.BrandID
	FROM Relational.ConsumerCombination c
	INNER JOIN #Brands b ON c.BrandID = b.BrandID
	WHERE c.BrandID NOT IN (SELECT BrandID FROM Relational.Partner WHERE TransactionTypeID = 2)
	

	CREATE TABLE #CombosDD(ConsumerCombinationID INT PRIMARY KEY, BrandID SMALLINT NOT NULL)

	INSERT INTO #CombosDD(ConsumerCombinationID, BrandID)
	SELECT	ConsumerCombination_DD as ConsumerCombinationID, C.BrandID
	FROM Relational.ConsumerCombination_DD C
	INNER JOIN #Brands b ON c.BrandID = b.BrandID
	WHERE c.BrandID IN (SELECT BrandID FROM Relational.Partner WHERE TransactionTypeID = 2)


	INSERT INTO Prototype.BudgetTracker_SeasonSpend(BrandID, DayID, DaySpend)
	SELECT t.BrandID, d.DayID, t.DaySpend
	FROM
	(
		SELECT c.BrandID, ct.Trandate, SUM(ct.Amount) AS DaySpend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN #Combos c on ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @MinDate AND @MaxDate
		GROUP BY c.BrandID, ct.TranDate
		UNION
		SELECT c.BrandID, ct.Trandate, SUM(ct.Amount) AS DaySpend
		FROM Relational.ConsumerTransaction_DD ct WITH (NOLOCK)
		INNER JOIN #CombosDD c on ct.ConsumerCombinationID_DD = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @MinDate AND @MaxDate
		GROUP BY c.BrandID, ct.TranDate
	) t
	INNER JOIN Prototype.BudgetTracker_DayNumber d ON t.TranDate = d.DayDate
	WHERE d.ID BETWEEN 1 AND 364

END



