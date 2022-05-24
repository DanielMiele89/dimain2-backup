/*
	Author:			Stuart Barnley

	Date:			13th April 2016

	Purpose:		To EndDate any Shopper Segments where the customer is no longer active on the
					MyRewards scheme


*/

CREATE PROCEDURE [Segmentation].[Segmentation_CloseDeactivatedCustomers]

AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @time DATETIME = GETDATE()
		  , @msg VARCHAR(2048)
		  , @SSMS BIT = NULL
							
	EXEC [dbo].[oo_TimerMessageV2] 'Process started', @time OUTPUT, @SSMS OUTPUT

	DECLARE @TableName VARCHAR(40)
		  , @RowCount INT

	/*******************************************************************************************************************************************
		1.	Point Of Sale
	*******************************************************************************************************************************************/

		SET @TableName = 'Roc_Shopper_Segment_Members'

			/***********************************************************************************************************************
				1.1.	Write Entry to Joblog_Temp
			***********************************************************************************************************************/

				INSERT INTO Staging.JobLog_Temp
				SELECT StoredProcedureName = 'Segmentation_CloseDeactivatedCustomers'
					 , TableSchemaName = 'Segmentation'
					 , TableName = @TableName
					 , StartDate = GETDATE()
					 , EndDate = NULL
					 , TableRowCount  = NULL
					 , AppendReload = 'U'

			/***********************************************************************************************************************
				1.2.	End Date customers that are no longer active
			***********************************************************************************************************************/

				/***********************************************************************************************************************
					1.2.1.	Create Table of Deactivated Customers
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#Deactivated_POS') IS NOT NULL DROP TABLE #Deactivated_POS
					SELECT FanID
					INTO #Deactivated_POS
					FROM [Relational].[Customer] cu
					WHERE cu.CurrentlyActive = 0

					CREATE CLUSTERED INDEX CIX_FanID ON #Deactivated_POS (FanID)

					SELECT @msg ='Create Table of Deactivated Customers'
					EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


				/***********************************************************************************************************************
					1.2.2.	Fetch Roc_Shopper_Segment_Members IDs of the null End Date rows of Deactivated customers
				***********************************************************************************************************************/

					IF OBJECT_ID ('tempdb..#Updates_POS') IS NOT NULL DROP TABLE #Updates_POS
					SELECT	ssm.ID
						,	ssm.FanID
						,	ssm.PartnerID
						,	ssm.StartDate
					INTO #Updates_POS
					FROM [Segmentation].[Roc_Shopper_Segment_Members] ssm
					WHERE ssm.EndDate IS NULL
					AND EXISTS (SELECT 1
								FROM #Deactivated_POS d
								WHERE d.FanID = ssm.FanID)

					SET @RowCount = @@ROWCOUNT
					
					CREATE CLUSTERED INDEX CIX_ID ON #Updates_POS (ID)
					CREATE NONCLUSTERED INDEX CIX_FanID ON #Updates_POS (FanID)

					SELECT @msg ='Fetch Roc_Shopper_Segment_Members IDs of the null End Date rows of Deactivated customers'
					EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


				/***********************************************************************************************************************
					1.2.3.	Disable indexes on Roc_Shopper_Segment_Members
				***********************************************************************************************************************/

					--ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_Members] DISABLE
					--ALTER INDEX [ix_PartnerID_EndDate] ON [Segmentation].[Roc_Shopper_Segment_Members] DISABLE

					--SELECT @msg ='Disable indexes on Roc_Shopper_Segment_Members'
					--EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


				/***********************************************************************************************************************
					1.2.4.	Update the End Date of the rows fetched above
				***********************************************************************************************************************/
				
					DECLARE @MinID INT
						,	@MaxID INT
						,	@EndDate DATETIME
						,	@Rows INT					

					SELECT	@MinID = MIN(ID)
						,	@MaxID = MAX(ID)
						,	@EndDate = DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 0, 0)
						,	@Rows = 30000
					FROM #Updates_POS

					WHILE @Rows > 0
						BEGIN

							;WITH
							Roc_Shopper_Segment_Members AS (SELECT	TOP 30000
																	[ID]
																,	[FanID]
																,	[PartnerID]
																,	[ShopperSegmentTypeID]
																,	[StartDate]
																,	[EndDate]
															FROM Segmentation.Roc_Shopper_Segment_Members sg
															WHERE EXISTS (SELECT 1
																		  FROM #Updates_POS up
																		  WHERE sg.FanID = up.FanID
																		  AND sg.PartnerID = up.PartnerID)
													--		AND sg.ID BETWEEN @MinID AND @MaxID
															)

							DELETE
							FROM Roc_Shopper_Segment_Members
							OUTPUT	DELETED.[ID]
								,	DELETED.[FanID]
								,	DELETED.[PartnerID]
								,	DELETED.[ShopperSegmentTypeID]
								,	DELETED.[StartDate]
								,	DELETED.[EndDate]
							INTO Segmentation.Roc_Shopper_Segment_Members_Archive

							--;WITH
							--Updater AS (	SELECT	TOP (30000)
							--						ID
							--					,	EndDate
							--				FROM [Segmentation].[Roc_Shopper_Segment_Members] ssm
							--				WHERE EXISTS (SELECT 1
							--							  FROM #Updates_POS up
							--							  WHERE ssm.ID = up.ID)
							--				AND ssm.EndDate IS NULL
							--				AND ssm.ID BETWEEN @MinID AND @MaxID)

							--UPDATE Updater
							--SET EndDate = @EndDate

							SET @Rows = @@ROWCOUNT

						END

					SELECT @msg ='Update the End Date of the rows fetched above'
					EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


				/***********************************************************************************************************************
					1.2.4.	Rebuild indexes on Roc_Shopper_Segment_Members
				***********************************************************************************************************************/

					--ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_Members] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)
					--ALTER INDEX [ix_PartnerID_EndDate] ON [Segmentation].[Roc_Shopper_Segment_Members] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)

					--SELECT @msg ='Rebuild indexes on Roc_Shopper_Segment_Members'
					--EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				1.3. Write Entry to Joblog
			***********************************************************************************************************************/

				UPDATE Staging.JobLog_Temp
				SET EndDate = GETDATE()
				  , TableRowCount = @RowCount
				WHERE StoredProcedureName = 'Segmentation_CloseDeactivatedCustomers' 
				AND TableSchemaName = 'Segmentation'
				AND TableName = @TableName
				AND EndDate IS NULL


				INSERT INTO Staging.JobLog
				SELECT StoredProcedureName
					 , TableSchemaName
					 , TableName
					 , StartDate
					 , EndDate
					 , TableRowCount
					 , AppendReload
				FROM Staging.JobLog_Temp

				TRUNCATE TABLE Staging.JobLog_Temp


	/*******************************************************************************************************************************************
		2. Direct Debit
	*******************************************************************************************************************************************/

		SET @TableName = 'CustomerSegment_DD'

			/***********************************************************************************************************************
				2.1. Write Entry to Joblog_Temp
			***********************************************************************************************************************/

				INSERT INTO Staging.JobLog_Temp
				SELECT StoredProcedureName = 'Segmentation_CloseDeactivatedCustomers'
					 , TableSchemaName = 'Segmentation'
					 , TableName = @TableName
					 , StartDate = GETDATE()
					 , EndDate = NULL
					 , TableRowCount  = NULL
					 , AppendReload = 'U'

			/***********************************************************************************************************************
				2.2.	End Date customers that are no longer active
			***********************************************************************************************************************/

				/***********************************************************************************************************************
					2.2.1.	Create Table of Deactivated Customers
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#Deactivated_DD') IS NOT NULL DROP TABLE #Deactivated_DD
					SELECT FanID
					INTO #Deactivated_DD
					FROM Relational.Customer cu
					WHERE cu.CurrentlyActive = 0

					CREATE CLUSTERED INDEX CIX_FanID ON #Deactivated_DD (FanID)

					SELECT @msg ='Create Table of Deactivated Customers'
					EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

				/***********************************************************************************************************************
					2.2.2.	Fetch CustomerSegment_DD IDs of the null End Date rows of Deactivated customers
				***********************************************************************************************************************/

					IF OBJECT_ID ('tempdb..#Updates_DD') IS NOT NULL DROP TABLE #Updates_DD
					SELECT cs.ID
					INTO #Updates_DD
					FROM #Deactivated_DD d
					INNER JOIN [Segmentation].[CustomerSegment_DD] cs
						ON d.FanID = cs.FanID
						AND cs.EndDate IS NULL

					SET @RowCount = @@ROWCOUNT

					CREATE CLUSTERED INDEX CIX_Updates_ID ON #Updates_DD (ID)

					SELECT @msg ='Fetch CustomerSegment_DD IDs of the null End Date rows of Deactivated customers'
					EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


				/***********************************************************************************************************************
					2.2.3.	Disable indexes on CustomerSegment_DD
				***********************************************************************************************************************/

					--ALTER INDEX [IX_PartnerFan] ON [Segmentation].[CustomerSegment_DD] DISABLE
					--ALTER INDEX [ID_PartnerEndDate] ON [Segmentation].[CustomerSegment_DD] DISABLE

					--SELECT @msg ='Disable indexes on CustomerSegment_DD'
					--EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


				/***********************************************************************************************************************
					2.2.4.	Update the End Date of the rows fetched above
				***********************************************************************************************************************/
				
					--DECLARE @MinID INT
					--	,	@MaxID INT

					SELECT	@MinID = MIN(ID)
						,	@MaxID = MAX(ID)
					FROM #Updates_DD

					UPDATE cs
					SET EndDate = @EndDate
					FROM [Segmentation].[CustomerSegment_DD] cs
					WHERE EXISTS (SELECT 1
								  FROM #Updates_DD up
								  WHERE cs.ID = up.ID)
					AND cs.ID BETWEEN @MinID AND @MaxID

					SELECT @msg ='Update the End Date of the rows fetched above'
					EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


				/***********************************************************************************************************************
					2.2.4.	Disable indexes on CustomerSegment_DD
				***********************************************************************************************************************/

					--ALTER INDEX [IX_PartnerFan] ON [Segmentation].[CustomerSegment_DD] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)
					--ALTER INDEX [ID_PartnerEndDate] ON [Segmentation].[CustomerSegment_DD] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)

					--SELECT @msg ='Rebuild indexes on CustomerSegment_DD'
					--EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				2.3. Write Entry to Joblog
			***********************************************************************************************************************/

				UPDATE Staging.JobLog_Temp
				SET EndDate = GETDATE()
				  , TableRowCount = @RowCount
				WHERE StoredProcedureName = 'Segmentation_CloseDeactivatedCustomers' 
				AND TableSchemaName = 'Segmentation'
				AND TableName = @TableName
				AND EndDate IS NULL


				INSERT INTO Staging.JobLog
				SELECT StoredProcedureName
					 , TableSchemaName
					 , TableName
					 , StartDate
					 , EndDate
					 , TableRowCount
					 , AppendReload
				FROM Staging.JobLog_Temp

				TRUNCATE TABLE Staging.JobLog_Temp

END