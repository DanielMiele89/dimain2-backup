
CREATE PROCEDURE [Staging].[SSRS_R0200_MerchantIDsToHash] (@MerchantIDsToHash VARCHAR(MAX))
As
Begin

	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/

		DECLARE @MerchantID VARCHAR(MAX)
			  , @RetailOutletIDs VARCHAR(MAX) = ''
		SET @MerchantID = REPLACE(@MerchantIDsToHash, ' ', '')

		IF OBJECT_ID ('tempdb..#MerchantIDs') IS NOT NULL DROP TABLE #MerchantIDs
		SELECT m.Item AS MerchantID
		INTO #MerchantIDs
		FROM dbo.il_SplitDelimitedStringArray (@MerchantID, ',') m

		CREATE CLUSTERED INDEX CIX_MerchantID ON #MerchantIDs (MerchantID)


	/*******************************************************************************************************************************************
		2. Store results into temp table
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OutputResults') IS NOT NULL DROP TABLE #OutputResults
		SELECT pa.ID AS PartnerID
			 , pa.Name AS PartnerName
			 , mid.MerchantID
			 , ro.ID AS RetailOutletID
			 , ro.Channel AS ChannelID
			 , CASE
					WHEN ro.Channel = 1 THEN 'Online'
					WHEN ro.Channel = 2 THEN 'Offline'
					WHEN ro.Channel = 3 THEN 'Unknown'
			   END AS Channel
			 , ro.SuppressFromSearch
			 , fa.Address1
			 , fa.Address2
			 , fa.City
			 , fa.County
			 , fa.Postcode
			 , CONVERT(DATE, fa.RegistrationDate) AS RegistrationDate
			 , ROW_NUMBER() Over (ORDER BY pa.Name, mid.MerchantID) AS RowNumber
		Into #OutputResults
		FROM #MerchantIDs mid
		INNER JOIN SLC_Report..RetailOutlet ro
			ON mid.MerchantID = ro.MerchantID
		INNER JOIN SLC_Report..Partner pa
			ON ro.PartnerID = pa.ID
		INNER JOIN SLC_Report..Fan fa
			ON ro.FanID = fa.ID


	/*******************************************************************************************************************************************
		3. Loop through results to store each Retail Outlet ID
	*******************************************************************************************************************************************/

		SELECT @RetailOutletIDs = @RetailOutletIDs + '' + CONVERT(VARCHAR(25), [RetailOutletID]) + ','
		FROM #OutputResults

		SET @RetailOutletIDs = LEFT(@RetailOutletIDs, LEN(@RetailOutletIDs) - 1)


	/*******************************************************************************************************************************************
		4. Output results
	*******************************************************************************************************************************************/

		SELECT PartnerID
			 , PartnerName
			 , MerchantID
			 , RetailOutletID
			 , ChannelID
			 , Channel
			 , SuppressFromSearch
			 , Address1
			 , Address2
			 , City
			 , County
			 , Postcode
			 , RegistrationDate
			 , RowNumber
			 , @RetailOutletIDs as OutletIDsToUpdate
		From #OutputResults

END
