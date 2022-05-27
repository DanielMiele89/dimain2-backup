

CREATE PROCEDURE [Staging].[SSRS_R0208_OnboardingPack_VISA_Matcher] (@PartnerID NVARCHAR(MAX)
														 , @RetailerChannel VARCHAR(25))
AS
	BEGIN
	
/*******************************************************************************************************************************************
	1. Declare Variables
*******************************************************************************************************************************************/

		--DECLARE @PartnerID NVARCHAR(MAX) = 4319
		--	  , @RetailerChannel VARCHAR(25) = 'Both'


		DECLARE @PID NVARCHAR(MAX) = REPLACE(@PartnerID, ' ', '')
			  , @RC VARCHAR(25) = @RetailerChannel		  
	
/*******************************************************************************************************************************************
	2. Split multiple PartnerIDs
*******************************************************************************************************************************************/
			  
		IF OBJECT_ID ('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs;
		SELECT p.Item AS PartnerID
			 , pa.Name
			 , pa.RegisteredName
			 , pa.MerchantAcquirer
		INTO #PartnerIDs
		FROM [dbo].[il_SplitDelimitedStringArray] (@PID, ',') p
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON p.Item = pa.ID

		
/*******************************************************************************************************************************************
	3. Fetch all connected partners including Alternate Partner records
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner;
		SELECT pa.ID AS PartnerID
			 , p.Name AS PartnerName
			 , p.RegisteredName
			 , p.MerchantAcquirer
		INTO #Partner
		FROM #PartnerIDs p
		INNER JOIN [iron].[PrimaryRetailerIdentification] pri
			ON p.PartnerID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID)
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON pri.PartnerID = pa.ID
		WHERE pa.Name NOT LIKE '%AMEX%'
			  
	
/*******************************************************************************************************************************************
	4. Convert the input of the channel type into a queryable format
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Channels') IS NOT NULL DROP TABLE #Channels;
		SELECT CASE
					WHEN @RC IN ('Online', 'Both') THEN 1
			   END AS ChannelID
		INTO #Channels
		UNION
		SELECT CASE
					WHEN @RC IN ('InStore', 'Both') THEN 2
			   END AS ChannelID

		DELETE
		FROM #Channels
		WHERE ChannelID IS NULL

			  
/*******************************************************************************************************************************************
	5. Fetch partner details
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerDetails') IS NOT NULL DROP TABLE #PartnerDetails;
		SELECT DISTINCT
			   ro.MerchantID
			 , pa.PartnerName
			 , fa.City
			 , CASE
					WHEN fa.Address1 = '' THEN fa.Address2
					WHEN fa.Address2 = '' THEN fa.Address1
					ELSE fa.Address1 + ', ' + fa.Address2
			   END AS Address
			 , fa.Postcode
			 , pa.RegisteredName
			 , pa.MerchantAcquirer

			 , 826 AS MerchantCountryCode_ISO

			 , CASE
					WHEN ro.Channel = 1 THEN 'Online'
					WHEN ro.Channel = 2 THEN 'In-Store'
					ELSE 'Unknown'
			   END AS OnlineInStore
			 , ro.ID AS RetailOutletID
		INTO #PartnerDetails
		FROM [SLC_REPL].[dbo].[RetailOutlet] ro
		INNER JOIN #Partner pa
			ON ro.PartnerID = pa.PartnerID
		INNER JOIN [SLC_REPL].[dbo].[Fan] fa
			ON ro.FanID = fa.ID
		WHERE LEFT(ro.MerchantID, 1) NOT IN ('x', '#', 'a')
		AND EXISTS (SELECT 1
					FROM #Channels c
					WHERE ro.Channel = c.ChannelID)


/*******************************************************************************************************************************************
	6. Output results
*******************************************************************************************************************************************/

		SELECT MerchantID
			 , PartnerName
			 , City
			 , Address
			 , Postcode
			 , RegisteredName
			 , MerchantAcquirer

			 , MerchantCountryCode_ISO

			 , OnlineInStore
			 , RetailOutletID
		FROM #PartnerDetails

	END