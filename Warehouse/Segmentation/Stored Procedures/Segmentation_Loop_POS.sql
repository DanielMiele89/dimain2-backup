/*

	Author:		Stuart Barnley

	Date:		18th December 2017

	Purpose:	To Run ALS Shopper Segments AS needed

*/
CREATE PROCEDURE [Segmentation].[Segmentation_Loop_POS] (@EmailDate DATE
													,	@PartnerID INT = NULL)
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN

	DECLARE	@time DATETIME
		,	@msg VARCHAR(2048)
		,	@SSMS BIT = NULL

	SET @msg = 'Segmentation_Loop_POS has now begun'
	EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		1. Write Entry to JobLog
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[JobLog_temp]
		SELECT	StoredProcedureName = 'Segmentation_Loop_POS'
			,	TableSchemaName = 'Segmentation'
			,	TableName = ''
			,	StartDate = GETDATE()
			,	EndDate = NULL
			,	TableRowCount  = NULL
			,	AppendReload = NULL

			--DECLARE @EmailDate DATE = '2022-03-24'
			--	,	@PartnerID INT = 4162


	/*******************************************************************************************************************************************
		2. Fetch all partner settings and place to holding table
	*******************************************************************************************************************************************/

		IF OBJECT_ID('Tempdb..#PartnerSettings') IS NOT NULL DROP TABLE #PartnerSettings
		SELECT	PartnerID
			,	IsPos = MAX(IsPos)
			,	IsDD = MAX(IsDD)
		INTO #PartnerSettings
		FROM (	SELECT	PartnerID = ps.PartnerID
	  				,	IsPos = 1
	  				,	IsDD = 0
				FROM [Segmentation].[ROC_Shopper_Segment_Partner_Settings] ps
				WHERE ps.StartDate <= @EmailDate
				AND (ps.EndDate IS NULL OR ps.EndDate > @EmailDate)
				UNION ALL
				SELECT	PartnerID = ps.PartnerID
	  				,	IsPos = 0
	  				,	IsDD = 1
				FROM [Segmentation].[PartnerSettings_DD] ps
				WHERE ps.StartDate <= @EmailDate
				AND (ps.EndDate IS NULL OR ps.EndDate > @EmailDate)) ps
		GROUP BY	PartnerID

	/*******************************************************************************************************************************************
		3. Find campaigns that will be running
	*******************************************************************************************************************************************/

		IF OBJECT_ID('Tempdb..#UpcomingCampaigns') IS NOT NULL DROP TABLE #UpcomingCampaigns
		SELECT	PartnerID = cs.PartnerID
			,	IsPOS = MAX(cs.IsPOS)
			,	IsDD = MAX(cs.IsDD)
		INTO #UpcomingCampaigns
		FROM (	SELECT	PartnerID = cs.PartnerID
					,	IsPOS = 1
					,	IsDD = 0
				FROM [Selections].[CampaignSetup_POS] cs
				WHERE cs.EmailDate = @EmailDate
				UNION
				SELECT	PartnerID = cs.PartnerID
					,	IsPOS = 0
					,	IsDD = 1
				FROM [Selections].[CampaignSetup_DD] cs
				WHERE cs.EmailDate = @EmailDate) cs
		GROUP BY	cs.PartnerID


	/*******************************************************************************************************************************************
		4. Find Partners that are set to run a campaign that they don't have segmentation settings for
	*******************************************************************************************************************************************/
		
		DECLARE @RetailerList VARCHAR(MAX) = ''

		SELECT	@RetailerList = STUFF((	SELECT ', ' + pa.RetailerName
										FROM #UpcomingCampaigns uc
										INNER JOIN [WH_AllPublishers].[Derived].[Partner] pa
											ON uc.PartnerID = pa.PartnerID
										WHERE EXISTS (	SELECT 1
														FROM #PartnerSettings ps
														WHERE uc.PartnerID = ps.PartnerID
														AND (uc.IsDD > ps.IsDD OR uc.IsPOS > ps.IsPOS)
														)
										ORDER BY pa.RetailerName
										FOR XML PATH ('')), 1, 1, '')

		IF LEN(@RetailerList) > 0
			BEGIN

				DECLARE	@Message VarChar(MAX)

				SET @Message = 'The following retailers have either a DD or POS campaign set to run but do not have the segmet settings set for them:<br><br>' + @RetailerList
				
				
				EXEC [msdb].[dbo].[sp_send_dbmail]	@profile_name = 'Administrator'
												,	@recipients= 'DataOperations@RewardInsight.com'
												,	@subject = 'Retailers With Segmentation Settings Missing'
												,	@body= @Message
												,	@body_format = 'HTML'
												,	@importance = 'HIGH'

			END


	/*******************************************************************************************************************************************
		5. Find Partners that have settings corerctly added
	*******************************************************************************************************************************************/

		TRUNCATE TABLE [Segmentation].[PartnersToSegment]
		INSERT INTO [Segmentation].[PartnersToSegment] WITH (HOLDLOCK)
		SELECT	PartnerID = uc.PartnerID
			,	BrandID = pa.BrandID
			,	IsDD = uc.IsDD
			,	IsPOS = uc.IsPOS
			,	RowNo = ROW_NUMBER() OVER (ORDER BY uc.IsDD, uc.IsPOS DESC, uc.PartnerID ASC)
		FROM #UpcomingCampaigns uc
		LEFT JOIN [WH_AllPublishers].[Derived].[Partner] pa
			ON uc.PartnerID = pa.PartnerID
		WHERE EXISTS (	SELECT 1
						FROM #PartnerSettings ps
						WHERE uc.PartnerID = ps.PartnerID
						AND uc.IsDD <= ps.IsDD
						AND uc.IsPOS <= ps.IsPOS)
		AND @PartnerID IS NULL
		
		INSERT INTO [Segmentation].[PartnersToSegment] WITH (HOLDLOCK)
		SELECT	PartnerID = uc.PartnerID
			,	BrandID = pa.BrandID
			,	IsDD = uc.IsDD
			,	IsPOS = uc.IsPOS
			,	RowNo = ROW_NUMBER() OVER (ORDER BY uc.IsDD, uc.IsPOS DESC, uc.PartnerID ASC)
		FROM #UpcomingCampaigns uc
		LEFT JOIN [WH_AllPublishers].[Derived].[Partner] pa
			ON uc.PartnerID = pa.PartnerID
		WHERE EXISTS (	SELECT 1
						FROM #PartnerSettings ps
						WHERE uc.PartnerID = ps.PartnerID
						AND uc.IsDD <= ps.IsDD
						AND uc.IsPOS <= ps.IsPOS)
		AND @PartnerID = pa.PartnerID

		SET @msg = '[Segmentation].[PartnersToSegment] has populated'
		EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		6. Prepare tables for execution loop
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			6.1. Fetch customer details where customers have CINIDs
		***********************************************************************************************************************/
					
			TRUNCATE TABLE [Segmentation].[CustomersWithCINs]
			INSERT INTO [Segmentation].[CustomersWithCINs] WITH (HOLDLOCK)
			SELECT cu.FanID
				 , cl.CINID
			FROM [Relational].[Customer] cu WITH (NOLOCK)
			INNER JOIN [Relational].[CINList] cl WITH (NOLOCK)
				ON cu.SourceUID = cl.CIN
			WHERE cu.CurrentlyActive = 1

			SET @msg = '[Segmentation].[CustomersWithCINs] has populated'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

			
		/***********************************************************************************************************************
			6.2. Fetch all customer details
		***********************************************************************************************************************/
			
			TRUNCATE TABLE [Segmentation].[AllCustomers]
			INSERT INTO [Segmentation].[AllCustomers] WITH (HOLDLOCK)
			SELECT	FanID = cu.FanID
			FROM [Relational].[Customer] cu WITH (NOLOCK)
			WHERE cu.CurrentlyActive = 1

			SET @msg = '[Segmentation].[AllCustomers] has populated'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

			
		/***********************************************************************************************************************
			6.3. Fetch all Combinations
		***********************************************************************************************************************/
						
			TRUNCATE TABLE [Segmentation].[ConsumerCombinationsToSegment]
			INSERT INTO [Segmentation].[ConsumerCombinationsToSegment] WITH (HOLDLOCK) (PartnerID
																					,	ConsumerCombinationID)
			SELECT	PartnerID = pts.PartnerID
				,	ConsumerCombinationID = cc.ConsumerCombinationID
			FROM [Relational].[ConsumerCombination] cc WITH (NOLOCK)
			INNER JOIN [Segmentation].[PartnersToSegment] pts WITH (HOLDLOCK)
				ON cc.BrandID = pts.BrandID

			INSERT INTO [Segmentation].[ConsumerCombinationsToSegment] WITH (HOLDLOCK) (PartnerID
																					,	ConsumerCombinationID)
			SELECT	PartnerID = 4938
				,	ConsumerCombinationID = cc.ConsumerCombinationID
			FROM [Relational].[ConsumerCombination] cc WITH (NOLOCK)
			WHERE EXISTS (	SELECT 1
							FROM [SLC_REPL].[dbo].[RetailOutlet] ro
							INNER JOIN [Segmentation].[PartnersToSegment] pts
								ON ro.PartnerID = pts.PartnerID
							WHERE ro.PartnerID = 4938
							AND cc.MID = ro.MerchantID)

			SET @msg = '[Segmentation].[ConsumerCombinationsToSegment] has populated'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

			
		/***********************************************************************************************************************
			6.4.	Fetch all transactions
		***********************************************************************************************************************/
		
			TRUNCATE TABLE [Segmentation].[ConsumerTransactionsToSegment]
			INSERT INTO [Segmentation].[ConsumerTransactionsToSegment] WITH (HOLDLOCK) (PartnerID
																					,	FanID
																					,	LastTran)
			SELECT	PartnerID = cc.PartnerID
				,	FanID = cu.FanID
				,	LastTran = MAX(TranDate)
			FROM [Relational].[ConsumerTransaction_MyRewards] ct WITH (NOLOCK)
			INNER JOIN [Segmentation].[CustomersWithCINs] cu WITH (HOLDLOCK)
				ON	ct.CINID = cu.CINID
			INNER JOIN [Segmentation].[ConsumerCombinationsToSegment] cc
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
			WHERE ct.Amount > 0
			GROUP BY	cc.PartnerID
					,	cu.FanID
			OPTION (RECOMPILE)

			SET @msg = '[Segmentation].[ConsumerTransactionsToSegment] has populated'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		7. Find Partners that have settings corerctly added
	*******************************************************************************************************************************************/

		DECLARE @RowNo INT = 1
			  , @RowNoMax INT = (SELECT COALESCE(MAX(RowNo), 0) FROM [Segmentation].[PartnersToSegment])
			  , @PartnerID_Loop INT
			  , @IsDD INT
			  , @IsPOS INT

		WHILE @RowNo <= @RowNoMax
		BEGIN
		  
			SELECT @PartnerID_Loop = PartnerID
				 , @IsDD = IsDD
				 , @IsPOS = IsPOS
			FROM [Segmentation].[PartnersToSegment]
			WHERE RowNo = @RowNo
		
			IF @IsPOS = 1 EXEC [Segmentation].[Segmentation_IndividualPartner_POS] @PartnerID_Loop
			IF @IsDD = 1 EXEC [Segmentation].[Segmentation_IndividualPartner_DD] @PartnerID_Loop, 1, 1, 56, 1	--	PartnerID, ToBeRanked, ExlcudeNewJoiners, NewJoinerLength_Days, WeekyRun

			SET @RowNo = @RowNo+1

		END


	/*******************************************************************************************************************************************
		8. Clear down tables after execution loop
	*******************************************************************************************************************************************/
	
		TRUNCATE TABLE [Segmentation].[CustomersWithCINs]
		TRUNCATE TABLE [Segmentation].[AllCustomers]
		TRUNCATE TABLE [Segmentation].[PartnersToSegment]
		TRUNCATE TABLE [Segmentation].[ConsumerCombinationsToSegment]
		TRUNCATE TABLE [Segmentation].[ConsumerTransactionsToSegment]
			

	/*******************************************************************************************************************************************
		9. Update entry in JobLogTemp TABLE with End DATE
	*******************************************************************************************************************************************/

		UPDATE [Staging].[JobLog_temp]
		SET EndDate = GETDATE()
		WHERE StoredProcedureName = 'Segmentation_Loop_POS'
		AND TableSchemaName = 'Segmentation'
		AND TableName = ''
		AND EndDate IS NULL


	/*******************************************************************************************************************************************
		10. Update entry in JobLog TABLE with Row Count
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[JobLog]
		SELECT	[StoredProcedureName]
			,	[TABLESchemaName]
			,	[TABLEName]
			,	[StartDate]
			,	[EndDate]
			,	[TABLERowCount]
			,	[AppendReload]
		FROM [Staging].[JobLog_temp]

		TRUNCATE TABLE [Staging].[JobLog_temp]

END

RETURN 0