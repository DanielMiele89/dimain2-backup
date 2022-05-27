
CREATE PROCEDURE [Staging].[SSRS_R0202_RBSOfferCycles_Load]
AS
BEGIN

	SET NOCOUNT ON;
	
	/*******************************************************************************************************************************************
		1. Fetch all offers details
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			1.1. Fetch all offer details for both DD & POS campaigns
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CampaignSetup') IS NOT NULL DROP TABLE #CampaignSetup
			SELECT OfferID
				 , StartDate
				 , CONVERT(DATETIME, EndDate) + CONVERT(DATETIME, '23:59:59.000') AS EndDate
			INTO #CampaignSetup
			FROM [Selections].[CampaignSetup_POS]
			WHERE SelectionRun = 1
			UNION
			SELECT OfferID
				 , StartDate
				 , CONVERT(DATETIME, EndDate) + CONVERT(DATETIME, '23:59:59.000') AS EndDate
			FROM [Selections].[CampaignSetup_DD]
			WHERE SelectionRun = 1


		/***********************************************************************************************************************
			1.2. Split all offers down to OfferID level and exclude counts already ran
		***********************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#OfferCountsToAdd') IS NOT NULL DROP TABLE #OfferCountsToAdd
			SELECT DISTINCT
				   iof.Item AS IronOfferID
				 , StartDate
				 , EndDate
			INTO #OfferCountsToAdd
			FROM #CampaignSetup cs
			CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (cs.OfferID, ',') iof
			WHERE iof.Item > 0
			AND NOT EXISTS (SELECT 1
							FROM [Selections].[IronOfferMember_CycleCounts] iom
							WHERE iof.Item = iom.IronOfferID
							AND cs.StartDate = iom.StartDate
							AND cs.EndDate = iom.EndDate)


	/*******************************************************************************************************************************************
		2. Find the counts associated to all campaigns, irrelevant of whether they have any members
	*******************************************************************************************************************************************/

		DECLARE	@MinStartDate DATETIME
			,	@MaxStartDate DATETIME
			,	@MinEndDate DATETIME
			,	@MaxEndDate DATETIME

		SELECT	@MinStartDate = MIN(StartDate)
			,	@MaxStartDate = MAX(StartDate)
			,	@MinEndDate = MIN(EndDate)
			,	@MaxEndDate = MAX(EndDate)
		FROM #OfferCountsToAdd

		IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
		SELECT iom.IronOfferID
			 , iom.StartDate
			 , iom.EndDate
			 , COUNT(DISTINCT iom.CompositeID) AS CustomerCount
		INTO #IronOfferMember
		FROM [Relational].[IronOfferMember] iom
		WHERE iom.StartDate BETWEEN @MinStartDate AND @MaxStartDate
		AND iom.EndDate BETWEEN @MinEndDate AND @MaxEndDate
		AND EXISTS (SELECT 1
					FROM #OfferCountsToAdd octa
					WHERE iom.IronOfferID = octa.IronOfferID
					AND iom.StartDate = octa.StartDate
					AND iom.EndDate = octa.EndDate)
		GROUP BY iom.IronOfferID
			   , iom.StartDate
			   , iom.EndDate


	/*******************************************************************************************************************************************
		4. Insert counts to permanent table
	*******************************************************************************************************************************************/

		INSERT INTO [Selections].[IronOfferMember_CycleCounts] (IronOfferID
															  , StartDate
															  , EndDate
															  , CustomerCount)
		SELECT octa.IronOfferID
			 , octa.StartDate
			 , octa.EndDate
			 , COALESCE(iom.CustomerCount, 0) AS CustomerCount
		FROM #OfferCountsToAdd octa
		LEFT JOIN #IronOfferMember iom
			ON iom.IronOfferID = octa.IronOfferID
			AND iom.StartDate = octa.StartDate
			AND iom.EndDate = octa.EndDate


	/*******************************************************************************************************************************************
		5. Send the report
	*******************************************************************************************************************************************/

	--	EXEC ReportServer.dbo.AddEvent @EventType='TimedSubscription',@EventData='389e4abb-9ae8-4aef-a95c-afd1c4582fa5' -- RBSOfferCount report subscription on DIMAIN

END