
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
		AND [SLC_Report].[dbo].[Trans].[TypeID] = 9
		AND CONVERT(DATE, [SLC_Report].[dbo].[Trans].[ProcessDate]) = @Yesterday

		CREATE CLUSTERED INDEX CIX_FanID ON #TransProcessedYesterday (FanID)
		CREATE NONCLUSTERED INDEX CIX_MatchID ON #TransProcessedYesterday (MatchID)

		IF OBJECT_ID('tempdb..#CustomersWithExistingTrans') IS NOT NULL DROP TABLE #CustomersWithExistingTrans
		SELECT [SLC_Report].[dbo].[Trans].[FanID]
		INTO #CustomersWithExistingTrans
		FROM [SLC_Report].[dbo].[Trans] tr
		WHERE EXISTS (	SELECT 1
						FROM #TransProcessedYesterday tpy
						WHERE #TransProcessedYesterday.[tr].FanID = tpy.FanID)
		AND [SLC_Report].[dbo].[Trans].[TypeID] = 9
		AND [SLC_Report].[dbo].[Trans].[ProcessDate] < @Yesterday
		GROUP BY [SLC_Report].[dbo].[Trans].[FanID]

		CREATE CLUSTERED INDEX CIX_FanID ON #CustomersWithExistingTrans (FanID)

		IF OBJECT_ID('tempdb..#FirstTrans') IS NOT NULL DROP TABLE #FirstTrans
		SELECT tpy.ID AS TranID
			 , tpy.MatchID
			 , tpy.FanID
			 , tpy.Price
			 , tpy.ClubCash
			 , #TransProcessedYesterday.[ma].RetailOutletID
			 , #TransProcessedYesterday.[ma].MerchantID
			 , tpy.Date AS TransactionDate
			 , MIN(tpy.MatchID) OVER (PARTITION BY tpy.FanID) AS FirstMatchID
		INTO #FirstTrans
		FROM #TransProcessedYesterday tpy
		INNER JOIN [SLC_Report].[dbo].[Match] ma
			ON tpy.MatchID = #TransProcessedYesterday.[ma].ID
		WHERE NOT EXISTS (	SELECT 1
							FROM #CustomersWithExistingTrans cwet
							WHERE #CustomersWithExistingTrans.[tpy].FanID = cwet.FanID)

		SELECT ft.FanID
			 , #FirstTrans.[ro].PartnerID
			 , #FirstTrans.[pa].Name AS PartnerName
			 , ft.Price
			 , ft.ClubCash
			 , ft.MerchantID
			 , ft.TransactionDate
		FROM #FirstTrans ft
		INNER JOIN [SLC_Report].[dbo].[RetailOutlet] ro
			ON ft.RetailOutletID = #FirstTrans.[ro].ID
		LEFT JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
			ON #FirstTrans.[ro].PartnerID = #FirstTrans.[pri].PartnerID
		INNER JOIN [SLC_Report].[dbo].[Partner] pa
			ON COALESCE(#FirstTrans.[pri].PrimaryPartnerID, #FirstTrans.[ro].PartnerID) = #FirstTrans.[pa].ID
		WHERE [ft].[MatchID] = [ft].[FirstMatchID]
		ORDER BY [ft].[FanID]

	END