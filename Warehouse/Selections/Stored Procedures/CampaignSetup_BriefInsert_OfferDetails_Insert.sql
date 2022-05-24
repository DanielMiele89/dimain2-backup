
CREATE PROCEDURE [Selections].[CampaignSetup_BriefInsert_OfferDetails_Insert]
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Fetch campaign details
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			1.1. Find the first row that contains campaign details
		***********************************************************************************************************************/

			DECLARE @CampaignDetailsStart INT
			
			SELECT @CampaignDetailsStart = MIN(ID)
			FROM [Selections].[CampaignSetup_BriefInsert_OfferDetails_Import]
			WHERE ColumnA = 'Campaign Name'

		/***********************************************************************************************************************
			1.2. Store all rows containing relevant details in table
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CampaignDetails') IS NOT NULL DROP TABLE #CampaignDetails
			SELECT ColumnA AS CampaignDetails_Header
				 , ColumnB AS CampaignDetails_Values
				 , ROW_NUMBER() OVER (ORDER BY ID) as RowNumber
			INTO #CampaignDetails
			FROM [Selections].[CampaignSetup_BriefInsert_OfferDetails_Import]
			WHERE ID Between @CampaignDetailsStart And @CampaignDetailsStart + 7
			AND ColumnA != 'Brand ID'
			

		/***********************************************************************************************************************
			1.3. Store all rows containing relevant details as parameters to later insert to table
		***********************************************************************************************************************/

			DECLARE @CampaignName VARCHAR(255)
				  , @CampaignCode VARCHAR(255)
				  , @RetailerName VARCHAR(255)
				  , @Override VARCHAR(255)
				  , @StartDate VARCHAR(255)
				  , @EndDate VARCHAR(255)

			SELECT	@CampaignName = MAX(CASE WHEN RowNumber = 1 THEN CampaignDetails_Values END)
				,	@CampaignCode = MAX(CASE WHEN RowNumber = 2 THEN CampaignDetails_Values END)
				,	@RetailerName = MAX(CASE WHEN RowNumber = 3 THEN CampaignDetails_Values END)
				,	@Override = MAX(CASE WHEN RowNumber = 4 THEN CampaignDetails_Values END)
				,	@StartDate = MAX(CASE WHEN RowNumber = 5 THEN CampaignDetails_Values END)
				,	@EndDate = MAX(CASE WHEN RowNumber = 6 THEN CampaignDetails_Values END)
			FROM #CampaignDetails


	/*******************************************************************************************************************************************
		2. Fetch offer details
	*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CampaignSetup_BriefInsert_OfferDetails_Import') IS NOT NULL DROP TABLE #CampaignSetup_BriefInsert_OfferDetails_Import
			SELECT	ID
				,	COALESCE(TRY_CONVERT(VARCHAR(10), TRY_CONVERT(DATE, ColumnR, 103)), TRY_CONVERT(DATE, ColumnR, 101)) AS CycleStart
				,	COALESCE(TRY_CONVERT(VARCHAR(10), TRY_CONVERT(DATE, ColumnS, 103)), TRY_CONVERT(DATE, ColumnS, 101)) AS CycleEnd
				,	ColumnT AS Publisher
				,	ColumnU AS Segment
				--,	CONVERT(DECIMAL(19, 4), ColumnV) AS Selection
				--,	CONVERT(DECIMAL(19, 4), ColumnW) AS Throttle
				,	ColumnX AS Cycle
				,	ColumnY As Cardholders
				,	LTRIM(RTRIM(CASE 
									WHEN ColumnZ LIKE '%[%]%' THEN TRY_CONVERT(DECIMAL(19,4),REPLACE(ColumnZ, '%', ''))
									WHEN ColumnZ LIKE '%E%' THEN TRY_CONVERT(DECIMAL(19,4), TRY_CONVERT(FLOAT, ColumnZ)) * 100
									ELSE TRY_CONVERT(DECIMAL(19, 4), ColumnZ) * 100
								END)) AS OfferRate
				,	REPLACE(LEFT(ColumnAA, CASE WHEN CHARINDEX('-', ColumnAA) > 0 THEN CHARINDEX('-', ColumnAA) - 1 ELSE 999 END), '£', '') AS SpendStretchAmount
				,	LTRIM(RTRIM(CASE 
									WHEN ColumnAB LIKE '%[%]%' THEN TRY_CONVERT(DECIMAL(19,4),REPLACE(ColumnAB, '%', ''))
									WHEN ColumnAB LIKE '%E%' THEN TRY_CONVERT(DECIMAL(19,4), TRY_CONVERT(FLOAT, ColumnAB)) * 100
									ELSE TRY_CONVERT(DECIMAL(19, 4), ColumnAB) * 100
								END)) AS AboveSpendStretchRate
				,	LTRIM(RTRIM(CASE 
									WHEN ColumnAC LIKE '%[%]%' THEN TRY_CONVERT(DECIMAL(19,4),REPLACE(ColumnAC, '%', ''))
									WHEN ColumnAC LIKE '%E%' THEN TRY_CONVERT(DECIMAL(19,4), TRY_CONVERT(FLOAT, ColumnAC)) * 100
									ELSE TRY_CONVERT(DECIMAL(19, 4), ColumnAC) * 100
								END)) AS OfferBillingRate
				,	LTRIM(RTRIM(CASE 
									WHEN ColumnAD LIKE '%[%]%' THEN TRY_CONVERT(DECIMAL(19,4),REPLACE(ColumnAD, '%', ''))
									WHEN ColumnAD LIKE '%E%' THEN TRY_CONVERT(DECIMAL(19,4), TRY_CONVERT(FLOAT, ColumnAD)) * 100
									ELSE TRY_CONVERT(DECIMAL(19, 4), ColumnAD) * 100
								END)) AS AboveSpendStretchBillingRate
				,	ColumnAE AS IronOfferID
			INTO #CampaignSetup_BriefInsert_OfferDetails_Import
			FROM [Selections].[CampaignSetup_BriefInsert_OfferDetails_Import]
			WHERE ColumnR IS NOT NULL
			AND ColumnR NOT IN ('Cycle Details', 'CycleStart')
			

			IF OBJECT_ID('tempdb..#OfferDetails') IS NOT NULL DROP TABLE #OfferDetails
			SELECT	DISTINCT
					Publisher
				,	@RetailerName as PartnerName
				,	CASE
						WHEN @Override Like '%[%]%' THEN CONVERT(FLOAT, REPLACE(@Override, '%', ''))
						ELSE @Override
					END AS Override
				,	@CampaignCode as ClientServicesRef
				,	@StartDate as CampaignStartDate
				,	@EndDate as CampaignEndDate
				,	IronOfferID
				,	OfferRate
				,	SpendStretchAmount
				,	AboveSpendStretchRate
				,	OfferBillingRate
				,	AboveSpendStretchBillingRate
			INTO #OfferDetails
			FROM #CampaignSetup_BriefInsert_OfferDetails_Import
		
	/*******************************************************************************************************************************************
		3. Store entries where there is a non numeric character in the IronOfferID column
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IronOfferID_Edit') IS NOT NULL DROP TABLE #IronOfferID_Edit
		SELECT	IronOfferID
			,	IronOfferID AS IronOfferID_Edit
			,	NULL AS IronOffer1
			,	NULL AS IronOffer2
			,	NULL AS IronOffer3
		INTO #IronOfferID_Edit
		FROM #OfferDetails
		WHERE PATINDEX('%[^0-9]%', IronOfferID) > 0

	/*******************************************************************************************************************************************
		4. Split the stored IronOfferIDs into at 3 different IDs (more may need to be added depnding on counts of secondary partners)
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Extract the first IronOfferID by finding the first numeric character then taking all following numeric
				 characters without break.
				 Once seperated, remove this string from the IronOfferID_Edit column to prevent duplication
		***********************************************************************************************************************/

			UPDATE #IronOfferID_Edit
			SET IronOffer1 = SUBSTRING(IronOfferID_Edit,
									   PATINDEX('%[0-9]%', IronOfferID_Edit),
										CASE
						   				   WHEN PATINDEX('%[^0-9]%', SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit))) = 0 THEN LEN(SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit)))
						   				   ELSE PATINDEX('%[^0-9]%', SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit))) - 1
										END)

			UPDATE #IronOfferID_Edit
			SET IronOfferID_Edit = REPLACE(IronOfferID_Edit, IronOffer1, '')
									 

		/***********************************************************************************************************************
			4.2. Repeat the process for the second instance of an IronOfferID, leaving null values where no second offer found
		***********************************************************************************************************************/

			UPDATE #IronOfferID_Edit
			SET IronOffer2 = SUBSTRING(IronOfferID_Edit,
									   PATINDEX('%[0-9]%', IronOfferID_Edit),
										CASE
						   				   WHEN PATINDEX('%[^0-9]%', SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit))) = 0 THEN LEN(SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit)))
						   				   ELSE PATINDEX('%[^0-9]%', SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit))) - 1
										END)
			WHERE PATINDEX('%[0-9]%', IronOfferID_Edit) > 0

			UPDATE #IronOfferID_Edit
			SET IronOfferID_Edit = REPLACE(IronOfferID_Edit, IronOffer2, '')
											 

		/***********************************************************************************************************************
			4.3. Repeat the process for the third instance of an IronOfferID, leaving null values where no second offer found
		***********************************************************************************************************************/


			UPDATE #IronOfferID_Edit
			SET IronOffer3 = SUBSTRING(IronOfferID_Edit, 
									   PATINDEX('%[0-9]%', IronOfferID_Edit),
										CASE
						   				   WHEN PATINDEX('%[^0-9]%', SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit))) = 0 THEN LEN(SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit)))
						   				   ELSE PATINDEX('%[^0-9]%', SUBSTRING(IronOfferID_Edit, PATINDEX('%[0-9]%', IronOfferID_Edit), LEN(IronOfferID_Edit))) - 1
										END)
			WHERE PATINDEX('%[0-9]%', IronOfferID_Edit) > 0

			UPDATE #IronOfferID_Edit
			SET IronOfferID_Edit = REPLACE(IronOfferID_Edit, IronOffer3, '')		


	/*******************************************************************************************************************************************
		5. Union disinct entries per offer
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#IronOffer_Join') IS NOT NULL DROP TABLE #IronOffer_Join
		SELECT	DISTINCT
				IronOffer_Join
			,	IronOfferID
		INTO #IronOffer_Join
		FROM (	SELECT IronOfferID AS IronOffer_Join
					 , IronOffer1 AS IronOfferID
				FROM #IronOfferID_Edit
				WHERE IronOffer1 IS NOT NULL

				UNION ALL

				SELECT IronOfferID AS IronOffer_Join
					 , IronOffer2 AS IronOfferID
				FROM #IronOfferID_Edit
				WHERE IronOffer2 IS NOT NULL

				UNION ALL

				SELECT IronOfferID AS IronOffer_Join
					 , IronOffer3 AS IronOfferID
				FROM #IronOfferID_Edit
				WHERE IronOffer3 IS NOT NULL) a


	/*******************************************************************************************************************************************
		6. Rejoin to original table, replacing the concatenated IronOfferID string with individual IronOffers
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#AllPublisher_CampaignDetails_BriefInput') IS NOT NULL DROP TABLE #AllPublisher_CampaignDetails_BriefInput
		SELECT	DISTINCT
				bi.Publisher
			,	bi.PartnerName
			,	bi.Override
			,	bi.ClientServicesRef
			,	bi.CampaignStartDate
			,	bi.CampaignEndDate
			,	ioj.IronOfferID
			,	bi.OfferRate
			,	bi.SpendStretchAmount
			,	bi.AboveSpendStretchRate
			,	bi.OfferBillingRate
			,	bi.AboveSpendStretchBillingRate
		INTO #AllPublisher_CampaignDetails_BriefInput
		FROM #IronOffer_Join ioj
		INNER JOIN #OfferDetails bi
			ON ioj.IronOffer_Join = bi.IronOfferID

	/*******************************************************************************************************************************************
		7. Delete the original entry of each offer from main table where a replacement has been gerenated
	*******************************************************************************************************************************************/
	
		DELETE bi
		FROM #OfferDetails bi
		INNER JOIN #IronOffer_Join iof
			ON bi.IronOfferID = iof.IronOffer_Join


	/*******************************************************************************************************************************************
		8. Insert new entries to #OfferDetails
	*******************************************************************************************************************************************/

		INSERT INTO #OfferDetails (	Publisher
								,	PartnerName
								,	Override
								,	ClientServicesRef
								,	CampaignStartDate
								,	CampaignEndDate
								,	IronOfferID
								,	OfferRate
								,	SpendStretchAmount
								,	AboveSpendStretchRate
								,	OfferBillingRate
								,	AboveSpendStretchBillingRate)
		SELECT Publisher
			 , PartnerName
			 , Override
			 , ClientServicesRef
			 , CampaignStartDate
			 , CampaignEndDate
			 , IronOfferID
			 , OfferRate
			 , SpendStretchAmount
			 , AboveSpendStretchRate
			 , OfferBillingRate
			 , AboveSpendStretchBillingRate
		FROM #AllPublisher_CampaignDetails_BriefInput
		
	/*******************************************************************************************************************************************
		9. Insert to final table
	*******************************************************************************************************************************************/

		INSERT INTO [Selections].[CampaignSetup_BriefInsert_OfferDetails]
		SELECT	Publisher
			,	PartnerName
			,	Override
			,	ClientServicesRef
			,	COALESCE(TRY_CONVERT(DATE, CampaignStartDate, 103), TRY_CONVERT(DATE, CampaignStartDate, 111)) AS CampaignStartDate
			,	COALESCE(TRY_CONVERT(DATE, CampaignEndDate, 103), TRY_CONVERT(DATE, CampaignEndDate, 111)) AS CampaignEndDate
			,	IronOfferID
			,	OfferRate
			,	SpendStretchAmount
			,	AboveSpendStretchRate
			,	OfferBillingRate
			,	AboveSpendStretchBillingRate
		FROM #OfferDetails od
		

	/*******************************************************************************************************************************************
		10. Clear down temp table
	*******************************************************************************************************************************************/

		TRUNCATE TABLE [Selections].[CampaignSetup_BriefInsert_OfferDetails_Import]
		
END