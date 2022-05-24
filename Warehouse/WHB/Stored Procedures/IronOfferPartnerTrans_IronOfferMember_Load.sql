/*

	Author:		Rory Francis

	Date:		2019-03-27

	Purpose:	Inert / Update all missing / misaligned rows from SLC_Report..IronOfferMember to Relational.IronOfferMember

	Amendment: 06/08/2021 CJM commented out disable / rebuild ordinary indexes on IOM
			   22/09/2021 CJM changed the batch quantity in the IOM uploader section. Smaller batch size eliminates a sort from the pan, for each ordinary index

*/

CREATE PROCEDURE [WHB].[IronOfferPartnerTrans_IronOfferMember_Load] (	@ImportStartDate DATETIME
																	,	@ImportEndDate DATETIME)
AS
BEGIN

	SET NOCOUNT ON

	--DECLARE @ImportStartDate DATE = GETDATE()-1
	--	,	@ImportEndDate DATE = GETDATE()

	DECLARE	@StartDate DATETIME = @ImportStartDate
		,	@EndDate DATETIME = DATEADD(DAY, 1, @ImportEndDate)
		,	@Time DATETIME
		,	@Msg VARCHAR(2048)
		,	@RowCount INT
		,	@SSMS BIT = NULL
							
	EXEC [Staging].[oo_TimerMessage_V2] 'Process started', @Time OUTPUT 

	--SELECT @StartDate AS StartDate, @EndDate AS EndDate

	/*******************************************************************************************************************************************
		1. Write entry to JobLog_Temp Table
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[JobLog_temp]
		SELECT StoredProcedureName = 'IronOfferPartnerTrans_IronOfferMember_Load'
			 , TableSchemaName = 'Relational'
			 , TableName = 'IronOfferMember'
			 , StartDate = GETDATE()
			 , EndDate = NULL
			 , TableRowCount  = NULL
			 , AppendReload = 'A'
		

	/*******************************************************************************************************************************************
		2. Prepare tables for insert & updates
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Create Table of Customers
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
			SELECT	CompositeID
			INTO #Customers
			FROM [Relational].[Customer]

			CREATE CLUSTERED INDEX CIX_CompositeID ON #Customers (CompositeID) 

			SELECT @Msg = 'Created #Customers Table'
			EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 


		/***********************************************************************************************************************
			2.2. Find all offers with entries created on the date requested
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
			SELECT	IronOfferID
			INTO #Offers
			FROM [Relational].[IronOffer] iof
			WHERE EXISTS (SELECT 1
						  FROM [SLC_Report].[dbo].[IronOfferMember] iom
						  WHERE iof.IronOfferID = iom.IronOfferID
						  AND iom.ImportDate >= @StartDate
						  AND iom.ImportDate < @EndDate)

			CREATE CLUSTERED INDEX CIX_IronOfferID ON #Offers (IronOfferID)

			SELECT @Msg = 'Created #Offers Table'
			EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT  -- 00:00:06
		

		/***********************************************************************************************************************
			2.3. Fetch all rows that are missing from Relational.IronOfferMember
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#IronOfferMember_MissingRows') IS NOT NULL DROP TABLE #IronOfferMember_MissingRows
			SELECT	ioms.IronOfferID
				,	ioms.CompositeID
				,	ioms.StartDate
				,	ioms.EndDate
				,	ioms.ImportDate
			INTO #IronOfferMember_MissingRows
			FROM [SLC_Report].[dbo].[IronOfferMember] ioms
			WHERE ioms.ImportDate BETWEEN @StartDate AND @EndDate
			AND EXISTS (SELECT 1
						FROM #Offers o
						WHERE ioms.IronOfferID = o.IronOfferID)
			AND NOT EXISTS (SELECT 1
							FROM [Relational].[IronOfferMember] iomw
							WHERE ioms.IronOfferID = iomw.IronOfferID
							AND ioms.CompositeID = iomw.CompositeID
							AND ioms.StartDate = iomw.StartDate)

			SET @RowCount = @@ROWCOUNT

			CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOfferMember_MissingRows (IronOfferID)
						
			SELECT @msg = 'Loaded ' + CONVERT(VARCHAR(10), @RowCount) + ' rows missing from [Relational].[IronOfferMember]'
			EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT  -- 00:11:31


		/***********************************************************************************************************************
			2.4. Fetch all rows that have misaligned EndDates in [Relational].[IronOfferMember]
		***********************************************************************************************************************/

			/*******************************************************************************************************************
				2.4.1. Find all Offers with open EndDates in IronOfferMember
			*******************************************************************************************************************/
		
				IF OBJECT_ID('tempdb..#RelationalIOM') IS NOT NULL DROP TABLE #RelationalIOM
				SELECT	*
				INTO #RelationalIOM
				FROM [Relational].[IronOfferMember] iom
				WHERE iom.EndDate IS NULL

				CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #RelationalIOM (IronOfferID, CompositeID, StartDate, EndDate)

				SELECT @Msg = 'Created #RelationalIOM Table - All Relational memberships with NULL EndDates' -- 00:02:34
				EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
		
				IF OBJECT_ID('tempdb..#IronOffer_Dates') IS NOT NULL DROP TABLE #IronOffer_Dates
				SELECT	CONVERT(INT, iof.ID) AS IronOfferID
					,	StartDate
					,	EndDate
					,	ROW_NUMBER() OVER (ORDER BY iof.ID ASC) AS RowNo
				INTO #IronOffer_Dates
				FROM [SLC_Report].[dbo].[IronOffer] iof
				WHERE EXISTS (	SELECT 1
								FROM #RelationalIOM riom
								WHERE iof.ID = riom.IronOfferID)
				AND (EXISTS (	SELECT 1
								FROM [SLC_Report].[dbo].[IronOfferMember] siom
								WHERE iof.ID = siom.IronOfferID
								AND siom.EndDate IS NOT NULL)
				OR iof.EndDate IS NOT NULL)
				
				CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer_Dates (IronOfferID, StartDate, EndDate)

				SELECT @Msg = 'Created #IronOffer_Dates Table - All offers with NULL membership EndDates' -- 00:00:03
				EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
		
				IF OBJECT_ID('tempdb..#SLCIOM') IS NOT NULL DROP TABLE #SLCIOM
				SELECT	*
				INTO #SLCIOM
				FROM [SLC_Report].[dbo].[IronOfferMember] siom
				WHERE EXISTS (	SELECT 1
								FROM #IronOffer_Dates iof
								WHERE siom.IronOfferID = iof.IronOfferID)
				AND siom.EndDate IS NOT NULL
				
				CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #SLCIOM (IronOfferID, CompositeID, StartDate, EndDate)
				
				SELECT @Msg = 'Created #SLCIOM Table - All SLC_Report memberships with NULL EndDates' -- 00:00:04
				EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 


			/*******************************************************************************************************************
				2.4.2. Fetch the corresponding rows with misaligned EndDates
			*******************************************************************************************************************/
			
				DECLARE @Today DATE = GETDATE()

				IF OBJECT_ID('tempdb..#RowsToUpdate') IS NOT NULL DROP TABLE #RowsToUpdate
				SELECT	riom.IronOfferMemberID
					,	riom.IronOfferID
					,	riom.CompositeID
					,	riom.StartDate
					,	riom.EndDate AS EndDate_Relational
					,	riom.ImportDate
					,	iof.EndDate AS EndDate_IronOffer
					,	siom.EndDate AS EndDate_SLC
					,	iof.StartDate AS StartDate_IronOffer
					,	siom.StartDate AS StartDate_SLC
					,	CASE
							WHEN riom.ImportDate < iof.StartDate THEN iof.StartDate
							ELSE CONVERT(DATE, riom.ImportDate)
						END AS UpdatedStartDate
					,	COALESCE(siom.EndDate, iof.EndDate) AS UpdatedEndDate
				INTO #RowsToUpdate
				FROM #RelationalIOM riom
				LEFT JOIN #IronOffer_Dates iof
					ON riom.IronOfferID = iof.IronOfferID
				LEFT JOIN #SLCIOM siom
					ON riom.IronOfferID = siom.IronOfferID
					AND riom.CompositeID = siom.CompositeID
					AND riom.StartDate = siom.StartDate
				WHERE COALESCE(riom.EndDate, '9999-12-31') != COALESCE(siom.EndDate, '9999-12-31')
				OR riom.StartDate IS NULL
				OR (riom.EndDate IS NULL AND iof.EndDate < @Today)

				SET @RowCount = @@ROWCOUNT

				CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #RowsToUpdate (IronOfferID, IronOfferMemberID, UpdatedStartDate, UpdatedEndDate)

				SELECT @msg = 'Loaded ' + CONVERT(VARCHAR(10), @RowCount) + ' rows with EndDates requiring updates in [Relational].[IronOfferMember]' -- 00:00:06
				EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
				PRINT CHAR(10)


	/*******************************************************************************************************************************************
		3. Insert & update to [Relational].[IronOfferMember]
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Loop through Offers updating misaligned EndDates
		***********************************************************************************************************************/
		
			DECLARE	@RowNo INT = 1
				,	@RowNoMax INT = (SELECT MAX(RowNo) FROM #IronOffer_Dates)
				,	@OfferID INT

			WHILE @RowNo <= @RowNoMax
				BEGIN
					SET @OfferID = (SELECT IronOfferID FROM #IronOffer_Dates WHERE RowNo = @RowNo)
				
					UPDATE iomw
					SET iomw.EndDate = rtu.UpdatedEndDate
					  , iomw.StartDate = rtu.UpdatedStartDate
					FROM #RowsToUpdate rtu
					INNER JOIN [Relational].[IronOfferMember] iomw
						ON rtu.IronOfferMemberID = iomw.IronOfferMemberID
					WHERE rtu.IronOfferID = @OfferID

					SET @RowCount = @@ROWCOUNT
	
					SET @RowNo = @RowNo + 1

					SELECT @Msg = 'EndDated ' + CONVERT(VARCHAR(10), @RowCount) + ' rows for IronOfferID ' + CONVERT(VARCHAR(10), @OfferID)
					EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
				END

				PRINT CHAR(10)

		/***********************************************************************************************************************
			3.2.	Fetch counts of rows to import & if over set threshold, disable indexes on [Relational].[IronOfferMember]
		***********************************************************************************************************************/
		
			DECLARE	@RowCount_Total BIGINT = (SELECT COUNT(*) FROM #IronOfferMember_MissingRows)
				,	@RowCount_Inserted BIGINT = 0

			SELECT @msg = 'Fetch counts of rows to import'
			EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 

			IF @RowCount_Total > 3000000
				BEGIN
					--ALTER INDEX [IX_OfferStartComp_End] ON [Relational].[IronOfferMember] DISABLE
					--ALTER INDEX [IX_StartOfferComp_End] ON [Relational].[IronOfferMember] DISABLE

					SELECT @msg = 'Disable indexes on [Relational].[IronOfferMember] as counts of rows to import are over set threshold'
					EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
				END
			
					

		/***********************************************************************************************************************
			3.3. Loop through Offers adding missing rows
		***********************************************************************************************************************/
			
			SET @RowCount = 1300000 -- CJM migration / removes two sorts from the plan
			SET @RowNo = 1

			WHILE @RowCount = 1300000
				BEGIN

					;WITH IronOfferMember_MissingRows AS (
						SELECT TOP(@RowCount) * 
						FROM #IronOfferMember_MissingRows
						ORDER BY IronOfferID)

					DELETE
					FROM IronOfferMember_MissingRows
					OUTPUT DELETED.IronOfferID
						 , DELETED.CompositeID
						 , DELETED.StartDate
						 , DELETED.EndDate
						 , DELETED.ImportDate
					INTO Relational.IronOfferMember

					SET @RowCount = @@ROWCOUNT
					SET @RowCount_Inserted = @RowCount_Inserted + @RowCount
					SET @RowNo = @RowNo + 1

					SELECT @Msg = 'Inserted ' + CONVERT(VARCHAR(15), @RowCount_Inserted) + ' of ' + CONVERT(VARCHAR(15), @RowCount_Total) + ' rows'
					EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
					
					IF (SELECT @RowNo % 10) = 0 AND (SELECT @RowCount_Total - @RowCount_Inserted) > 15000000
						BEGIN
							--ALTER INDEX CIX_IronOfferID ON #IronOfferMember_MissingRows REBUILD
							UPDATE STATISTICS #IronOfferMember_MissingRows
							PRINT CHAR(10)
							SELECT @Msg = 'Index rebuilt on #IronOfferMember_MissingRows'
							EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
							PRINT CHAR(10)
						END
				END
				
			PRINT CHAR(10)

		/***********************************************************************************************************************
			3.4.	If import size was over set threshold, rebuild indexes on [Relational].[IronOfferMember]
		***********************************************************************************************************************/

			IF @RowCount_Total > 3000000
				BEGIN
					--ALTER INDEX [IX_OfferStartComp_End] ON [Relational].[IronOfferMember] REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON, FILLFACTOR = 80)
					--ALTER INDEX [IX_StartOfferComp_End] ON [Relational].[IronOfferMember] REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON, FILLFACTOR = 80)

					SELECT @msg = 'Rebuild indexes on [Relational].[IronOfferMember] as counts of rows to import are over set threshold'
					EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time OUTPUT 
				END


	/*******************************************************************************************************************************************
		5. Update entry in JobLog_Temp Table with End Date
	*******************************************************************************************************************************************/

		UPDATE [Staging].[JobLog_temp]
		SET	EndDate = GETDATE()
		,	TableRowCount = @RowCount_Total
		WHERE StoredProcedureName = 'IronOfferPartnerTrans_IronOfferMember_Load' 
		AND TableSchemaName = 'Relational'
		AND TableName = 'IronofferMember' 
		AND EndDate IS NULL

	/*******************************************************************************************************************************************
		6. Insert entry INTO JobLog
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[JobLog]
		SELECT [StoredProcedureName],
			[TableSchemaName],
			[TableName],
			[StartDate],
			[EndDate],
			[TableRowCount],
			[AppendReload]
		FROM [Staging].[JobLog_temp]

		TRUNCATE TABLE [Staging].[JobLog_Temp]

END

RETURN 0