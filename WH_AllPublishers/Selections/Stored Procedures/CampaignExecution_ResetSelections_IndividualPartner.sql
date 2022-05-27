

/***********************************************************************************************************************
Author:			Rory Francis
Creation Date:	2021-12-20
Purpose:		To remove all selections for a given retailer and update campaign to be ready for rerunning

------------------------------------------------------------------------------------------------------------------------

Modified Log:

Change No:	Name:			Date:			Description of change:

											
***********************************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignExecution_ResetSelections_IndividualPartner]	@EmailDate DATE
																				,	@DatabaseName VARCHAR(25)	--	Warehouse / WH_Virgin / WH_VirginPCA / WH_Visa
																				,	@TableName VARCHAR(25)	--	CampaignSetup_POS / CampaignSetup_DD
																				,	@ClientServicesRef VARCHAR(25)
																				,	@UpdateGivenClientServicesRefOnly BIT
																				,	@RunType BIT = 0
AS
BEGIN

	/*******************************************************************************************************************************************
		1.	Set variables for testing
	*******************************************************************************************************************************************/

		--DECLARE	@EmailDate DATE
		--	,	@DatabaseName VARCHAR(25)		= 'Warehouse'			--	Warehouse / WH_Virgin / WH_VirginPCA / WH_Visa
		--	,	@TableName VARCHAR(25)			= 'CampaignSetup_POS'	--	CampaignSetup_POS / CampaignSetup_DD
		--	,	@ClientServicesRef VARCHAR(10)	= 'HAV'
		--	,	@UpdateGivenClientServicesRefOnly BIT = 0
		--	,	@RunType INT = 0
			
		--SELECT @EmailDate = MIN(EmailDate)
		--FROM [Selections].[CampaignSetup_All]
		--WHERE EmailDate > GETDATE()


	/*******************************************************************************************************************************************
		2.	Pull in all campaign entries matching the ClientServicesRef that has been provided
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CampaignSetup') IS NOT NULL DROP TABLE #CampaignSetup
		SELECT	DatabaseName
			,	TableName
			,	PartnerID
			,	PriorityFlag
			,	ClientServicesRef
			,	CampaignName
			,	StartDate
			,	EndDate
			,	OfferID
			,	OutputTableName
		INTO #CampaignSetup
		FROM [Selections].[CampaignSetup_All]
		WHERE EmailDate = @EmailDate
		AND ClientServicesRef LIKE @ClientServicesRef + '%'
		AND DatabaseName = @DatabaseName
		AND TableName = @TableName
		ORDER BY PriorityFlag


	/*******************************************************************************************************************************************
		3.	Check whether there are mupltiple retailers that have been pulled back by the ClientServicesRef that has been provided.
			If there are then stop the process
	*******************************************************************************************************************************************/

		IF (SELECT COUNT(DISTINCT PartnerID) FROM #CampaignSetup) > 1
			BEGIN
				
				SELECT 'Multiple Retailers Returned, please review the output & adjust the ClientServicesRef parameter'

				SELECT	DISTINCT
						cs.PartnerID
					,	pa.RetailerName
					,	cs.ClientServicesRef
				FROM #CampaignSetup cs
				INNER JOIN [Derived].[Partner] pa
					ON cs.PartnerID = pa.PartnerID

				RETURN

			END


	/*******************************************************************************************************************************************
		4.	Return all campaigns for the given retailer
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CampaignToUpdate') IS NOT NULL DROP TABLE #CampaignToUpdate
		SELECT	DatabaseName = csa.DatabaseName
			,	TableName = csa.TableName
			,	PartnerID = csa.PartnerID
			,	ClientServicesRef = csa.ClientServicesRef
			,	CampaignName = csa.CampaignName
			,	EmailDate = csa.EmailDate
			,	StartDate = csa.StartDate
			,	EndDate = csa.EndDate
			,	IronOfferID = iof.Item
			,	OfferName = o.OfferName
			,	CountSelected = sc.CountSelected
			,	OutputTableName = csa.OutputTableName
			,	InTableNames = CASE WHEN tn.TableID IS NULL THEN 0 ELSE 1 END
			,	InOutputTables = CASE WHEN ot.RowNumber IS NULL THEN 0 ELSE 1 END
		INTO #CampaignToUpdate
		FROM [Selections].[CampaignSetup_ALL] csa
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (csa.OfferID, ',') iof
		LEFT JOIN [Derived].[Offer] o
			ON iof.Item = o.IronOfferID
		LEFT JOIN [Selections].[CampaignExecution_SelectionCounts] sc
			ON iof.Item = sc.IronOfferID
			AND csa.EmailDate = sc.EmailDate
			AND csa.DatabaseName = sc.DatabaseName
		LEFT JOIN [Selections].[CampaignExecution_TableNames] tn
			ON csa.DatabaseName = tn.DatabaseName
			AND tn.TableName LIKE csa.ClientServicesRef + '%'
		LEFT JOIN [Selections].[CampaignExecution_OutputTables] ot
			ON csa.DatabaseName = ot.DatabaseName
			AND ot.OutputTableName = csa.OutputTableName
		WHERE csa.EmailDate = @EmailDate
		AND csa.DatabaseName = @DatabaseName
		AND csa.TableName = @TableName
		AND iof.Item != 0
		AND EXISTS (SELECT 1
					FROM #CampaignSetup cs
					WHERE csa.PartnerID = cs.PartnerID)


	/*******************************************************************************************************************************************
		6.	If only a particular campaign is being reset then remove all entries
	*******************************************************************************************************************************************/

		IF @UpdateGivenClientServicesRefOnly = 1
			BEGIN
				
				DELETE
				FROM #CampaignToUpdate
				WHERE ClientServicesRef != @ClientServicesRef

			END


	/*******************************************************************************************************************************************
		7.	Return all results for review, if the run type is not set to 1 then stop here
	*******************************************************************************************************************************************/

		SELECT	DatabaseName
			,	TableName
			,	PartnerID
			,	ClientServicesRef
			,	CampaignName
			,	EmailDate
			,	StartDate
			,	EndDate
			,	IronOfferID
			,	OfferName
			,	CountSelected
			,	OutputTableName
			,	InTableNames
			,	InOutputTables
		FROM #CampaignToUpdate


	--	If @RunType = 0 then end process here

		IF @RunType = 0 RETURN


	/*******************************************************************************************************************************************
		8.	Update CampaignSetup table
	*******************************************************************************************************************************************/

		UPDATE cs
		SET SelectionRun = 0
		FROM [Warehouse].[Selections].[CampaignSetup_DD] cs
		WHERE @DatabaseName = 'Warehouse'
		AND @TableName = 'CampaignSetup_DD'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE cs.EmailDate = ctu.EmailDate
					AND cs.ClientServicesRef = ctu.ClientServicesRef)
				
		UPDATE cs
		SET SelectionRun = 0
		FROM [Warehouse].[Selections].[CampaignSetup_POS] cs
		WHERE @DatabaseName = 'Warehouse'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE cs.EmailDate = ctu.EmailDate
					AND cs.ClientServicesRef = ctu.ClientServicesRef)

		UPDATE cs
		SET SelectionRun = 0
		FROM [WH_Virgin].[Selections].[CampaignSetup_POS] cs
		WHERE @DatabaseName = 'WH_Virgin'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE cs.EmailDate = ctu.EmailDate
					AND cs.ClientServicesRef = ctu.ClientServicesRef)

		UPDATE cs
		SET SelectionRun = 0
		FROM [WH_VirginPCA].[Selections].[CampaignSetup_POS] cs
		WHERE @DatabaseName = 'WH_VirginPCA'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE cs.EmailDate = ctu.EmailDate
					AND cs.ClientServicesRef = ctu.ClientServicesRef)

		UPDATE cs
		SET SelectionRun = 0
		FROM [WH_Visa].[Selections].[CampaignSetup_POS] cs
		WHERE @DatabaseName = 'WH_Visa'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE cs.EmailDate = ctu.EmailDate
					AND cs.ClientServicesRef = ctu.ClientServicesRef)


	/*******************************************************************************************************************************************
		9.	Remove from selection counts
	*******************************************************************************************************************************************/

		DELETE sc
		FROM [Warehouse].[Selections].[CampaignExecution_SelectionCounts] sc
		WHERE @DatabaseName = 'Warehouse'
		AND @TableName = 'CampaignSetup_DD'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE sc.EmailDate = ctu.EmailDate
					AND sc.ClientServicesRef = ctu.ClientServicesRef)
					
		DELETE sc
		FROM [Warehouse].[Selections].[CampaignExecution_SelectionCounts] sc
		WHERE @DatabaseName = 'Warehouse'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE sc.EmailDate = ctu.EmailDate
					AND sc.ClientServicesRef = ctu.ClientServicesRef)
					
		DELETE sc
		FROM [WH_Virgin].[Selections].[CampaignExecution_SelectionCounts] sc
		WHERE @DatabaseName = 'WH_Virgin'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE sc.EmailDate = ctu.EmailDate
					AND sc.ClientServicesRef = ctu.ClientServicesRef)
					
		DELETE sc
		FROM [WH_VirginPCA].[Selections].[CampaignExecution_SelectionCounts] sc
		WHERE @DatabaseName = 'WH_VirginPCA'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE sc.EmailDate = ctu.EmailDate
					AND sc.ClientServicesRef = ctu.ClientServicesRef)
					
		DELETE sc
		FROM [WH_Visa].[Selections].[CampaignExecution_SelectionCounts] sc
		WHERE @DatabaseName = 'WH_Visa'
		AND @TableName = 'CampaignSetup_POS'
		AND EXISTS (SELECT 1
					FROM #CampaignToUpdate ctu
					WHERE sc.EmailDate = ctu.EmailDate
					AND sc.ClientServicesRef = ctu.ClientServicesRef)


	/*******************************************************************************************************************************************
		10.	Remove selections table
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#RemoveSelection') IS NOT NULL DROP TABLE #RemoveSelection
		SELECT	DISTINCT
				'IF OBJECT_ID(''' + OutputTableName + ''') IS NOT NULL DROP TABLE ' + OutputTableName AS DropStatement
			,	ROW_NUMBER() OVER (ORDER BY OutputTableName) AS TableRank
		INTO #RemoveSelection
		FROM #CampaignToUpdate

		DECLARE @TableRank INT = 1
				, @MaxTableRank INT = (SELECT MAX(TableRank) FROM #RemoveSelection)
				, @DropStatement VARCHAR(MAX)

		WHILE @TableRank <= @MaxTableRank
			BEGIN
				SELECT @DropStatement = DropStatement
				FROM #RemoveSelection
				WHERE TableRank = @TableRank

				EXEC (@DropStatement)

				SET @TableRank = (SELECT MIN(TableRank) FROM #RemoveSelection WHERE TableRank > @TableRank)

			END


	/*******************************************************************************************************************************************
		11.	Remove from [Selections].[CampaignExecution_TableNames]
	*******************************************************************************************************************************************/

		DELETE tn
		FROM [Warehouse].[Selections].[CampaignExecution_TableNames] tn
		WHERE TableName IN (	SELECT	OutputTableName
								FROM #CampaignToUpdate
								UNION ALL
								SELECT	CASE
											WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
											ELSE OutputTableName + '_APR'
										END
								FROM #CampaignToUpdate)
		AND @DatabaseName = 'Warehouse'
				
		DELETE tn
		FROM [WH_Virgin].[Selections].[CampaignExecution_TableNames] tn
		WHERE TableName IN (	SELECT	OutputTableName
								FROM #CampaignToUpdate
								UNION ALL
								SELECT	CASE
											WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
											ELSE OutputTableName + '_APR'
										END
								FROM #CampaignToUpdate)
		AND @DatabaseName = 'WH_Virgin'
				
		DELETE tn
		FROM [WH_VirginPCA].[Selections].[CampaignExecution_TableNames] tn
		WHERE TableName IN (	SELECT	OutputTableName
								FROM #CampaignToUpdate
								UNION ALL
								SELECT	CASE
											WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
											ELSE OutputTableName + '_APR'
										END
								FROM #CampaignToUpdate)
		AND @DatabaseName = 'WH_VirginPCA'
				
		DELETE tn
		FROM [WH_Visa].[Selections].[CampaignExecution_TableNames] tn
		WHERE TableName IN (	SELECT	OutputTableName
								FROM #CampaignToUpdate
								UNION ALL
								SELECT	CASE
											WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
											ELSE OutputTableName + '_APR'
										END
								FROM #CampaignToUpdate)
		AND @DatabaseName = 'WH_Visa'


	/*******************************************************************************************************************************************
		12.	Remove from [Selections].[CampaignExecution_OutputTables]
	*******************************************************************************************************************************************/

		DELETE ot
		FROM [Warehouse].[Selections].[CampaignExecution_OutputTables] ot
		WHERE OutputTableName IN (	SELECT	OutputTableName
									FROM #CampaignToUpdate
									UNION ALL
									SELECT	CASE
												WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
												ELSE OutputTableName + '_APR'
											END
									FROM #CampaignToUpdate)
		AND @DatabaseName = 'Warehouse'
				
		DELETE ot
		FROM [WH_Virgin].[Selections].[CampaignExecution_OutputTables] ot
		WHERE OutputTableName IN (	SELECT	OutputTableName
									FROM #CampaignToUpdate
									UNION ALL
									SELECT	CASE
												WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
												ELSE OutputTableName + '_APR'
											END
									FROM #CampaignToUpdate)
		AND @DatabaseName = 'WH_Virgin'
				
		DELETE ot
		FROM [WH_VirginPCA].[Selections].[CampaignExecution_OutputTables] ot
		WHERE OutputTableName IN (	SELECT	OutputTableName
									FROM #CampaignToUpdate
									UNION ALL
									SELECT	CASE
												WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
												ELSE OutputTableName + '_APR'
											END
									FROM #CampaignToUpdate)
		AND @DatabaseName = 'WH_VirginPCA'
				
		DELETE ot
		FROM [WH_Visa].[Selections].[CampaignExecution_OutputTables] ot
		WHERE OutputTableName IN (	SELECT	OutputTableName
									FROM #CampaignToUpdate
									UNION ALL
									SELECT	CASE
												WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
												ELSE OutputTableName + '_APR'
											END
									FROM #CampaignToUpdate)
		AND @DatabaseName = 'WH_Visa'


	/*******************************************************************************************************************************************
		13.	Remove from Control Group
	*******************************************************************************************************************************************/

		DECLARE @DeletedRows_CG INT = 50000

		WHILE @DeletedRows_CG > 0
			BEGIN

				;WITH
				Deleter AS (SELECT	TOP (50000)
									*
							FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
							WHERE EXISTS (	SELECT 1
											FROM #CampaignToUpdate ctu
											WHERE cg.IronOfferID = ctu.IronOfferID
											AND cg.StartDate = ctu.EmailDate)
							AND @DatabaseName = 'Warehouse')

				DELETE
				FROM Deleter

				SET @DeletedRows_CG = @@ROWCOUNT

			END


	/*******************************************************************************************************************************************
		14.	Remove from Offer Member Additions
	*******************************************************************************************************************************************/

		DECLARE @DeletedRows_OMA INT = 50000

		WHILE @DeletedRows_OMA > 0
			BEGIN

				;WITH
				Deleter AS (SELECT	TOP (50000)
									*
							FROM [Warehouse].[iron].[OfferMemberAddition] oma
							WHERE EXISTS (	SELECT 1
											FROM #CampaignToUpdate ctu
											WHERE oma.IronOfferID = ctu.IronOfferID)
							AND @DatabaseName = 'Warehouse')

				DELETE
				FROM Deleter

				SET @DeletedRows_OMA = @@ROWCOUNT

			END

		SET @DeletedRows_OMA = 50000

		WHILE @DeletedRows_OMA > 0
			BEGIN

				;WITH
				Deleter AS (SELECT	TOP (50000)
									*
							FROM [WH_Virgin].[Segmentation].[OfferMemberAddition] oma
							WHERE EXISTS (	SELECT 1
											FROM #CampaignToUpdate ctu
											WHERE oma.IronOfferID = ctu.IronOfferID)
							AND @DatabaseName = 'WH_Virgin')

				DELETE
				FROM Deleter

				SET @DeletedRows_OMA = @@ROWCOUNT

			END

		SET @DeletedRows_OMA = 50000

		WHILE @DeletedRows_OMA > 0
			BEGIN

				;WITH
				Deleter AS (SELECT	TOP (50000)
									*
							FROM [WH_VirginPCA].[Segmentation].[OfferMemberAddition] oma
							WHERE EXISTS (	SELECT 1
											FROM #CampaignToUpdate ctu
											WHERE oma.IronOfferID = ctu.IronOfferID)
							AND @DatabaseName = 'WH_VirginPCA')

				DELETE
				FROM Deleter

				SET @DeletedRows_OMA = @@ROWCOUNT

			END

		SET @DeletedRows_OMA = 50000

		WHILE @DeletedRows_OMA > 0
			BEGIN

				;WITH
				Deleter AS (SELECT	TOP (50000)
									*
							FROM [WH_Visa].[Segmentation].[OfferMemberAddition] oma
							WHERE EXISTS (	SELECT 1
											FROM #CampaignToUpdate ctu
											WHERE oma.IronOfferID = ctu.IronOfferID)
							AND @DatabaseName = 'WH_Visa')

				DELETE
				FROM Deleter

				SET @DeletedRows_OMA = @@ROWCOUNT

			END
				
END