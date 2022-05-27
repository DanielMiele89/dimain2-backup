-- =============================================
-- Author:		JEA
-- Create date: 21/06/2013
-- Description:	Clears down SchemeUpliftTrans
-- =============================================
CREATE PROCEDURE [Relational].[SchemeUpliftTrans_Fetch] 
	
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
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN MI.SchemeTransBrandMID B ON CT.BrandMIDID = B.BrandMIDID
	INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
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
	--FROM Relational.CardTransactionRainbow ct WITH (NOLOCK)
	--INNER JOIN MI.SchemeTransBrandMID B ON CT.BrandMIDID = B.BrandMIDID
	--INNER JOIN MI.SchemeTransCINID C ON CT.CINID = C.CINID
	--WHERE ct.TranDate >= '2012-01-02' --hardcoded start of data extraction
	) c
	LEFT OUTER JOIN Relational.Partner_CBPDates p on c.PartnerID = p.PartnerID
		AND c.TranDate >= p.Scheme_StartDate and (p.Scheme_EndDate IS NULL OR C.TranDate <= P.Scheme_EndDate)
	
	ORDER BY FileID, RowNum
    
END