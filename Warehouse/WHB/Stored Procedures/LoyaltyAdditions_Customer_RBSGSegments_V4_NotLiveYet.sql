/*
	Author:				Stuart Barnley

	Date:				2015-07-23

	Purpose:			Code created to update a new table to log the customersegment

	Updates:			Re-written to deal with anomalies in the data (multi segment customers)
						17-11-2016 SB - This table had a fragmented index that wasn't being rebuilt,
										therefore I have added code to do this. Also nolock on original count

*/
CREATE PROCEDURE [WHB].[LoyaltyAdditions_Customer_RBSGSegments_V4_NotLiveYet]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	Declare @TableRows int
	Set @TableRows = (Select Count(*) FROM Relational.Customer_RBSGSegments with (nolock))
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	INSERT INTO staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'Customer_RBSGSegments',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	-------------------------------------------------------------------------------------------------
	-----------------------------------Create Customer Table-----------------------------------------
	-------------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	SELECT	cu.FanID
		,	cu.ActivatedDate
		,	cu.SourceUID
		,	cu.ClubID
		,	ic.ID AS IssuerCustomerID
		,	ROW_NUMBER() OVER(ORDER BY cu.FanID ASC) AS RowNo
	INTO #Customer
	FROM [Relational].[Customer] cu
	LEFT JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
		ON cu.SourceUID = ic.SourceUID
		AND ((cu.ClubID = 138 AND ic.IssuerID = 1) OR (cu.ClubID = 132 AND ic.IssuerID = 2))

	CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)
	CREATE NONCLUSTERED INDEX IX_IssuerCustomerID ON #Customer (IssuerCustomerID)

		
	IF OBJECT_ID('tempdb..#IssuerCustomerAttribute') IS NOT NULL DROP TABLE #IssuerCustomerAttribute
	SELECT	ica.IssuerCustomerID
		,	ica.StartDate
		,	ica.Value
	INTO #IssuerCustomerAttribute
	FROM [SLC_Report].[dbo].[IssuerCustomerAttribute] ica
	WHERE ica.EndDate IS NULL
	AND ica.AttributeID = 1
	AND EXISTS (SELECT 1
				FROM #Customer cu
				WHERE ica.IssuerCustomerID = cu.IssuerCustomerID)

	CREATE CLUSTERED INDEX CIX_IssuerCustomerID ON #IssuerCustomerAttribute (IssuerCustomerID)



	-------------------------------------------------------------------------------------------------
	-----------------------------------Assess for new entries----------------------------------------
	-------------------------------------------------------------------------------------------------

	Declare @LaunchDate as Date
	Set @LaunchDate = '2015-07-20'

	IF OBJECT_ID('tempdb..#CS') IS NOT NULL DROP TABLE #CS
	Create Table #CS (FanID int, CustomerSegment varchar(5), StartDate Date,RowNo tinyint)

	-----------------------------------------------------------------------------------------------------
	----------------------------------------------Find Segments------------------------------------------
	-----------------------------------------------------------------------------------------------------

	INSERT INTO #CS
	Select	a.FanID
		,	CASE
				WHEN a.CustomerSegment IS NULL THEN ''
				WHEN a.CustomerSegment = 'V' THEN 'V'
				ELSE ''
			END AS CustomerSegment
		,	StartDate
		,	ROW_NUMBER() OVER(PARTITION BY a.FanID ORDER BY a.CustomerSegment DESC) AS RowNo
	FROM (	SELECT	DISTINCT
					FanID
				,	ica.Value AS CustomerSegment
				,	CASE
						WHEN ica.IssuerCustomerID IS NULL AND ActivatedDate >= @LaunchDate THEN ActivatedDate
						WHEN ica.IssuerCustomerID IS NULL THEN @LaunchDate
						WHEN ica.StartDate < @Launchdate THEN @LaunchDate
						ELSE ica.StartDate
					END AS StartDate
			FROM #Customer cu
			LEFT JOIN #IssuerCustomerAttribute ica
				on cu.IssuerCustomerID = ica.IssuerCustomerID) a


	-----------------------------------------------------------------------------------------------------
	--------------------------------delete where more than one segment-----------------------------------
	-----------------------------------------------------------------------------------------------------
	DELETE
	FROM #CS
	WHERE RowNo > 1
	-----------------------------------------------------------------------------------------------------
	------------------------------------------Insert new segments----------------------------------------
	-----------------------------------------------------------------------------------------------------
	INSERT INTO Relational.Customer_RBSGSegments
	Select	c.FanID,
			c.CustomerSegment,
			c.StartDate,
			NULL as EndDate
	FROM #CS as c
	LEFT JOIN Relational.Customer_RBSGSegments as cs
		on	c.fanid = cs.fanid and
			cs.enddate IS NULL and
			(CASE
				WHEN c.CustomerSegment <> 'V' or c.CustomerSegment IS NULL THEN ''
				ELSE c.CustomerSegment
			 End) =
					(CASE
							WHEN cs.CustomerSegment <> 'V' or cs.CustomerSegment IS NULL THEN ''
							ELSE cs.CustomerSegment
					 End)
	Where	cs.fanid IS NULL
	-----------------------------------------------------------------------------------------------------
	------------------------------------------Insert new segments----------------------------------------
	-----------------------------------------------------------------------------------------------------
	Update	Relational.Customer_RBSGSegments
	Set		EndDate = dateadd(day,-1,c.StartDate)
	from	Relational.Customer_RBSGSegments as cs
	inner join #CS as c
			on	cs.fanid = c.fanid and
			cs.enddate IS NULL and
			(CASE
				WHEN c.CustomerSegment <> 'V' or c.CustomerSegment IS NULL THEN ''
				ELSE c.CustomerSegment
			 End) <>
					(CASE
							WHEN cs.CustomerSegment <> 'V' or cs.CustomerSegment IS NULL THEN ''
							ELSE cs.CustomerSegment
					 End)
	
	Truncate Table #cs

	Alter Index [ix_Customer_RBSGSegments_FanID_EndDate] ON Relational.Customer_RBSGSegments  REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_RBSGSegments' and
			EndDate IS NULL
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = ((Select COUNT(*) FROM Relational.Customer_RBSGSegments)-@TableRows)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_RBSGSegments' and
			TableRowCount IS NULL

	INSERT INTO staging.JobLog
	select	[StoredProcedureName],
			[TableSchemaName],
			[TableName],
			[StartDate],
			[EndDate],
			[TableRowCount],
			[AppendReload]
	FROM staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

	--(2000934 row(s) affected)
	

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run