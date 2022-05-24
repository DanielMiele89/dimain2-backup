-- =============================================
-- Author:		JEA
-- Create date: 18/08/2015
-- Description:	Retrieves data for SchemeUpliftTrans
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_SignedOff_Fetch]

AS
BEGIN
	
	SET NOCOUNT ON;
    

	--SELECT c.FileID
	--	, c.RowNum
	--	, c.Amount
	--	, c.FanID
	--	, c.OutletID
	--	, c.PartnerID
	--	, c.CardholderPresentData
	--	, c.IsOnline
	--	, c.TranDate
	--	, c.ClubID
	--	, c.CompositeID
	--	, CAST(CASE WHEN p.PartnerID IS NULL THEN 0 ELSE 1 END AS bit) AS IsRetailReport
	--	, c.PaymentTypeID
	--	, CAST(1 AS BIT) AS ExcludeTime
	--FROM
	--(
 --   SELECT ct.FileID
	--	, ct.RowNum
	--	, ct.Amount
	--	, C.FanID
	--	, b.OutletID
	--	, b.PartnerID
	--	, ct.CardholderPresentData
	--	, b.IsOnline
	--	, ct.TranDate
	--	, c.ClubID
	--	, c.CompositeID
	--	, ct.PaymentTypeID
	--FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	--INNER JOIN MI.SchemeTransCombination B ON CT.ConsumerCombinationID = B.ConsumerCombinationID
	--INNER JOIN MI.SchemeUpliftTrans_RetailOutletSignedOff o ON b.OutletID = o.OutletID
	--INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	--WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
	--AND ct.PostStatusID IN (1,5,6,7)
	
	--UNION

	--SELECT ct.FileID
	--	, ct.RowNum
	--	, ct.Amount
	--	, C.FanID
	--	, b.OutletID
	--	, b.PartnerID
	--	, ct.CardholderPresentData
	--	, b.IsOnline
	--	, ct.TranDate
	--	, c.ClubID
	--	, c.CompositeID
	--	, ct.PaymentTypeID
	--FROM Relational.ConsumerTransactionHolding ct WITH (NOLOCK)
	--INNER JOIN MI.SchemeTransCombination B ON CT.ConsumerCombinationID = B.ConsumerCombinationID
	--INNER JOIN MI.SchemeUpliftTrans_RetailOutletSignedOff o ON b.OutletID = o.OutletID
	--INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	--WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
	--AND ct.PostStatusID IN (1,5,6,7)
	--) c
	--LEFT OUTER JOIN Relational.Partner_CBPDates p on c.PartnerID = p.PartnerID
	--	AND c.TranDate >= p.Scheme_StartDate and (p.Scheme_EndDate IS NULL OR C.TranDate <= P.Scheme_EndDate)
	
	--ORDER BY FileID, RowNum

	SELECT s.FileID
		, s.RowNum
		, s.Amount
		, s.AddedDate
		, s.FanID
		, s.OutletID
		, s.PartnerID
		, s.IsOnline
		, s.weekid
		, s.ExcludeTime
		, s.TranDate
		, s.IsRetailReport
		, s.PaymentTypeID
	FROM MI.SchemeUpliftTrans_Stage s WITH (NOLOCK)
	INNER JOIN MI.SchemeUpliftTrans_RetailOutletSignedOff o ON s.OutletID = o.OutletID
    
END