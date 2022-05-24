

/***********************************************************************************************************************
Title: 3. Welcome Offer - Extending Memberships to the end of the cycle
Author: Rory Francis
Creation Date: 
Purpose: 

------------------------------------------------------------------------------------------------------------------------

Modified Log:

Change No:	Name:			Date:			Description of change:

											
***********************************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignExecution_StoreCampaignCounts] 

AS
BEGIN
	
	SET NOCOUNT ON

	DECLARE @CheckDate DATE = DATEADD(DAY, -0, GETDATE())
		,	@IsNewsletterBeingSent BIT = 1


	DECLARE @Cycle VARCHAR(25) = 'Half Cycle'
		  , @EmailDate DATE = (	SELECT MIN(EmailDate)
								FROM [Selections].[CampaignExecution_SelectionCounts]
								WHERE EmailDate > @CheckDate)
		  , @EndDate DATE = (	SELECT DATEADD(day, 13, MIN(EmailDate))
								FROM [Selections].[CampaignExecution_SelectionCounts]
								WHERE EmailDate > @CheckDate)

	/**************************************************************************
	****************************Store email sEND date**************************
	**************************************************************************/

	IF ((SELECT CONVERT(NUMERIC, DATEDIFF(day,'2018-01-04', @EmailDate)) / 28) % 1) = 0
		BEGIN
			SET @Cycle = 'Full Cycle'
			SET @EndDate = DATEADD(day, 14, @EndDate)
		END


	IF OBJECT_ID('tempdb..#DateAndCampaignType') IS NOT NULL DROP TABLE #DateAndCampaignType 
	SELECT @EmailDate AS EmailDate
		 , @EndDate AS EndDate
		 , @Cycle AS Cycle
	INTO #DateAndCampaignType


	/**************************************************************************
	********************Check OPE, ROCShopper_ALS & Selections********************
	**************************************************************************/

			/*******************************************************************
			*******Fetch Upcoming offer details FROM OfferPrioritisation********
			*******************************************************************/

				IF OBJECT_ID ('tempdb..#IronOffer_Campaign_HTM') IS NOT NULL DROP TABLE #IronOffer_Campaign_HTM
				SELECT	iof.PartnerID
					,	pa.Name AS PartnerName
					,	htm.ClientServicesRef
					,	iof.ID AS IronOfferID
					,	iof.Name AS IronOfferName
				INTO #IronOffer_Campaign_HTM
				FROM [Relational].[IronOffer_Campaign_HTM] htm
				LEFT JOIN [SLC_REPL].[dbo].[IronOffer] iof
					ON htm.IronOfferID = iof.ID
				LEFT JOIN [SLC_REPL].[dbo].[Partner] pa
					ON iof.PartnerID = pa.ID

			/*******************************************************************
			*******Fetch Upcoming offer details FROM OfferPrioritisation********
			*******************************************************************/

				IF OBJECT_ID ('tempdb..#OPE') IS NOT NULL DROP TABLE #OPE
				SELECT	iof.PartnerID
					,	pa.PartnerName
					,	htm.ClientServicesRef
					,	iof.IronOfferID
					,	iof.IronOfferName
				INTO #OPE
				FROM [Selections].[OfferPrioritisation] op
				INNER JOIN [Relational].[Partner] pa
					ON op.PartnerID = pa.PartnerID
				LEFT JOIN [Relational].[IronOffer] iof
					ON op.IronOfferID = iof.IronOfferID
				LEFT JOIN [Relational].[IronOffer_Campaign_HTM] htm
					ON op.IronOfferID = htm.IronOfferID
				WHERE EmailDate = (SELECT EmailDate FROM #DateAndCampaignType)
				And op.Base = 0
		

			/*************************************************************************
			***Fetch Upcoming offer details FROM ROCShopperSegment_PreSelection_ALS***
			*************************************************************************/


			IF OBJECT_ID('tempdb..#AllCampaigns') IS NOT NULL DROP TABLE #AllCampaigns 
			SELECT ClientServicesRef
				 , StartDate
				 , EndDate
				 , OutputTableName
				 , NewCampaign
				 , OfferID
				 , Throttling
				 , CASE
						WHEN PredictedCardholderVolumes IS NULL THEN '0,0,0,0,0,0'
						ELSE PredictedCardholderVolumes
				   END AS PredictedCardholderVolumes
				 , CampaignCycleLength_Weeks
				 , CASE
						WHEN EmailDate = @EmailDate THEN 1
						ELSE 0
				   END AS SelectionRan
			INTO #AllCampaigns
			FROM [Selections].[CampaignSetup_POS]
			WHERE @EmailDate BETWEEN StartDate AND EndDate
			UNION
			SELECT ClientServicesRef
				 , StartDate
				 , EndDate
				 , OutputTableName
				 , NewCampaign
				 , OfferID
				 , Throttling
				 , CASE
						WHEN PredictedCardholderVolumes IS NULL THEN '0,0,0,0,0,0'
						ELSE PredictedCardholderVolumes
				   END AS PredictedCardholderVolumes
				 , CampaignCycleLength_Weeks
				 , CASE
						WHEN EmailDate = @EmailDate THEN 1
						ELSE 0
				   END AS SelectionRan
			FROM [Selections].[CampaignSetup_DD]
			WHERE @EmailDate BETWEEN StartDate AND EndDate

	
			IF OBJECT_ID ('tempdb..#CampaignSetup') IS NOT NULL DROP TABLE #CampaignSetup	
			SELECT pa.PartnerID
				 , pa.PartnerName
				 , als.StartDate
				 , als.EndDate
				 , als.ClientServicesRef
				 , MAX(als.OutputTableName) AS OutputTableName
				 , c1.Item AS IronOfferID
				 , iof.IronOfferName
				 , MAX(c3.Item) AS PredictedCardholderVolumes
				 , MAX(c2.Item) AS Throttling
				 , als.NewCampaign
				 , als.CampaignCycleLength_Weeks
				 , als.SelectionRan
			INTO #CampaignSetup
			FROM #AllCampaigns als
			CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (OfferID, ',') c1
			CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (Throttling, ',') c2
			CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (PredictedCardholderVolumes, ',') c3
			LEFT JOIN [Relational].[IronOffer] iof
				ON c1.Item = iof.IronOfferID
			LEFT JOIN [Relational].[Partner] pa
				ON iof.PartnerID=pa.PartnerID
			WHERE (iof.EndDate > @CheckDate OR iof.EndDate IS NULL)
			AND c1.ItemNumber = c2.ItemNumber
			AND c2.ItemNumber = c3.ItemNumber
			AND c1.Item > 0
			GROUP BY pa.PartnerID
				   , pa.PartnerName
				   , als.StartDate
				   , als.EndDate
				   , als.ClientServicesRef
				   , c1.Item
				   , iof.IronOfferName
				   , als.NewCampaign
				   , als.CampaignCycleLength_Weeks
				   , als.SelectionRan


			/*******************************************************************
			******Cross check both data sources to find any missing offers******
			*******************************************************************/

			IF OBJECT_ID ('tempdb..#NonBaseOffersGoingLive') IS NOT NULL DROP TABLE #NonBaseOffersGoingLive
			SELECT DISTINCT
				   COALESCE(als.PartnerID, ope.PartnerID) AS PartnerID
				 , COALESCE(als.PartnerName, ope.PartnerName) AS PartnerName
				 , COALESCE(als.IronOfferID, ope.IronOfferID) AS IronOfferID
				 , COALESCE(als.IronOfferName, ope.IronOfferName) AS IronOfferName
				 , als.Throttling
				 , als.PredictedCardholderVolumes
				 , COALESCE(als.ClientServicesRef,ope.ClientServicesRef) AS ClientServicesRef
				 , OutputTableName
				 , StartDate
				 , EndDate
				 , als.NewCampaign
				 , als.CampaignCycleLength_Weeks
				 , als.SelectionRan
				 , CASE
						WHEN ope.IronOfferID IS NOT NULL THEN 1
						WHEN @IsNewsletterBeingSent = 0 THEN 1
						ELSE 0
				   END AS InOPE
				 , CASE
						WHEN htm.IronOfferID IS NOT NULL THEN 1
						ELSE 0
				   END AS InCampaign_HTM
				 , CASE
						WHEN als.IronOfferID IS NOT NULL THEN 1
						ELSE 0
				   END AS InPreSelection_ALS
			INTO #NonBaseOffersGoingLive
			FROM #CampaignSetup als
			FULL OUTER JOIN #OPE ope
				ON als.IronOfferID=ope.IronOfferID
			LEFT JOIN #IronOffer_Campaign_HTM htm
				ON COALESCE(als.IronOfferID, ope.IronOfferID) = htm.IronOfferID
			
			/*******************************************************************
			***************AcCOUNT for alternate partner records****************
			*******************************************************************/

				INSERT INTO #NonBaseOffersGoingLive
				SELECT p.PartnerID
					 , p.PartnerName
					 , iof.IronOfferID
					 , iof.IronOfferName
					 , nbogl.Throttling
					 , nbogl.PredictedCardholderVolumes
					 , nbogl.ClientServicesRef
					 , nbogl.OutputTableName + '_APR' AS OutputTableName
					 , nbogl.StartDate
					 , nbogl.EndDate
					 , nbogl.NewCampaign
					 , nbogl.CampaignCycleLength_Weeks
					 , nbogl.SelectionRan
					 , nbogl.InOPE
					 , CASE
				 			WHEN htm.ClientServicesRef IS NOT NULL THEN 1
				 			ELSE 0
					   END AS InCampaign_HTM
					 , nbogl.InPreSelection_ALS
				FROM #NonBaseOffersGoingLive nbogl
				LEFT JOIN [APW].[PartnerAlternate] pa
					ON nbogl.PartnerID=pa.AlternatePartnerID
				LEFT JOIN [Relational].[Partner] p
					ON pa.PartnerID=p.PartnerID
				INNER JOIN [Relational].[IronOffer] iof
					ON pa.PartnerID=iof.PartnerID
					AND nbogl.IronOfferName=iof.IronOfferName
				LEFT JOIN [Relational].[IronOffer_Campaign_HTM] htm
					ON iof.IronOfferID = htm.IronOfferID

			/*******************************************************************
			****************Fetch selections counts*****************
			*******************************************************************/


		
			IF OBJECT_ID ('tempdb..#SelectionCounts') IS NOT NULL DROP TABLE #SelectionCounts
			SELECT sc.EmailDate
				 , iof.PartnerID
				 , sc.ClientServicesRef
				 , sc.OutputTableName
				 , sc.IronOfferID
				 , sc.CountSelected
				 , IronOfferName
			INTO #SelectionCounts
			FROM [Selections].[CampaignExecution_SelectionCounts] sc
			INNER JOIN [Relational].[IronOffer] iof
				ON sc.IronOfferID = iof.IronOfferID

			INSERT INTO #SelectionCounts
			SELECT sc.EmailDate
				 , iof.PartnerID
				 , sc.ClientServicesRef
				 , sc.OutputTableName + '_APR' AS OutputTableName
				 , iof.IronOfferID
				 , sc.CountSelected
				 , iof.IronOfferName
			FROM #SelectionCounts sc
			LEFT JOIN [APW].[PartnerAlternate] pa
				ON sc.PartnerID=pa.AlternatePartnerID
			LEFT JOIN [Relational].[Partner] p
				ON pa.PartnerID=p.PartnerID
			INNER JOIN [Relational].[IronOffer] iof
				ON pa.PartnerID=iof.PartnerID
				AND sc.IronOfferName=iof.IronOfferName
			LEFT JOIN [Relational].[IronOffer_Campaign_HTM] htm
				ON iof.IronOfferID = htm.IronOfferID
			WHERE EmailDate > @CheckDate

			/*******************************************************************
			****************Are the Selections ready in Selections*****************
			*******************************************************************/

			IF OBJECT_ID ('tempdb..#SelectionsAndNominatedSelections') IS NOT NULL DROP TABLE #SelectionsAndNominatedSelections
			SELECT DISTINCT 
				   (SELECT Cycle FROM #DateAndCampaignType) AS CycleStart_Email
				 , (SELECT EmailDate FROM #DateAndCampaignType) AS EmailDate
				 , StartDate
				 , EndDate
				 , ogl.PartnerID
				 , ogl.PartnerName
				 , ogl.ClientServicesRef
				 , ogl.OutputTableName
				 , ogl.IronOfferID
				 , ogl.IronOfferName
				 , ogl.Throttling
				 , ogl.PredictedCardholderVolumes
				 , COALESCE(sc.CountSelected, cc.CountFromSelections, 0) AS CountFromSelections
				 , ogl.NewCampaign
				 , ogl.SelectionRan
				 , ogl.CampaignCycleLength_Weeks
				 , ogl.InOPE
				 , ogl.InCampaign_HTM
				 , ogl.InPreSelection_ALS
				 , CASE
						WHEN st.name IS NOT NULL THEN 1
						WHEN st.name IS NULL AND ogl.SelectionRan = 0 AND ogl.NewCampaign = 0 THEN 1
						ELSE 0
				   END AS InSelections
				 , CASE
						WHEN tn.TableName IS NOT NULL THEN 1
						WHEN tn.TableName IS NULL AND ogl.SelectionRan = 0 AND ogl.NewCampaign = 0 THEN 1
						ELSE 0
				   END AS InNomTableNames
				 , CASE
						WHEN opl.IronOfferID IS NOT NULL THEN 1
						WHEN opl.IronOfferID IS NULL AND ogl.SelectionRan = 0 AND ogl.NewCampaign = 0 THEN 1
						ELSE 0
				   END AS InOfferProcessLog
			INTO #SelectionsAndNominatedSelections
			FROM #NonBaseOffersGoingLive ogl
			LEFT JOIN [Warehouse].[iron].[OfferProcessLog] opl
				ON ogl.IronOfferID = opl.IronOfferID
				AND (opl.ProcessedDate IS NULL OR opl.ProcessedDate > DATEADD(Day, -7, (SELECT EmailDate FROM #DateAndCampaignType)))
			LEFT JOIN #SelectionCounts sc
				ON ogl.IronOfferID = sc.IronOfferID
				AND ogl.StartDate = sc.EmailDate
			LEFT JOIN sys.tables st
				ON ogl.OutputTableName = 'Warehouse.Selections.' + st.name
				OR ogl.OutputTableName = '[Warehouse].[Selections].[' + st.name + ']'
			LEFT JOIN [Selections].[CampaignExecution_TableNames] tn
				ON ogl.OutputTableName = tn.TableName
			LEFT JOIN [Selections].[CampaignCounts] cc
				ON ogl.IronOfferID = cc.IronOfferID
				AND ogl.SelectionRan = 0
				AND DATEADD(day, -14, (SELECT EmailDate FROM #DateAndCampaignType)) = cc.EmailDate

			/*************************************************************************
			*************Fetch all releveant IrON Offer Member entires****************
			*************************************************************************/

			DECLARE @MinDate DATE = DATEADD(day, -28, (SELECT MIN(StartDate) FROM #SelectionsAndNominatedSelections))
		
			IF OBJECT_ID ('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
			SELECT IronOfferID
				 , StartDate
				 , EndDate
				 , COUNT(*) AS CountFromIOMCurrent
			INTO #IronOfferMember
			FROM [Relational].[IronOfferMember] iom
			WHERE @MinDate <= StartDate
			AND EXISTS (SELECT *
						FROM #SelectionsAndNominatedSelections sns
						WHERE iom.IronOfferID = sns.IronOfferID)
			GROUP BY IronOfferID
				   , StartDate
				   , EndDate
		
		
			IF OBJECT_ID ('tempdb..#IronOfferMember_Ongoing') IS NOT NULL DROP TABLE #IronOfferMember_Ongoing
			SELECT sns.EmailDate
				 , sns.StartDate
				 , sns.EndDate
				 , sns.IronOfferID
				 , sns.IronOfferName
				 , iom.CountFromIOMCurrent
				 , iom.StartDate AS IronOfferMemberStartDate
			INTO #IronOfferMember_Ongoing
			FROM #SelectionsAndNominatedSelections sns
			INNER JOIN #IronOfferMember iom
				ON sns.IronOfferID = iom.IronOfferID
				AND sns.StartDate = iom.StartDate
					
			IF OBJECT_ID ('tempdb..#IronOfferMember_Previous') IS NOT NULL DROP TABLE #IronOfferMember_Previous
			SELECT iom.EmailDate
				 , iom.StartDate
				 , iom.EndDate
				 , iom.IronOfferID
				 , iom.IronOfferName
				 , iom.CountFromIOMCurrent
				 , iom.IronOfferMemberStartDate
			INTO #IronOfferMember_Previous
			FROM (	SELECT sns.EmailDate
						 , sns.StartDate
						 , sns.EndDate
						 , sns.PartnerName
						 , sns.IronOfferID
						 , sns.IronOfferName
						 , iom.CountFromIOMCurrent
						 , iom.StartDate AS IronOfferMemberStartDate
						 , MAX(iom.StartDate) OVER (PARTITION BY iom.IronOfferID) AS IronOfferMemberStartDate_Max
					FROM #SelectionsAndNominatedSelections sns
					INNER JOIN #IronOfferMember iom
						ON sns.IronOfferID = iom.IronOfferID
						AND sns.EmailDate > iom.StartDate
					WHERE NOT EXISTS (SELECT 1
									  FROM #IronOfferMember_Ongoing iom_o
									  WHERE iom.IronOfferID = iom_o.IronOfferID)) iom
			WHERE iom.IronOfferMemberStartDate = iom.IronOfferMemberStartDate_Max


			/*************************************************************************
			*********************Fetch OfferMemberAdditionsCounts*********************
			*************************************************************************/

			IF OBJECT_ID ('tempdb..#OfferMemberAddition') IS NOT NULL DROP TABLE #OfferMemberAddition
			SELECT oma.IronOfferID
				 , COUNT(DISTINCT CompositeID) AS CountFromOfferMemberAddition
			INTO #OfferMemberAddition
			FROM [iron].[OfferMemberAddition] oma
			WHERE EXISTS (SELECT 1
						  FROM #SelectionsAndNominatedSelections sns
						  WHERE oma.IronOfferID = sns.IronOfferID)
			GROUP BY oma.IronOfferID

					
			/*************************************************************************************
			**** INSERT all entries INTO final table ****
			*************************************************************************************/
		
			IF OBJECT_ID ('tempdb..#FinalCheck') IS NOT NULL DROP TABLE #FinalCheck
			SELECT sns.EmailDate
				 , sns.CycleStart_Email
				 , sns.StartDate
				 , sns.EndDate
				 , sns.PartnerID
				 , sns.PartnerName
				 , sns.ClientServicesRef
				 , sns.OutputTableName
				 , sns.IronOfferID
				 , sns.IronOfferName
				 , sns.Throttling
				 , sns.PredictedCardholderVolumes
				 , sns.NewCampaign
				 , sns.SelectionRan
				 , sns.InOPE
				 , sns.InCampaign_HTM
				 , sns.InPreSelection_ALS
				 , sns.InSelections
				 , sns.InNomTableNames
				 , sns.InOfferProcessLog
				 , CASE
						WHEN sns.InOPE = 0 OR sns.InCampaign_HTM = 0 OR sns.InPreSelection_ALS = 0 OR sns.InSelections = 0 OR sns.InNomTableNames = 0 OR sns.InOfferProcessLog = 0 THEN 1
						ELSE 0
				   END AS MissingInformation
				 , CASE
						WHEN ((sns.NewCampaign = 1 AND sns.EmailDate = sns.StartDate) OR sns.SelectionRan = 1) AND (sns.InOPE = 0 OR sns.InCampaign_HTM = 0 OR sns.InPreSelection_ALS = 0 OR sns.InSelections = 0 OR sns.InNomTableNames = 0) THEN 1
						ELSE 0
				   END AS MissingInformation_PreProcessLog
				 , COALESCE(iomo.CountFromIOMCurrent, iomp.CountFromIOMCurrent, 0) AS CountFromIOMCurrent
				 , sns.CountFromSelections
				 , COALESCE(oma.CountFromOfferMemberAddition, cc.CountFromOfferMemberAddition, 0) AS CountFromOfferMemberAddition
				 , NULL AS CountFromIOMUpcoming
			INTO #FinalCheck
			FROM #SelectionsAndNominatedSelections sns
			LEFT JOIN #IronOfferMember_Ongoing iomo
				ON sns.IronOfferID = iomo.IronOfferID
			LEFT JOIN #IronOfferMember_Previous iomp
				ON sns.IronOfferID = iomp.IronOfferID
			LEFT JOIN #OfferMemberAddition oma
				ON sns.IronOfferID = oma.IronOfferID
			LEFT JOIN Selections.CampaignCounts cc
				ON sns.IronOfferID = cc.IronOfferID
				AND sns.SelectionRan = 0
				AND DATEADD(day, -14, (SELECT EmailDate FROM #DateAndCampaignType)) = cc.EmailDate

		
			/*************************************************************************************
			***Loop through all offers in IrON Offer Member to find previous or current Counts****
			*************************************************************************************/

				DELETE cc
				FROM Selections.CampaignCounts cc
				INNER JOIN #FinalCheck fc
					ON cc.IronOfferID = fc.IronOfferID
					AND cc.EmailDate = fc.EmailDate
		
				INSERT INTO Selections.CampaignCounts
				SELECT EmailDate
					 , CycleStart_Email
					 , PartnerID
					 , PartnerName
					 , ClientServicesRef
					 , OutputTableName
					 , IronOfferID
					 , IronOfferName
					 , COALESCE(Throttling, 0) AS Throttling
					 , COALESCE(PredictedCardholderVolumes, 0) AS PredictedCardholderVolumes
					 , NewCampaign
					 , SelectionRan
					 , CountFromIOMCurrent
					 , CountFromSelections
					 , CountFromOfferMemberAddition
					 , CountFromIOMUpcoming
				FROM #FinalCheck

END