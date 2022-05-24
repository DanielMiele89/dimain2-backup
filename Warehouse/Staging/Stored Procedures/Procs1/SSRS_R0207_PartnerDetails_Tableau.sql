

CREATE PROCEDURE [Staging].[SSRS_R0207_PartnerDetails_Tableau]
AS
	BEGIN
	
/*******************************************************************************************************************************************
	1. Declare Variables
*******************************************************************************************************************************************/

		--DECLARE @PID NVARCHAR(MAX) = @PartnerID
			  
	
/*******************************************************************************************************************************************
	2. Split multiple PartnerIDs
*******************************************************************************************************************************************/
			  
		--IF OBJECT_ID ('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs
		--SELECT p.Item AS PartnerID
		--INTO #PartnerIDs
		--FROM dbo.il_SplitDelimitedStringArray (@PID, ',') p

		--CREATE CLUSTERED INDEX CIX_PartnerID ON #PartnerIDs (PartnerID)
			  
	
/*******************************************************************************************************************************************
	3. Fetch partner details
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner;
	SELECT *
	INTO #Partner
	FROM [SLC_REPL].[dbo].[Partner] pa
	--WHERE EXISTS (SELECT 1
	--			  FROM #PartnerIDs p
	--			  WHERE pa.ID = p.PartnerID)
			  
	
/*******************************************************************************************************************************************
	4. Fetch MID details
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
	SELECT *
	INTO #RetailOutlet
	FROM [SLC_REPL].[dbo].[RetailOutlet] ro
	--WHERE EXISTS (SELECT 1
	--			  FROM #PartnerIDs p
	--			  WHERE ro.PartnerID = p.PartnerID)
			  
	
/*******************************************************************************************************************************************
	5. Fetch MID details and join
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#All') IS NOT NULL DROP TABLE #All;
	SELECT pa.ID AS PartnerID
		 , pa.Name AS PartnerName
		 , pa.RegisteredName
		 , pa.CompanyWebsite
		 , pa.Country AS PartnerCountry
		 , CASE
				WHEN pa.Status = 0 THEN 'Deleted'
				WHEN pa.Status = 1 THEN 'Being Tracked'
				WHEN pa.Status = 2 THEN 'Closed'
				WHEN pa.Status = 3 THEN 'Live'
		   END AS PartnerStatus
		 , CASE
				WHEN pa.ShowMaps = 0 THEN 'No'
				WHEN pa.ShowMaps = 1 THEN 'Yes'
		   END AS ShowMaps
		 , COALESCE(pa.MerchantAcquirer, '') AS Acquirer
		 , COALESCE(tv.Name, '') AS Matcher
		 , ro.MerchantID
		 , CASE
				WHEN ro.SuppressFromSearch = 0 THEN 'No'
				WHEN ro.SuppressFromSearch = 1 THEN 'Yes'
		   END AS SuppressFromSearch
		 , CASE
				WHEN ro.Channel = 1 THEN 'Online'
				WHEN ro.Channel = 2 THEN 'Offline'
				WHEN ro.Channel = 3 THEN 'Unknown'
		   END AS Channel
		 , fa.Address1
		 , fa.Address2
		 , fa.City
		 , fa.County
		 , fa.Postcode
		 , fa.Country
		 , CASE
				WHEN ro.MerchantID IS NULL THEN NULL
				ELSE COALESCE(fa.RegistrationDate, GETDATE())
		   END AS MerchantIDAddedDate 
	INTO #All
	FROM #Partner pa
	LEFT JOIN [SLC_Report].[dbo].[TransactionVector] tv
		ON pa.Matcher = tv.ID
	LEFT JOIN #RetailOutlet ro
		ON pa.ID = ro.PartnerID
	LEFT JOIN [SLC_Report].[dbo].[Fan] fa
		ON ro.FanID = fa.ID
			  
	
/*******************************************************************************************************************************************
	6. Fetch MID details and join
*******************************************************************************************************************************************/

	SELECT DISTINCT
		   PartnerID
		 , PartnerName
		 , RegisteredName
		 , CompanyWebsite
		 , PartnerCountry
		 , PartnerStatus
		 , ShowMaps
		 , Acquirer
		 , Matcher
		 , MerchantID
		 , SuppressFromSearch
		 , Channel
		 , Address1
		 , Address2
		 , City
		 , County
		 , Postcode
		 , Country
		 , MerchantIDAddedDate
		 , ROW_NUMBER() OVER (PARTITION BY PartnerID ORDER BY (SELECT NULL)) AS PartnerRow
	FROM #All

END