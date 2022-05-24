CREATE PROCEDURE [Staging].[SchemeTransList_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @StartMatchID INT

	SELECT @StartMatchID = MAX(MatchID) FROM Staging.SchemeCashbackRateInfo

	CREATE TABLE #CBPMatch(MatchID Int not null, FanID Int Not Null, PartnerID Int Not Null, TransactionDate DATE NOT NULL)

	INSERT INTO #CBPMatch(MatchID, FanID, PartnerID, TransactionDate)
	SELECT MatchID, FanID, PartnerID, TransactionDate
	FROM Relational.PartnerTrans
	WHERE MatchID > @StartMatchID

	ALTER TABLE #CBPMatch ADD PRIMARY KEY (MatchID)
	CREATE NONCLUSTERED INDEX IX_TMP_CBPMatch_FanPartner ON #CBPMatch(FanID, PartnerID, TransactionDate)
	
	INSERT INTO Staging.SchemeCashbackRateInfo(MatchID, CashbackRateNumeric)
	SELECT C.MatchID, pb.CashBackRateNumeric
	FROM #CBPMatch c
	INNER JOIN Relational.Customer_Segment cs ON c.FanID = cs.FanID AND c.PartnerID = cs.PartnerID
	INNER JOIN Relational.Partner_BaseOffer pb ON cs.OfferID = pb.OfferID
	WHERE c.TransactionDate BETWEEN cs.StartDate AND ISNULL(cs.enddate, CAST('3000-01-01' AS DATE))
	
	DROP TABLE #CBPMatch

END