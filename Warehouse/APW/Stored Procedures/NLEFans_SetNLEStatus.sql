-- =============================================
-- Author:		JEA
-- Create date: 02/08/2016
-- Description:	Sets NLE value on APW.NLEFans
-- =============================================
CREATE PROCEDURE [APW].[NLEFans_SetNLEStatus] 
(
	@RetailerID INT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @BrandID SMALLINT, @YearDate DATE, @LapseDate DATE, @LapseMonths INT, @MonthDate Date

	SET @MonthDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))

	SELECT @LapseMonths = Months FROM Stratification.LapsersDefinition WHERE PartnerID = @RetailerID

	SET @YearDate = DATEFROMPARTS(YEAR(@MonthDate), 1, 1)
	SET @LapseDate = DATEADD(MONTH, -@LapseMonths, @YearDate)

	--SET CINID
	UPDATE n SET CINID = c.CINID
	FROM APW.NLEFans n
	INNER JOIN Relational.Customer cu on n.FanID = cu.FanID
	INNER JOIN Relational.CINList c on cu.SourceUID = c.CIN

	CREATE TABLE #combos(ConsumerCombinationID INT PRIMARY KEY)

	SELECT @BrandID = BrandID 
	FROM Relational.[Partner]
	WHERE PartnerID = @RetailerID

	INSERT INTO #combos(ConsumerCombinationID)
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination
	WHERE BrandID = @BrandID

	--set date values

	UPDATE N
	SET LastBPDTrans = B.TranDate
	FROM APW.NLEFans n
	INNER JOIN
	(
		SELECT N.cinid, MAX(CT.trandate) as trandate
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN #combos co on ct.ConsumerCombinationID = co.ConsumerCombinationID
		INNER JOIN APW.NLEFans n ON ct.CINID = n.CINID
		WHERE ct.TranDate < @YearDate
		GROUP BY N.CINID
	) b ON n.CINID = b.CINID

	UPDATE N
	SET LastPTTrans = B.TranDate
	FROM APW.NLEFans n
	INNER JOIN
	(
		SELECT pt.FanID, MAX(pt.TransactionDate) as trandate
		FROM Relational.partnertrans pt WITH (NOLOCK)
		INNER JOIN APW.NLEFans n ON pt.fanid = n.fanid
		WHERE pt.TransactionDate < @YearDate
		AND pt.PartnerID = @RetailerID
		GROUP BY pt.FanID
	) b on n.FanID = b.FanID

	--SET LastTrans
	UPDATE APW.NLEFans SET LastTrans = LastBPDTrans

	UPDATE APW.NLEFans SET LastTrans = LastPTTrans
	WHERE LastPTTrans IS NOT NULL
	AND (LastTrans IS NULL OR LastTrans < LastPTTrans)

	--SET NLE value

	UPDATE APW.NLEFans SET NLE = 'N'
	WHERE LastTrans IS NULL

	UPDATE APW.NLEFans SET NLE = 'L' 
	WHERE LastTrans < @LapseDate
	AND NLE IS NULL

	UPDATE APW.NLEFans SET NLE = 'E'
	WHERE NLE IS NULL

	DROP TABLE #combos

END