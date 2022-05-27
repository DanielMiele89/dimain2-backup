/*

	Author:		Rory Francis

	Date:		2019-03-27

	Purpose:	Inert / Update all missing / misaligned rows from SLC_Report..IronOfferMember to Relational.IronOfferMember

*/

CREATE PROCEDURE [Staging].[WarehouseLoad_IronOfferMembers_DailyBulkLoad_V2] (@DataDate DATETIME)
With Execute as Owner
AS
BEGIN

	SET NOCOUNT ON

	--DECLARE @DataDate DATE = '2019-03-26'
	Declare @SDate DATETIME = @DataDate
		  , @EDate DATETIME = DATEADD(day, 1, @DataDate)
		  , @Time DATETIME
		  , @Msg VARCHAR(2048)
		  , @RowCount INT


	/*******************************************************************************************************************************************
		1. Write entry to JobLog_Temp Table
	*******************************************************************************************************************************************/

		INSERT INTO staging.JobLog_Temp
		SELECT	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_DailyBulkLoad',
				TableSchemaName = 'Relational',
				TableName = 'IronofferMember',
				StartDate = GETDATE(),
				EndDate = null,
				TableRowCount  = null,
				AppendReload = 'A'
		

	/*******************************************************************************************************************************************
		2. Prepare tables for insert & updates
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Create Table of Customers
		***********************************************************************************************************************/

			SELECT @Msg = 'Created #Customers Table - Start'
			EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT

				IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
				SELECT CompositeID
				INTO #Customers
				FROM Relational.Customer

				CREATE CLUSTERED INDEX cix_Customers_CompositeID ON #Customers (CompositeID) 

			SELECT @Msg = 'Created #Customers Table - End'
			EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
			PRINT CHAR(10)
		

		/***********************************************************************************************************************
			2.2. Find all offers with entries created on the date requested
		***********************************************************************************************************************/

			SELECT @Msg = 'Created #Offers Table - Start'
			EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
		
				IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
				SELECT IronOfferID
					 , ROW_NUMBER() OVER (ORDER BY IronOfferID ASC) AS RowNo
				INTO #Offers
				FROM Relational.IronOffer iof
				WHERE EXISTS (SELECT 1
							  FROM SLC_Report.dbo.IronOfferMember iom
							  WHERE iof.IronOfferID = iom.IronOfferID
							  AND iom.ImportDate >= @SDate
							  AND iom.ImportDate <  @EDate)

				CREATE CLUSTERED INDEX CIX_IronOfferID ON #Offers (IronOfferID)

			SELECT @Msg = 'Created #Offers Table - End'
			EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
			PRINT CHAR(10)
		

		/***********************************************************************************************************************
			2.3. Fetch all rows that are missing from Relational.IronOfferMember
		***********************************************************************************************************************/

			SELECT @msg = 'Load rows missing from Relational.IronOfferMember - Start'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
		
				IF OBJECT_ID('tempdb..#IronOfferMember_MissingRows') IS NOT NULL DROP TABLE #IronOfferMember_MissingRows
				SELECT ioms.IronOfferID
					 , ioms.CompositeID
					 , ioms.StartDate
					 , ioms.EndDate
					 , ioms.ImportDate
				INTO #IronOfferMember_MissingRows
				FROM SLC_Report.dbo.IronOfferMember ioms
				WHERE ioms.ImportDate >= @SDate
				AND ioms.ImportDate <  @EDate
				AND EXISTS (SELECT 1
							FROM #Offers o
							WHERE ioms.IronOfferID = o.IronOfferID)
				AND NOT EXISTS (SELECT 1
								FROM Relational.IronOfferMember iomw
								WHERE ioms.IronOfferID = iomw.IronOfferID
								AND ioms.CompositeID = iomw.CompositeID
								AND ioms.StartDate = iomw.StartDate)

				SET @RowCount = @@ROWCOUNT

				CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOfferMember_MissingRows (IronOfferID)
						
			SELECT @msg = 'Loaded ' + CONVERT(VARCHAR(10), @RowCount) + ' rows missing from Relational.IronOfferMember - End'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
			PRINT CHAR(10)


		/***********************************************************************************************************************
			2.4. Fetch all rows that have misaligned EndDates in Relational.IronOfferMember
		***********************************************************************************************************************/

			/*******************************************************************************************************************
				2.4.1. Find all Offers with open EndDates in IronOfferMember
			*******************************************************************************************************************/
		
				SELECT @Msg = 'Created #OffersWithOpenEndDates Table - Start'
				EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
		
					IF OBJECT_ID('tempdb..#RelationalOpenEndDates') IS NOT NULL DROP TABLE #RelationalOpenEndDates
					SELECT IronOfferID
					INTO #RelationalOpenEndDates
					FROM Relational.IronOffer iof
					WHERE EXISTS (SELECT 1
								  FROM Relational.IronOfferMember iomw
								  WHERE iof.IronOfferID = iomw.IronOfferID
								  AND iomw.EndDate IS NULL)

					CREATE CLUSTERED INDEX CIX_IronOfferID ON #RelationalOpenEndDates (IronOfferID)
		
					IF OBJECT_ID('tempdb..#OffersWithOpenEndDates') IS NOT NULL DROP TABLE #OffersWithOpenEndDates
					SELECT IronOfferID
						 , ROW_NUMBER() OVER (ORDER BY IronOfferID ASC) AS RowNo
					INTO #OffersWithOpenEndDates
					FROM #RelationalOpenEndDates iof
					WHERE EXISTS (SELECT 1
								  FROM SLC_Report..IronOfferMember ioms
								  WHERE iof.IronOfferID = ioms.IronOfferID
								  AND ioms.EndDate IS NOT NULL)

					CREATE CLUSTERED INDEX CIX_IronOfferID ON #OffersWithOpenEndDates (IronOfferID)

				SELECT @Msg = 'Created #OffersWithOpenEndDates Table - End'
				EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
				PRINT CHAR(10)

			/*******************************************************************************************************************
				2.4.2. Fetch the corresponding rows with misaligned EndDates
			*******************************************************************************************************************/

				SELECT @msg = 'Load rows with EndDates requiring updates in Relational.IronOfferMember - Start'
				EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
		

					IF OBJECT_ID('tempdb..#IronOfferMember_UpdateEndDate') IS NOT NULL DROP TABLE #IronOfferMember_UpdateEndDate
					SELECT ioms.IronOfferID
						 , ioms.CompositeID
						 , ioms.StartDate
						 , ioms.EndDate
						 , ioms.ImportDate
					INTO #IronOfferMember_UpdateEndDate
					FROM SLC_Report.dbo.IronOfferMember ioms
					WHERE EXISTS (SELECT 1
								  FROM #OffersWithOpenEndDates o
								  WHERE ioms.IronOfferID = o.IronOfferID)
					AND EXISTS (SELECT 1
								FROM Relational.IronOfferMember iomw
								WHERE ioms.IronOfferID = iomw.IronOfferID
								AND ioms.CompositeID = iomw.CompositeID
								AND ioms.StartDate = iomw.StartDate
								AND (ioms.EndDate != iomw.EndDate OR (ioms.EndDate IS NOT NULL AND iomw.EndDate IS NULL)))

					SET @RowCount = @@ROWCOUNT

				CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOfferMember_UpdateEndDate (IronOfferID)

				SELECT @msg = 'Loaded ' + CONVERT(VARCHAR(10), @RowCount) + ' rows with EndDates requiring updates in Relational.IronOfferMember - End'
				EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
				PRINT CHAR(10)


	/*******************************************************************************************************************************************
		3. Insert & update to Relational.IronOfferMember
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Drop columnstore Index
		***********************************************************************************************************************/

			SELECT @Msg = 'Drop ColumnStore Index - Start'
			EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT

				DROP INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember]

			SELECT @Msg = 'Drop ColumnStore Index - End'
			EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
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
					EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
				
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
					EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
					PRINT CHAR(10)
				END


		/***********************************************************************************************************************
			3.3. Loop through Offers updating misaligned EndDates
		***********************************************************************************************************************/

			SET @RowNo = 1
			SET @RowNoMax = (SELECT MAX(RowNo) FROM #OffersWithOpenEndDates)

			WHILE @RowNo <= @RowNoMax
				BEGIN
					SET @OfferID = (SELECT IronOfferID FROM #OffersWithOpenEndDates WHERE RowNo = @RowNo)
	
					SELECT @Msg = 'Update IronOffer ' + CONVERT(VARCHAR(10), @RowNo) + ' of ' + CONVERT(VARCHAR(10), @RowNoMax) + ', ' + CONVERT(VARCHAR(10), @OfferID) + ' - Start'
					EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
				
					UPDATE iomw
					SET iomw.EndDate = ioms.EndDate
					FROM #IronOfferMember_UpdateEndDate ioms
					INNER JOIN Relational.IronOfferMember iomw
						ON ioms.CompositeID = iomw.CompositeID
						AND ioms.IronOfferID = iomw.IronOfferID
						AND ioms.StartDate = iomw.StartDate
					WHERE ioms.IronOfferID = @OfferID

					SET @RowCount = @@ROWCOUNT
					SET @TotalRowCount = @TotalRowCount + @RowCount
	
					SET @RowNo = @RowNo + 1

					SELECT @Msg = 'Updated ' + CONVERT(VARCHAR(10), @RowCount) + ' rows - End'
					EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
					PRINT CHAR(10)
				END


	/*******************************************************************************************************************************************
		4. Recreate previously dropped Index (ColumnStore)
	*******************************************************************************************************************************************/

		SELECT @Msg = 'Recreate ColumnStore Index - Start'
		EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT

			CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember] ([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])

		SELECT @Msg = 'Recreate ColumnStore Index - End'
		EXEC Staging.oo_TimerMessage @Msg, @Time OUTPUT
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