/******************************************************************************
Author: Stuart Barnley
Created: 09/09/2016
Purpose:
	- Updates the Out of Programme Control group base table (Segmentation.ROC_Shopper_Segment_CtrlGroup)

------------------------------------------------------------------------------
Modification History

SB 27/01/2017
	- Updated to increase OOP Audience Size

12/09/2018
	- Cleaned up by Jason Shipp to make code more readable

******************************************************************************/
CREATE PROCEDURE [Segmentation].[ROC_Shopper_Segmentation_OOP_ControlGroup_Refresh_V2] (@ForceMultipleRefreshWithinCycle BIT = 0)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	/******************************************************************************
	Write entry to Joblog_Temp
	******************************************************************************/
	
		DECLARE 
			@TableName varchar(50)
			, @Today datetime
			, @EndTime datetime;

		SET @TableName = 'ROC_Shopper_Segment_CtrlGroup';
		SET @Today = GETDATE();

		INSERT INTO Staging.JobLog_Temp
		SELECT
			StoredProcedureName = 'ROC_Shopper_Segmentation_OOP_ControlGroup_Refresh'
			, TableSchemaName = 'Segmentation'
			, TableName = @TableName
			, StartDate = @Today
			, EndDate = NULL
			, TableRowCount  = NULL
			, AppendReload = 'A';
	

	/******************************************************************************
	Check how many times program has run in the given cycle
	******************************************************************************/

		DECLARE @ExecutionsWithinCycle INT = 0

		SELECT	@ExecutionsWithinCycle = COUNT(*)
		FROM [Staging].[JobLog] jl
		INNER JOIN [Staging].[ControlSetup_Cycle_Dates] cd
			ON jl.StartDate BETWEEN cd.StartDate AND cd.EndDate
		WHERE StoredProcedureName = 'ROC_Shopper_Segmentation_OOP_ControlGroup_Refresh'
		AND jl.EndDate IS NOT NULL


	/******************************************************************************
	Add end date to those customers who have ever been on MyRewards/CB+
	******************************************************************************/
			
		DECLARE @EndDate DATETIME = DATEADD(day, -1, GETDATE())

		UPDATE cg
		SET EndDate = @EndDate
		FROM [Segmentation].[ROC_Shopper_Segment_CtrlGroup] cg
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[Customer] cu
						WHERE cg.FanID = cu.FanID)
		AND cg.EndDate IS NULL


	/******************************************************************************
	Add new members if running for the first time this cycle
	******************************************************************************/

		IF @ExecutionsWithinCycle = 0 OR @ForceMultipleRefreshWithinCycle = 1
			BEGIN

			/******************************************************************************
			Create customer Table
			******************************************************************************/

				IF OBJECT_ID ('tempdb..#Ctrl') IS NOT NULL DROP TABLE #Ctrl;
				SELECT	TOP (2550000)
						fa.ID AS FanID
					,	cl.CINID
				INTO #Ctrl
				FROM [APW].[ControlAdjusted] a
				INNER JOIN [Relational].[CINList] cl
					ON a.CINID = cl.CINID
				INNER JOIN [SLC_Report].[dbo].[Fan] fa
					ON cl.CIN = fa.SourceUID
				WHERE fa.ClubID IN (132,138)
				AND NOT EXISTS (SELECT 1
								FROM [Relational].[Customer] cu
								WHERE fa.ID = cu.FanID)
				AND NOT EXISTS (SELECT 1
								FROM [Staging].[Customer_DuplicateSourceUID] ds
								WHERE cl.CIN = ds.SourceUID
								AND ds.EndDate IS NULL)
				ORDER BY ABS(CHECKSUM(NEWID()));

				CREATE CLUSTERED INDEX CIX_FanID ON #Ctrl (FanID, CINID);


			/******************************************************************************
			Add end date to those no longer in Ctrl group
			******************************************************************************/

				UPDATE cg
				SET EndDate = @EndDate
				FROM [Segmentation].[ROC_Shopper_Segment_CtrlGroup] cg
				WHERE cg.EndDate IS NULL
				AND NOT EXISTS (SELECT 1
								FROM #Ctrl ct
								WHERE cg.FanID = ct.FanID);


			/******************************************************************************
			Add new members to Ctrl group
			******************************************************************************/

				INSERT INTO [Segmentation].[ROC_Shopper_Segment_CtrlGroup] (FanID, CINID, StartDate, EndDate) 
				SELECT	ct.FanID
					,	ct.CINID
					,	@Today AS StartDate
					,	CAST(NULL AS Date) AS EndDate
				FROM #Ctrl ct
				WHERE NOT EXISTS (	SELECT 1
									FROM [Segmentation].[ROC_Shopper_Segment_CtrlGroup] cg
									WHERE ct.FanID = cg.FanID
									AND cg.EndDate IS NULL)

			END
		
	/******************************************************************************
	Write entry to Joblog_Temp and update Joblog
	******************************************************************************/
	
	SET @EndTime = GETDATE();

	UPDATE Staging.JobLog_Temp
	SET	EndDate = @EndTime
	WHERE
		StoredProcedureName = 'ROC_Shopper_Segmentation_OOP_ControlGroup_Refresh' 
		AND TableSchemaName = 'Segmentation'
		AND TableName = @TableName
		AND EndDate IS NULL;

	INSERT INTO Staging.JobLog
	SELECT
		StoredProcedureName
		, TableSchemaName
		, TableName
		, StartDate
		, EndDate
		, TableRowCount
		, AppendReload
	FROM Staging.JobLog_Temp;

	TRUNCATE TABLE Staging.JobLog_Temp;

END