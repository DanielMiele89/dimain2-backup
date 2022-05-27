-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE InsightArchive.SUTTest
	
AS
BEGIN

	SET NOCOUNT ON;

    	SELECT c.FileID
		, c.RowNum
		, c.Amount
		, c.FanID
		, c.OutletID
		, c.PartnerID
		, c.CardholderPresentData
		, c.IsOnline
		, c.TranDate
		, c.ClubID
		, c.CompositeID
		, CAST(CASE WHEN p.PartnerID IS NULL THEN 0 ELSE 1 END AS bit) AS IsRetailReport
		, c.PaymentTypeID
	FROM
	(
    SELECT ct.FileID
		, ct.RowNum
		, ct.Amount
		, C.FanID
		, b.OutletID
		, b.PartnerID
		, ct.CardholderPresentData
		, b.IsOnline
		, ct.TranDate
		, c.ClubID
		, c.CompositeID
		, ct.PaymentTypeID
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN MI.SchemeTransCombination B ON CT.ConsumerCombinationID = B.ConsumerCombinationID
	INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
	AND ct.PostStatusID IN (1,5,6,7)
	
	UNION ALL

	SELECT ct.FileID
		, ct.RowNum
		, ct.Amount
		, C.FanID
		, b.OutletID
		, b.PartnerID
		, ct.CardholderPresentData
		, b.IsOnline
		, ct.TranDate
		, c.ClubID
		, c.CompositeID
		, ct.PaymentTypeID
	FROM Relational.ConsumerTransactionHolding ct WITH (NOLOCK)
	INNER JOIN MI.SchemeTransCombination B ON CT.ConsumerCombinationID = B.ConsumerCombinationID
	INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
	AND ct.PostStatusID IN (1,5,6,7)

	UNION ALL

	SELECT ct.FileID
		, ct.RowNum
		, ct.Amount
		, C.FanID
		, b.OutletID
		, b.PartnerID
		, ct.CardholderPresentData
		, b.IsOnline
		, ct.TranDate
		, c.ClubID
		, c.CompositeID
		, ct.PaymentTypeID
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN MI.SchemeTransCombinationTranDate B ON CT.ConsumerCombinationID = B.ConsumerCombinationID AND ct.TranDate BETWEEN b.TranStartDate AND b.TranEndDate
	INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
	AND ct.PostStatusID IN (1,5,6,7)
	
	UNION ALL

	SELECT ct.FileID
		, ct.RowNum
		, ct.Amount
		, C.FanID
		, b.OutletID
		, b.PartnerID
		, ct.CardholderPresentData
		, b.IsOnline
		, ct.TranDate
		, c.ClubID
		, c.CompositeID
		, ct.PaymentTypeID
	FROM Relational.ConsumerTransactionHolding ct WITH (NOLOCK)
	INNER JOIN MI.SchemeTransCombinationTranDate B ON CT.ConsumerCombinationID = B.ConsumerCombinationID AND ct.TranDate BETWEEN b.TranStartDate AND b.TranEndDate
	INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
	AND ct.PostStatusID IN (1,5,6,7)

	) c
	LEFT OUTER JOIN Relational.Partner_CBPDates p on c.PartnerID = p.PartnerID
		AND c.TranDate >= p.Scheme_StartDate and (p.Scheme_EndDate IS NULL OR C.TranDate <= P.Scheme_EndDate)
	
	ORDER BY FileID, RowNum
END
