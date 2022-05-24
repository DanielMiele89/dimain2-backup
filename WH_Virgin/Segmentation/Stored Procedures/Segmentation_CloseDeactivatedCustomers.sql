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

	DECLARE @TableName VARCHAR(40)
		  , @EndDate DATETIME = DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 0, 0)
		  , @RowCount INT

	/*******************************************************************************************************************************************
		1.	Point Of Sale
	*******************************************************************************************************************************************/

		SET @TableName = 'Roc_Shopper_Segment_Members'

			/***********************************************************************************************************************
				1.2.	End Date customers that are no longer active
			***********************************************************************************************************************/

				/***********************************************************************************************************************
					1.2.1.	Create Table of Deactivated Customers
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#Deactivated_POS') IS NOT NULL DROP TABLE #Deactivated_POS
					SELECT FanID
					INTO #Deactivated_POS
					FROM [Derived].[Customer] cu
					WHERE cu.CurrentlyActive = 0

					CREATE CLUSTERED INDEX CIX_FanID ON #Deactivated_POS (FanID)


				/***********************************************************************************************************************
					1.2.2.	Fetch Roc_Shopper_Segment_Members IDs of the null End Date rows of Deactivated customers
				***********************************************************************************************************************/

					IF OBJECT_ID ('tempdb..#Updates_POS') IS NOT NULL DROP TABLE #Updates_POS
					SELECT ssm.ID
					INTO #Updates_POS
					FROM [Segmentation].[Roc_Shopper_Segment_Members] ssm
					WHERE ssm.EndDate IS NULL
					AND EXISTS (SELECT 1
								FROM #Deactivated_POS d
								WHERE d.FanID = ssm.FanID)

					SET @RowCount = @@ROWCOUNT

					CREATE CLUSTERED INDEX CIX_ID ON #Updates_POS (ID)


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

					SELECT	@MinID = MIN(ID)
						,	@MaxID = MAX(ID)
					FROM #Updates_POS
					
					UPDATE ssm
					SET EndDate = @EndDate
					FROM [Segmentation].[Roc_Shopper_Segment_Members] ssm
					WHERE EXISTS (SELECT 1
								  FROM #Updates_POS up
								  WHERE ssm.ID = up.ID)
					AND ssm.ID BETWEEN @MinID AND @MaxID


				/***********************************************************************************************************************
					1.2.4.	Rebuild indexes on Roc_Shopper_Segment_Members
				***********************************************************************************************************************/

					--ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_Members] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)
					--ALTER INDEX [ix_PartnerID_EndDate] ON [Segmentation].[Roc_Shopper_Segment_Members] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON, FILLFACTOR = 70)

					--SELECT @msg ='Rebuild indexes on Roc_Shopper_Segment_Members'
					--EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT



END