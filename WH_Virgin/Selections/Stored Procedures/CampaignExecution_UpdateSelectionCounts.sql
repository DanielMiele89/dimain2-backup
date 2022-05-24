

/***********************************************************************************************************************
Title: 4. Selection Counts
Author: Rory Francis
Creation Date: 
Purpose: 

------------------------------------------------------------------------------------------------------------------------

Modified Log:

Change No:	Name:			Date:			Description of change:

											
***********************************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignExecution_UpdateSelectionCounts]

AS
BEGIN
	
	SET NOCOUNT ON

	
/*******************************************************************************************************************************************
	1.	Fetch the stored selection counts for the upcoming cycle & all campaigns / offers set to run in the cycle
*******************************************************************************************************************************************/

		DECLARE @EmailDate DATE

		SELECT @EmailDate = MIN([Selections].[CampaignSetup_POS].[EmailDate])
		FROM [Selections].[CampaignSetup_POS]
		WHERE [Selections].[CampaignSetup_POS].[StartDate] > GETDATE()
			   
		IF OBJECT_ID('tempdb..#CamapignCounts') IS NOT NULL DROP TABLE #CamapignCounts
		SELECT	sc.EmailDate
			,	sc.OutputTableName
			,	sc.IronOfferID
			,	sc.CountSelected
			,	sc.RunDateTime
			,	sc.NewCampaign
			,	sc.ClientServicesRef
		INTO #CamapignCounts
		FROM [Selections].[CampaignExecution_SelectionCounts] sc
		WHERE [sc].[EmailDate] = @EmailDate

		IF OBJECT_ID('tempdb..#Camapigns') IS NOT NULL DROP TABLE #Camapigns
		SELECT	DISTINCT 
				cs.PartnerID
			 ,	cs.ClientServicesRef
			 ,	cs.CampaignName
			 ,	cs.OutputTableName
			 ,	io.Item AS OfferID
			 ,	iof.IronOfferName
			 ,	cs.StartDate
			 ,	cs.EndDate
		INTO #Camapigns
		FROM [Selections].[CampaignSetup_POS] cs
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([cs].[OfferID], ',') io
		INNER JOIN [Derived].[IronOffer] iof
			ON io.Item	 = iof.IronOfferID
		WHERE [cs].[EmailDate] = @EmailDate
		AND io.Item != 0


/*******************************************************************************************************************************************
	3.	Fetch all offer memberships for the upcoming cycle
*******************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#Memberships') IS NOT NULL DROP TABLE #Memberships
		SELECT	iom.IronOfferID
			,	iom.CompositeID
			,	ca.ClientServicesRef
			,	ca.OutputTableName
			,	ca.StartDate AS CycleStartDate
		INTO #Memberships
		FROM [Derived].[IronOfferMember] iom
		INNER JOIN #Camapigns ca
			ON iom.IronOfferID = ca.OfferID
			AND iom.StartDate <= ca.StartDate
			AND ca.StartDate <= iom.EndDate
		WHERE iom.StartDate <= @EmailDate
		AND EXISTS (SELECT 1 
					FROM [Derived].[Customer] cu
					WHERE iom.CompositeID = cu.CompositeID
					AND cu.CurrentlyActive = 1)

		INSERT INTO #Memberships
		SELECT	iom.IronOfferID
			,	iom.CompositeID
			,	ca.ClientServicesRef
			,	ca.OutputTableName
			,	ca.StartDate AS CycleStartDate
		FROM [Segmentation].[OfferMemberAddition] iom
		INNER JOIN #Camapigns ca
			ON iom.IronOfferID = ca.OfferID
		WHERE iom.StartDate <= @EmailDate
		AND EXISTS (SELECT 1 
					FROM [Derived].[Customer] cu
					WHERE iom.CompositeID = cu.CompositeID
					AND cu.CurrentlyActive = 1)

		CREATE CLUSTERED INDEX CIX_OfferComp ON #Memberships (IronOfferID, CompositeID)


/*******************************************************************************************************************************************
	4.	Aggregate memberships for the upcoming cycle
*******************************************************************************************************************************************/
				
		IF OBJECT_ID('tempdb..#MembershipsCount') IS NOT NULL DROP TABLE #MembershipsCount
		SELECT	[c].[IronOfferID]
			,	[c].[ClientServicesRef]
			,	[c].[OutputTableName]
			,	[c].[CycleStartDate]
			,	COUNT(DISTINCT [c].[CompositeID]) AS Entries
		INTO #MembershipsCount
		FROM #Memberships c
		GROUP BY	[c].[IronOfferID]
				,	[c].[ClientServicesRef]
				,	[c].[OutputTableName]
				,	[c].[CycleStartDate]


/*******************************************************************************************************************************************
	5.	Update existing counts to new values & add new entries from missing offers
*******************************************************************************************************************************************/

		DECLARE @EmailDate2 DATE

		SELECT @EmailDate2 = MIN([Selections].[CampaignSetup_POS].[EmailDate])
		FROM [Selections].[CampaignSetup_POS]
		WHERE [Selections].[CampaignSetup_POS].[StartDate] > GETDATE()

		UPDATE ch
		SET ch.CountSelected = mc.Entries
		FROM #MembershipsCount mc
		INNER JOIN [Selections].[CampaignExecution_SelectionCounts] ch
			ON mc.IronOfferID = ch.IronOfferID
			AND ch.EmailDate = @EmailDate2

		INSERT INTO [Selections].[CampaignExecution_SelectionCounts]
		SELECT	mc.CycleStartDate
			,	mc.OutputTableName
			,	mc.IronOfferID
			,	mc.Entries
			,	GETDATE()
			,	0
			,	mc.ClientServicesRef
		FROM #MembershipsCount mc
		WHERE NOT EXISTS (	SELECT 1
							FROM [Selections].[CampaignExecution_SelectionCounts] sc
							WHERE mc.IronOfferID = sc.IronOfferID
							AND sc.EmailDate = @EmailDate2)


END
