

CREATE PROCEDURE [Staging].[WeeklySummaryV2_FetchTransactionList_ByAddedDate] (@RetailerID INT)
AS 
BEGIN

SET NOCOUNT ON;
 
	--DECLARE @RetailerID INT = 4538

    SET DATEFIRST 1; -- Set Monday as the first day of the week

    DECLARE @Today DATE = CAST(GETDATE() AS DATE); 

	IF @Today < '2021-11-16' SET @Today = '2021-11-12'
	
    DECLARE @RecentSunday DATETIME = DATEADD(second,-1,datediff(dd,0,DATEADD(dd, -(DATEPART(dw, @Today)-1), DATEADD(day, -1, @Today)))+1); -- Most recent Sunday
    DECLARE @RecentWeekStart date = CASE WHEN @RetailerID IN (4760) THEN DATEADD(day, -13, @RecentSunday) ELSE DATEADD(day, -6, @RecentSunday) END;
	
	--SELECT @RecentWeekStart, @RecentSunday

		SELECT	CONVERT(BIGINT, pt.ID) * -1 AS MatchID
			,	fi.MatcherShortName AS PublisherName
			,	CONVERT(VARCHAR, ISNULL(pt.MerchantNumber, '')) AS  MerchantID
			,	CONVERT(VARCHAR, ro.PartnerOutletReference) AS Store
			,	CONVERT(DATE, pt.TransactionDate) AS TranDate
			,	CONVERT(TIME, pt.TransactionDate) AS Time
			,	MaskedCardNumber AS CardNumber
			,	pt.Price AS AmountSpent
			,	pt.OfferCode
			,	pt.OfferRate AS OfferPercentage
			,	pt.CashbackEarned
			,	pt.CommissionRate
			,	pt.NetAmount
			,	pt.VATAmount
			,	pt.GrossAmount
			,	pt.AddedDate
	--		,	fi.MatcherShortName
		FROM SLC_REPL.RAS.PANless_Transaction pt
		INNER JOIN SLC_REPL..CRT_File fi
			ON pt.FileID = fi.ID
		LEFT JOIN SLC_REPL..RetailOutlet ro
			ON pt.MerchantNumber = ro.MerchantID
		WHERE pt.PartnerID =@RetailerID		
		AND pt.AddedDate BETWEEN @RecentWeekStart AND @RecentSunday
		AND fi.MatcherShortName NOT IN ('VGN', 'AMX', 'VSI', 'VSA', 'VBC')	--	Excluded as these are included in SchemeTrans
		ORDER BY TransactionDate


END
