
CREATE PROCEDURE [Email].[__SFD_EarnConfirmation_Unused]
AS
	BEGIN

		DECLARE @Yesterday DATE = DATEADD(DAY, -1, GETDATE())

		IF OBJECT_ID('tempdb..#TransProcessedYesterday') IS NOT NULL DROP TABLE #TransProcessedYesterday
		SELECT *
		INTO #TransProcessedYesterday
		FROM [SLC_Report].[dbo].[Trans] tr
		WHERE EXISTS (	SELECT 1
						FROM [Derived].[Customer] cu
						WHERE tr.FanID = cu.FanID)
		AND TypeID = 9
		AND CONVERT(DATE, ProcessDate) = @Yesterday

		CREATE CLUSTERED INDEX CIX_FanID ON #TransProcessedYesterday (FanID)
		CREATE NONCLUSTERED INDEX CIX_MatchID ON #TransProcessedYesterday (MatchID)

		IF OBJECT_ID('tempdb..#CustomersWithExistingTrans') IS NOT NULL DROP TABLE #CustomersWithExistingTrans
		SELECT FanID
		INTO #CustomersWithExistingTrans
		FROM [SLC_Report].[dbo].[Trans] tr
		WHERE EXISTS (	SELECT 1
						FROM #TransProcessedYesterday tpy
						WHERE tr.FanID = tpy.FanID)
		AND TypeID = 9
		AND ProcessDate < @Yesterday
		GROUP BY FanID

		CREATE CLUSTERED INDEX CIX_FanID ON #CustomersWithExistingTrans (FanID)

		IF OBJECT_ID('tempdb..#FirstTrans') IS NOT NULL DROP TABLE #FirstTrans
		SELECT tpy.ID AS TranID
			 , tpy.MatchID
			 , tpy.FanID
			 , tpy.Price
			 , tpy.ClubCash
			 , ma.RetailOutletID
			 , ma.MerchantID
			 , tpy.Date AS TransactionDate
			 , MIN(tpy.MatchID) OVER (PARTITION BY tpy.FanID) AS FirstMatchID
		INTO #FirstTrans
		FROM #TransProcessedYesterday tpy
		INNER JOIN [SLC_Report].[dbo].[Match] ma
			ON tpy.MatchID = ma.ID
		WHERE NOT EXISTS (	SELECT 1
							FROM #CustomersWithExistingTrans cwet
							WHERE tpy.FanID = cwet.FanID)

		SELECT ft.FanID
			 , ro.PartnerID
			 , pa.Name AS PartnerName
			 , ft.Price
			 , ft.ClubCash
			 , ft.MerchantID
			 , ft.TransactionDate
		FROM #FirstTrans ft
		INNER JOIN [SLC_Report].[dbo].[RetailOutlet] ro
			ON ft.RetailOutletID = ro.ID
		LEFT JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
			ON ro.PartnerID = pri.PartnerID
		INNER JOIN [SLC_Report].[dbo].[Partner] pa
			ON COALESCE(pri.PrimaryPartnerID, ro.PartnerID) = pa.ID
		WHERE MatchID = FirstMatchID
		ORDER BY FanID

	END