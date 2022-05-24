
CREATE PROCEDURE Staging.CLS_Onboarding_FetchingMIDsToSend (@CurrentDate DATE)
AS
	BEGIN

		DECLARE @CD DATE = @CurrentDate

		DELETE
		FROM [Staging].[CLS_Onboarding_MIDsToSend]
		WHERE LastSendDate = @CD

		IF OBJECT_ID ('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
		SELECT pa.ID AS PartnerID
			 , pa.Name AS PartnerName
			 , COALESCE(pri.PrimaryPartnerID, ro.PartnerID) AS PrimaryPartnerID
			 , ppa.Name AS PrimaryPartnerName
			 , ro.ID AS RetailOutletID
			 , NULL AS PrimaryRetailOutletID
			 , ro.MerchantID
			 , pa.Matcher AS MatcherID
			 , tv.Name AS MatcherName
			 , fa.RegistrationDate
		INTO #RetailOutlet
		FROM [SLC_Report].[dbo].[RetailOutlet] ro
		INNER JOIN [SLC_Report].[dbo].[Partner] pa
			ON ro.PartnerID = pa.ID
		INNER JOIN [SLC_Report].[dbo].[TransactionVector] tv
			ON pa.Matcher = tv.ID
		LEFT JOIN [iron].[PrimaryRetailerIdentification] pri
			ON ro.PartnerID = pri.PartnerID
		INNER JOIN [SLC_Report].[dbo].[Partner] ppa
			ON COALESCE(pri.PrimaryPartnerID, ro.PartnerID) = ppa.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ro.FanID = fa.ID
		WHERE pa.Status IN (1, 3)
		AND pa.Name NOT LIKE '%AMEX%'
		AND LEFT(ro.MerchantID, 1) != '#'
		AND LEFT(ro.MerchantID, 1) != 'x'
		AND LEFT(ro.MerchantID, 1) != 'A'

		UPDATE ro
		SET ro.PrimaryRetailOutletID = ro2.RetailOutletID
		  , ro.MerchantID = ro2.MerchantID
		FROM #RetailOutlet ro
		INNER JOIN #RetailOutlet ro2
			ON ro.PartnerID = ro2.PartnerID
			AND TRY_CONVERT(BIGINT, ro.MerchantID) = TRY_CONVERT(BIGINT, ro2.MerchantID)
			AND ro.RetailOutletID != ro2.RetailOutletID
			AND ((LEN(ro.MerchantID) > LEN(ro2.MerchantID) AND LEN(ro.MerchantID) = 8)
				OR (LEN(ro.MerchantID) < LEN(ro2.MerchantID) AND LEN(ro2.MerchantID) = 15))

		CREATE CLUSTERED INDEX CIX_ROID ON #RetailOutlet (RetailOutletID)

		IF OBJECT_ID ('tempdb..#MatchMaxTranDate') IS NOT NULL DROP TABLE #MatchMaxTranDate
		SELECT ma.VectorID
			 , ma.RetailOutletID
			 , ma.MerchantID
			 , MAX(AddedDate) AS AddedDate
		INTO #MatchMaxTranDate
		FROM [SLC_Report].[dbo].[Match] ma
		WHERE EXISTS (SELECT 1
					  FROM #RetailOutlet ro
					  WHERE ma.RetailOutletID = ro.RetailOutletID)
		GROUP BY ma.VectorID
			   , ma.RetailOutletID
			   , ma.MerchantID

		IF OBJECT_ID ('tempdb..#OutletDetails') IS NOT NULL DROP TABLE #OutletDetails
		SELECT ro.PrimaryPartnerID
			 , ro.PrimaryPartnerName
			 , ro.RetailOutletID
			 , ro.PrimaryRetailOutletID
			 , ro.MerchantID
			 , ro.RegistrationDate
			 , mt.AddedDate
			 , mt.VectorID
			 , tv.Name AS VectorName
		INTO #OutletDetails
		FROM #RetailOutlet ro
		LEFT JOIN #MatchMaxTranDate mt
			ON ro.RetailOutletID = mt.RetailOutletID
		LEFT JOIN [SLC_Report].[dbo].[TransactionVector] tv
			ON mt.VectorID = tv.ID

		IF OBJECT_ID ('tempdb..#ToReview') IS NOT NULL DROP TABLE #ToReview
		SELECT od.PrimaryPartnerID
			 , od.PrimaryPartnerName
			 , COALESCE(od.PrimaryRetailOutletID, od.RetailOutletID) AS RetailOutletID
			 , od.MerchantID
			 , MAX(od.RegistrationDate) AS RegistrationDate
			 , MAX(AddedDate) AS AddedDate
			 , MAX(CASE WHEN od.VectorID = 42 THEN AddedDate END) AS AddedDate_Mastercard
		INTO #ToReview
		FROM #OutletDetails od
		GROUP BY od.PrimaryPartnerID
			   , od.PrimaryPartnerName
			   , COALESCE(od.PrimaryRetailOutletID, od.RetailOutletID)
			   , od.MerchantID
			   
		INSERT INTO [Staging].[CLS_Onboarding_MIDsToSend]
		SELECT PrimaryPartnerID
			 , PrimaryPartnerName
			 , RetailOutletID
			 , MerchantID
			 , @CD
			 , 0
		FROM #ToReview
		WHERE (DATEADD(MONTH, -2, GETDATE()) < AddedDate OR DATEADD(MONTH, -1, GETDATE()) < RegistrationDate)
		AND (AddedDate_Mastercard < DATEADD(MONTH, -2, GETDATE()) OR AddedDate_Mastercard IS NULL)
		
	END

