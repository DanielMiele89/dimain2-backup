-- =============================================
-- Author:		JEA
-- Create date: 18/02/2015
-- Description:	Fetches combinations to determine 
-- if a retailer is trackable by Reward
-- =============================================
CREATE PROCEDURE MI.RetailerTrackingAcquirer_SetValues
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE, @TransactedDate DATE

	SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @StartDate = DATEADD(YEAR, -1, @EndDate)
	SET @EndDate = DATEADD(DAY, -1, @EndDate)

	SET @TransactedDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 20))

	IF DATENAME(WEEKDAY, @TransactedDate) = 'Sunday'
	BEGIN
		SET @TransactedDate = DATEADD(DAY, -1, @TransactedDate)
	END

	UPDATE r SET AnnualSpend = c.Spend
	FROM MI.RetailerTrackingAcquirer r
	INNER JOIN
	(
		SELECT r.ConsumerCombinationID, SUM(Amount) AS Spend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN MI.RetailerTrackingAcquirer r ON ct.ConsumerCombinationID = r.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
		GROUP BY r.ConsumerCombinationID
	) c ON r.ConsumerCombinationID = c.ConsumerCombinationID

	UPDATE r SET TransactedOnDate = 1, TransactedDate = @TransactedDate
	FROM MI.RetailerTrackingAcquirer r
	INNER JOIN
	(
		SELECT DISTINCT r.ConsumerCombinationID
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN MI.RetailerTrackingAcquirer r ON ct.ConsumerCombinationID = r.ConsumerCombinationID
		WHERE ct.TranDate = @TransactedDate
	) c ON r.ConsumerCombinationID = c.ConsumerCombinationID

END