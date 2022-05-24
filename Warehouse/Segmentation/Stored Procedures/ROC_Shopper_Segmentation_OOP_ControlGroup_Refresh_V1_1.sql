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
CREATE PROCEDURE Segmentation.ROC_Shopper_Segmentation_OOP_ControlGroup_Refresh_V1_1
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE 
		@TableName varchar(50)
		, @Today datetime
		, @EndTime datetime;

	SET @TableName = 'ROC_Shopper_Segment_CtrlGroup';
	SET @Today = GETDATE();
	
	/******************************************************************************
	Write entry to Joblog_Temp
	******************************************************************************/

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
	Create customer Table
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#Ctrl') IS NOT NULL DROP TABLE #Ctrl;

	SELECT TOP (2550000)
		f.ID AS FanID
		, cl.CINID
	INTO #Ctrl
	FROM APW.ControlAdjusted a
	INNER JOIN Relational.CinList cl
		ON a.CINID = cl.CINID
	LEFT JOIN Staging.Customer_DuplicateSourceUID s
		ON cl.cin = s.SourceUID
		AND s.EndDate is null
	INNER JOIN SLC_Report.dbo.Fan f
		ON cl.CIN = f.SourceUID
	WHERE
		s.SourceUID IS NULL
		AND ClubID IN (132,138)
	ORDER BY 
		NewID();

	/******************************************************************************
	Remove customers who have ever been on MyRewards/CB+
	******************************************************************************/

	DELETE FROM a
	FROM #Ctrl a
	INNER JOIN Relational.Customer b
		ON a.FanID = b.FanID;

	/******************************************************************************
	Add end date to those no longer in Ctrl group
	******************************************************************************/

	UPDATE a
	SET EndDate = DATEADD(day, -1, GETDATE())
	FROM Segmentation.ROC_Shopper_Segment_CtrlGroup a
	LEFT JOIN #Ctrl c
		ON a.FanID = c.FanID
	WHERE 
		a.EndDate IS NULL
		AND c.FanID IS NULL;

	/******************************************************************************
	Add new members to Ctrl group
	******************************************************************************/

	INSERT INTO Segmentation.ROC_Shopper_Segment_CtrlGroup (FanID, CINID, StartDate, EndDate) 
	SELECT 
		c.FanID
		, c.CINID
		, GETDATE() AS StartDate
		, CAST(NULL AS Date) AS EndDate
	FROM #Ctrl c
	LEFT JOIN Segmentation.ROC_Shopper_Segment_CtrlGroup a
		ON c.FanID = a.FanID
		AND a.EndDate IS NULL
	WHERE
		a.FanID IS NULL;

	SET @EndTime = GETDATE();

	/******************************************************************************
	Write entry to Joblog_Temp and update Joblog
	******************************************************************************/

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