

CREATE PROCEDURE [Staging].[SSRS_R0206_OnboardingPack_MTR] (@PartnerID NVARCHAR(MAX)
														 , @PartnerID_New NVARCHAR(MAX)
														 , @DateOfLastOnboarding DATE)
AS
	BEGIN
	
/*******************************************************************************************************************************************
	1. Declare Variables
*******************************************************************************************************************************************/

		DECLARE @PID NVARCHAR(MAX) = @PartnerID
			  , @PID_New NVARCHAR(MAX) = @PartnerID_New
			  , @DateFilter DATE = @DateOfLastOnboarding
			  
	
/*******************************************************************************************************************************************
	2. Split multiple PartnerIDs
*******************************************************************************************************************************************/
			  
		IF OBJECT_ID ('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs
		SELECT p.Item AS PartnerID
		INTO #PartnerIDs
		FROM dbo.il_SplitDelimitedStringArray (@PID, ',') p
			  
		IF OBJECT_ID ('tempdb..#PartnerIDsNewToMTR') IS NOT NULL DROP TABLE #PartnerIDsNewToMTR
		SELECT p.Item AS PartnerID
		INTO #PartnerIDsNewToMTR
		FROM dbo.il_SplitDelimitedStringArray (@PID_New, ',') p
	
		
/*******************************************************************************************************************************************
	2. Find all MIDs relating to the Partner
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
		SELECT *
		INTO #RetailOutlet
		FROM SLC_Repl..RetailOutlet ro
		WHERE 1 = 1
		AND EXISTS (	SELECT 1
					  FROM [Staging].[Onboarding_Publisher_MTR_ToOnboard] p
					  WHERE ro.PartnerID = p.PartnerID
					  AND ro.Channel = p.Channel)
		AND PartnerID IN (SELECT PartnerID FROM #PartnerIDs);
			  
	
/*******************************************************************************************************************************************
	3. In cases where a MID has been hased, return it to it's actual value
*******************************************************************************************************************************************/

		WHILE EXISTS (SELECT 1 FROM #RetailOutlet WHERE LEFT(MerchantID, 1) IN ('x', 'a', '#'))
			BEGIN
				WITH UpdaterMID AS (SELECT ID
										 , MerchantID
										 , RIGHT(MerchantID, LEN(MerchantID) - 1) AS NewMerchantID
									FROM #RetailOutlet
									WHERE LEFT(MerchantID, 1) IN ('x', 'a', '#'))

				UPDATE UpdaterMID
				SET MerchantID = NewMerchantID
			END

			  
/*******************************************************************************************************************************************
	4. Output results
*******************************************************************************************************************************************/

		DECLARE @ReportDate DATE = GETDATE()
		
		DELETE
		FROM [Staging].[Onboarding_Publisher_MTR_SubmittedFiles]
		WHERE SubmittedDate = @ReportDate

	/***********************************************************************************************************************
		4.1. Fetch all datapoints relevant
	***********************************************************************************************************************/	

		;WITH
		PartnerDetails AS (SELECT pa.ID AS PartnerID
				   				, pa.MerchantAcquirer
								, pa.Matcher
								, ro.ID AS RetailOutletID
				   				, ro.MerchantID
				   				, pa.Name AS PartnerName
				   				, ro.Channel
				   				, fa.Address1
				   				, fa.Address2
				   				, fa.City
				   				, fa.County
				   				, fa.Postcode
				   				, ro.PartnerOutletReference
								, REPLACE(REPLACE(COALESCE(CONVERT(VARCHAR(50), ro.Coordinates), ''), 'POINT (', ''), ')', '') AS Coordinates
						   FROM #RetailOutlet ro
						   INNER JOIN SLC_Repl..Partner pa
				   				ON ro.PartnerID = pa.ID
						   INNER JOIN SLC_Repl..Fan fa
				   				ON ro.FanID = fa.ID),

	/***********************************************************************************************************************
		4.2. Identify instances where additional MIDs are added to GAS purely for TNS tracking, these will be excluded
	***********************************************************************************************************************/	

		Leading0_TNS AS (SELECT DISTINCT
								pd1.MerchantID
						 FROM PartnerDetails pd1
						 INNER JOIN PartnerDetails pd2
							ON LEFT(pd1.MerchantID, 1) = 0
							AND LEN(pd1.MerchantID) = 8
							AND RIGHT(pd1.MerchantID, 7) = pd2.MerchantID),

	/***********************************************************************************************************************
		4.3. Take postcode assigned to MID and find additional details where possible
	***********************************************************************************************************************/	

		Postcode AS (SELECT pd.Postcode
						  , MAX(pst.County) AS County
						  , MAX(pst.CountryString) AS Country
					 FROM Relational.PostcodeDistrict pst
					 INNER JOIN PartnerDetails pd
						ON CASE 
				   				WHEN CHARINDEX(' ', pd.PostCode) = 0 THEN CONVERT(VARCHAR(4), pd.PostCode) 
				   				ELSE LEFT(pd.PostCode, CHARINDEX(' ', pd.PostCode) - 1) 
						   END LIKE pst.PostCodeDistrict + '%'
					 GROUP BY pd.Postcode)	

	/***********************************************************************************************************************
		4.4. Output results, calculating action code based on MID start & end dates
	***********************************************************************************************************************/	

		INSERT INTO [Staging].[Onboarding_Publisher_MTR_SubmittedFiles]
		SELECT DISTINCT
			   pd.PartnerID
			 , pd.PartnerName
			 , CASE
					WHEN pd.Address1 = '' THEN pd.Address2
					WHEN pd.Address2 = '' THEN pd.Address1
					ELSE pd.Address1 + ', ' + pd.Address2
			   END AS Address
			 , pd.City
			 , COALESCE(pst.County, pd.County) AS County
			 , pd.Postcode
			 , pd.MerchantID
			 , pd.MerchantAcquirer
			 , SUBSTRING(Coordinates, PATINDEX('% %', Coordinates), 999) AS Latitude
			 , SUBSTRING(Coordinates, 1, PATINDEX('% %', Coordinates)) AS Longitude
			 , CASE
					WHEN EXISTS (SELECT 1 FROM #PartnerIDsNewToMTR pin WHERE pd.PartnerID = pin.PartnerID) AND EndDate IS NULL THEN 'Add New Location'
					WHEN StartDate <= @DateFilter AND EndDate IS NULL THEN 'Select…'
					WHEN StartDate > @DateFilter AND EndDate IS NULL THEN 'Add New Location'
					WHEN StartDate <= @DateFilter AND EndDate > @DateFilter THEN 'Remove Location'
			   END AS ActionCode
			 , PartnerOutletReference
			 , pd.Channel
			 , mtg.StartDate
			 , mtg.EndDate
			 , @ReportDate 
		FROM PartnerDetails pd
		LEFT JOIN Postcode pst
			ON pd.PostCode = pst.PostCode
		LEFT JOIN Relational.MIDTrackingGAS mtg
			ON pd.RetailOutletID = mtg.RetailOutletID
		WHERE NOT EXISTS (SELECT 1
						  FROM Leading0_TNS l0
						  WHERE pd.MerchantID = l0.MerchantID)
		AND (EndDate IS NULL OR EndDate >= @DateFilter)


		SELECT PartnerID
			 , PartnerName
			 , Address
			 , City
			 , County
			 , Postcode
			 , MerchantID
			 , MerchantAcquirer
			 , Latitude
			 , Longitude
			 , ActionCode
			 , PartnerOutletReference
			 , Channel
			 , StartDate
			 , EndDate
		FROM [Staging].[Onboarding_Publisher_MTR_SubmittedFiles]
		WHERE SubmittedDate = @ReportDate
		ORDER BY MerchantID

	END