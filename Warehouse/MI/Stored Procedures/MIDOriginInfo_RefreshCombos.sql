-- =============================================
-- Author:		JEA
-- Create date: 28/05/2014
-- Description:	Retrieves MID Origin info for MOM process
-- =============================================
CREATE PROCEDURE [MI].[MIDOriginInfo_RefreshCombos] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @TranFrom DATE
	SET @TranFrom  = DATEADD(MONTH, -13, GETDATE())

	TRUNCATE TABLE MI.MOMCombinationLastTrans
	TRUNCATE TABLE MI.MOMCombinationAcquirer

	CREATE TABLE #MOMCombinationCandidate(ConsumerCombinationID INT PRIMARY KEY)

	INSERT INTO #MOMCombinationCandidate(ConsumerCombinationID)
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination
	WHERE LocationCountry = 'GB'

	INSERT INTO MI.MOMCombinationLastTrans(ConsumerCombinationID, LastTranDate)
	SELECT m.ConsumerCombinationID, MAX(ct.TranDate) AS LastTranDate
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #MOMCombinationCandidate m ON ct.ConsumerCombinationID = m.ConsumerCombinationID
	WHERE ct.TranDate > @TranFrom
	GROUP BY m.ConsumerCombinationID

END