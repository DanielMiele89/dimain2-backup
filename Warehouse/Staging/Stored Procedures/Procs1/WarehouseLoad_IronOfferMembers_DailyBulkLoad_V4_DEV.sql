/*

	Author:		Rory Francis

	Date:		2019-03-27

	Purpose:	Inert / Update all missing / misaligned rows from SLC_Report..IronOfferMember to Relational.IronOfferMember

*/

CREATE PROCEDURE [Staging].[WarehouseLoad_IronOfferMembers_DailyBulkLoad_V4_DEV] (	@ImportStartDate DATETIME
																				 ,	@ImportEndDate DATETIME)
AS
BEGIN

	SET NOCOUNT ON

	--DECLARE @DataDate DATE = '2019-03-26'
	Declare @SDate DATETIME = @ImportStartDate
		  , @EDate DATETIME = DATEADD(day, 1, @ImportEndDate)
		  , @Time DATETIME
		  , @Msg VARCHAR(2048)
		  , @RowCount INT

	SELECT @SDate AS StartDate
		 , @EDate AS EndDate

	/*******************************************************************************************************************************************
		1. Write entry to JobLog_Temp Table
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[JobLog_temp]
		SELECT StoredProcedureName = 'WarehouseLoad_IronOfferMembers_DailyBulkLoad'
			 , TableSchemaName = 'Relational'
			 , TableName = 'IronOfferMember'
			 , StartDate = GETDATE()
			 , EndDate = null
			 , TableRowCount  = null
			 , AppendReload = 'A'
		

	/*******************************************************************************************************************************************
		2. Prepare tables for insert & updates
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Create Table of Customers
		***********************************************************************************************************************/

			SELECT @Msg = 'Created #Customers Table - Start'
			EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT

				IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
				SELECT CompositeID
				INTO #Customers
				FROM [Relational].[Customer]

				CREATE CLUSTERED INDEX cix_Customers_CompositeID ON #Customers (CompositeID) 

			SELECT @Msg = 'Created #Customers Table - End'
			EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
			PRINT CHAR(10)
		

		/***********************************************************************************************************************
			2.2. Find all offers with entries created on the date requested
		***********************************************************************************************************************/

			SELECT @Msg = 'Created #Offers Table - Start'
			EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
		
				IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
				SELECT IronOfferID
					 , ROW_NUMBER() OVER (ORDER BY IronOfferID ASC) AS RowNo
				INTO #Offers
				FROM [Relational].[IronOffer] iof
				WHERE EXISTS (SELECT 1
							  FROM [SLC_Report].[dbo].[IronOfferMember] iom
							  WHERE iof.IronOfferID = iom.IronOfferID
							  AND iom.ImportDate >= @SDate
							  AND iom.ImportDate < @EDate)

				CREATE CLUSTERED INDEX CIX_IronOfferID ON #Offers (IronOfferID)

			SELECT @Msg = 'Created #Offers Table - End'
			EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
			PRINT CHAR(10)
		

		/***********************************************************************************************************************
			2.3. Fetch all rows that are missing from Relational.IronOfferMember
		***********************************************************************************************************************/

			SELECT @msg = 'Load rows missing from Relational.IronOfferMember - Start'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
		
				IF OBJECT_ID('tempdb..#IronOfferMember_MissingRows') IS NOT NULL DROP TABLE #IronOfferMember_MissingRows
				SELECT ioms.IronOfferID
					 , ioms.CompositeID
					 , ioms.StartDate
					 , ioms.EndDate
					 , ioms.ImportDate
				INTO #IronOfferMember_MissingRows
				FROM [SLC_Report].[dbo].[IronOfferMember] ioms
				WHERE ioms.ImportDate >= @SDate
				AND ioms.ImportDate <  @EDate
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
						
			SELECT @msg = 'Loaded ' + CONVERT(VARCHAR(10), @RowCount) + ' rows missing from Relational.IronOfferMember - End'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
			PRINT CHAR(10)


		/***********************************************************************************************************************
			2.4. Fetch all rows that have misaligned EndDates in Relational.IronOfferMember
		***********************************************************************************************************************/

			/*******************************************************************************************************************
				2.4.1. Find all Offers with open EndDates in IronOfferMember
			*******************************************************************************************************************/
		
				SELECT @Msg = 'Created #OffersWithOpenEndDates Table - Start'
				EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT					
		
					IF OBJECT_ID('tempdb..#RelationalIOM') IS NOT NULL DROP TABLE #RelationalIOM
					SELECT *
					INTO #RelationalIOM
					FROM [Relational].[IronOfferMember] iom
					WHERE iom.EndDate IS NULL

					CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #RelationalIOM (IronOfferID, CompositeID, StartDate, EndDate)
		
					IF OBJECT_ID('tempdb..#IronOffer_Dates') IS NOT NULL DROP TABLE #IronOffer_Dates
					SELECT CONVERT(INT, iof.ID) AS IronOfferID
						 , StartDate
						 , EndDate
						 , ROW_NUMBER() OVER (ORDER BY iof.ID ASC) AS RowNo
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
		
					IF OBJECT_ID('tempdb..#SLCIOM') IS NOT NULL DROP TABLE #SLCIOM
					SELECT *
					INTO #SLCIOM
					FROM [SLC_Report].[dbo].[IronOfferMember] siom
					WHERE EXISTS (	SELECT 1
									FROM #IronOffer_Dates iof
									WHERE siom.IronOfferID = iof.IronOfferID)
					AND siom.EndDate IS NOT NULL
					
					CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #SLCIOM (IronOfferID, CompositeID, StartDate, EndDate)

				SELECT @Msg = 'Created #OffersWithOpenEndDates Table - End'
				EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
				PRINT CHAR(10)

			/*******************************************************************************************************************
				2.4.2. Fetch the corresponding rows with misaligned EndDates
			*******************************************************************************************************************/

				SELECT @msg = 'Load rows with EndDates requiring updates in Relational.IronOfferMember - Start'
				EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
		
					DECLARE @Today DATE = GETDATE()

					IF OBJECT_ID('tempdb..#RowsToUpdate') IS NOT NULL DROP TABLE #RowsToUpdate
					SELECT riom.IronOfferMemberID
						 , riom.IronOfferID
						 , riom.CompositeID
						 , riom.StartDate
						 , riom.EndDate AS EndDate_Relational
						 , riom.ImportDate
						 , iof.EndDate AS EndDate_IronOffer
						 , siom.EndDate AS EndDate_SLC
						 , iof.StartDate AS StartDate_IronOffer
						 , siom.StartDate AS StartDate_SLC
						 , CASE
								WHEN riom.ImportDate < iof.StartDate THEN iof.StartDate
								ELSE CONVERT(DATE, riom.ImportDate)
						   END AS UpdatedStartDate
						 , COALESCE(siom.EndDate, iof.EndDate) AS UpdatedEndDate
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

				SELECT @msg = 'Loaded ' + CONVERT(VARCHAR(10), @RowCount) + ' rows with EndDates requiring updates in Relational.IronOfferMember - End'
				EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
				PRINT CHAR(10)


	/*******************************************************************************************************************************************
		3. Insert & update to Relational.IronOfferMember
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Drop columnstore Index
		***********************************************************************************************************************/

			SELECT @Msg = 'Drop ColumnStore Index - Start'
			EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT

				DROP INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember]

			SELECT @Msg = 'Drop ColumnStore Index - End'
			EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
			PRINT CHAR(10)


		/***********************************************************************************************************************
			3.2. Loop through Offers adding missing rows
		***********************************************************************************************************************/
		
			DECLARE @OfferID INT
				  , @RowNo INT = 1
				  , @RowNoMax INT = (SELECT MAX(RowNo) FROM #Offers)
				  , @TotalRowCount INT = 0

			WHILE @RowNo <= @RowNoMax
				BEGIN
					SET @OfferID = (SELECT IronOfferID FROM #Offers WHERE RowNo = @RowNo)
	
					SELECT @Msg = 'Insert IronOffer ' + CONVERT(VARCHAR(10), @RowNo) + ' of ' + CONVERT(VARCHAR(10), @RowNoMax) + ', ' + CONVERT(VARCHAR(10), @OfferID) + ' - Start'
					EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
				
					DELETE
					FROM #IronOfferMember_MissingRows
					OUTPUT DELETED.IronOfferID
						 , DELETED.CompositeID
						 , DELETED.StartDate
						 , DELETED.EndDate
						 , DELETED.ImportDate
					INTO Relational.IronOfferMember
					WHERE IronOfferID = @OfferID

					SET @RowCount = @@ROWCOUNT
					SET @TotalRowCount = @TotalRowCount + @RowCount
	
					SET @RowNo = @RowNo + 1

					SELECT @Msg = 'Inserted ' + CONVERT(VARCHAR(10), @RowCount) + ' rows - End'
					EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
					PRINT CHAR(10)
				END


		/***********************************************************************************************************************
			3.3. Loop through Offers updating misaligned EndDates
		***********************************************************************************************************************/
		
			SET @RowNo = 1
			SET @RowNoMax = (SELECT MAX(RowNo) FROM #IronOffer_Dates)

			WHILE @RowNo <= @RowNoMax
				BEGIN
					SET @OfferID = (SELECT IronOfferID FROM #IronOffer_Dates WHERE RowNo = @RowNo)
	
					SELECT @Msg = 'Update IronOffer ' + CONVERT(VARCHAR(10), @RowNo) + ' of ' + CONVERT(VARCHAR(10), @RowNoMax) + ', ' + CONVERT(VARCHAR(10), @OfferID) + ' - Start'
					EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
				
					UPDATE iomw
					SET iomw.EndDate = rtu.UpdatedEndDate
					  , iomw.StartDate = rtu.UpdatedStartDate
					FROM #RowsToUpdate rtu
					INNER JOIN Relational.IronOfferMember iomw
						ON rtu.IronOfferMemberID = iomw.IronOfferMemberID
					WHERE rtu.IronOfferID = @OfferID

					SET @RowCount = @@ROWCOUNT
					SET @TotalRowCount = @TotalRowCount + @RowCount
	
					SET @RowNo = @RowNo + 1

					SELECT @Msg = 'Updated ' + CONVERT(VARCHAR(10), @RowCount) + ' rows - End'
					EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
					PRINT CHAR(10)
				END


	/*******************************************************************************************************************************************
		4. Recreate previously dropped Index (ColumnStore)
	*******************************************************************************************************************************************/

		SELECT @Msg = 'Recreate ColumnStore Index - Start'
		EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT

			CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember] ([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])

		SELECT @Msg = 'Recreate ColumnStore Index - End'
		EXEC [Staging].[oo_TimerMessage] @Msg, @Time OUTPUT
		PRINT CHAR(10)


	/*******************************************************************************************************************************************
		5. Update entry in JobLog_Temp Table with End Date
	*******************************************************************************************************************************************/

		UPDATE staging.JobLog_Temp
		SET		EndDate = GETDATE(),
				TableRowCount = @TotalRowCount
		WHERE	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_DailyBulkLoad' 
			AND TableSchemaName = 'Relational'
			AND TableName = 'IronofferMember' 
			AND EndDate IS NULL


	/*******************************************************************************************************************************************
		6. Insert entry INTO JobLog
	*******************************************************************************************************************************************/

		INSERT INTO staging.JobLog
		SELECT [StoredProcedureName],
			[TableSchemaName],
			[TableName],
			[StartDate],
			[EndDate],
			[TableRowCount],
			[AppendReload]
		FROM staging.JobLog_Temp

		TRUNCATE TABLE staging.JobLog_Temp

END