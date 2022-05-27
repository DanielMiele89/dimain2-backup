
-- ********************************************************************************************************
-- Author: Suraj Chahal
-- Create date: 12/11/2014
-- Description: Runs each week to populate the Warehouse.Relational.SFD_PostUploadAssessmentData_Member 
--		table for any LionSend IDs which aren't currently stored within it 
-- ********************************************************************************************************
CREATE PROCEDURE [Staging].[Populate_SFDPostUploadAssessmentData_Member]
			
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	INSERT INTO staging.JobLog_Temp
	SELECT	StoredProcedureName = 'Populate_SFDPostUploadAssessmentData_Member',
		TableSchemaName = 'Relational',
		TableName = 'SFD_PostUploadAssessmentData_Member',
		StartDate = GETDATE(),
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = 'A'
	--Counts pre-population
	DECLARE	@RowCount BIGINT
	SET @RowCount = (SELECT COUNT(1) FROM Relational.SFD_PostUploadAssessmentData_Member WITH (NOLOCK))



	IF OBJECT_ID ('tempdb..#MemberLionSendIDs') IS NOT NULL DROP TABLE #MemberLionSendIDs
	SELECT	DISTINCT
		LionSendID
	INTO #MemberLionSendIDs
	FROM Relational.SFD_PostUploadAssessmentData_Member

	CREATE CLUSTERED INDEX IDX_LSID ON #MemberLionSendIDs (LionSendID)



	IF OBJECT_ID ('tempdb..#LionSendsToBeAdded') IS NOT NULL DROP TABLE #LionSendsToBeAdded
	SELECT	ROW_NUMBER() OVER(ORDER BY LionSendID) as RowNo,
		LionSendID
	INTO #LionSendsToBeAdded
	FROM	(
		SELECT	DISTINCT
			sfd.LionSendID
		FROM Relational.SFD_PostUploadAssessmentData sfd
		LEFT OUTER JOIN #MemberLionSendIDs m
			ON sfd.LionSendID = m.LionSendID
		WHERE	m.LionSendID IS NULL
		)a

	ALTER INDEX IDX_FanID ON Relational.SFD_PostUploadAssessmentData_Member DISABLE
	ALTER INDEX IDX_LSID ON Relational.SFD_PostUploadAssessmentData_Member DISABLE
	ALTER INDEX IDX_IOID ON Relational.SFD_PostUploadAssessmentData_Member DISABLE


	/******************************************************************
	**********************Declare the variables************************
	******************************************************************/
	DECLARE @StartRow INT,
		@LionSendID INT,
		@MaxLionSendID INT
	
	SET @StartRow = 1
	SET @LionSendID = (SELECT LionSendID FROM #LionSendsToBeAdded WHERE RowNo = 1)
	SET @MaxLionSendID = (SELECT MAX(LionSendID) FROM #LionSendsToBeAdded)

	WHILE  @LionSendID <= @MaxLionSendID
	BEGIN

		DECLARE @Fan INT,
			@MaxFan INT,
			@Chunksize INT

		SET @Fan = (SELECT MIN([Customer ID]) FROM Relational.SFD_PostUploadAssessmentData WHERE LionSendID = @LionSendID)
		SET @MaxFan = (SELECT MAX([Customer ID]) FROM Relational.SFD_PostUploadAssessmentData WHERE LionSendID = @LionSendID)
		SET @Chunksize = 1000000

		WHILE @Fan < @MaxFan
	
		BEGIN 

			INSERT INTO Relational.SFD_PostUploadAssessmentData_Member
			SELECT	FanID,
				LionSendID,
				OfferSlot,
				IronOfferID
			FROM	(
				SELECT	sfd.[Customer ID] as FanID,
					sfd.LionSendID,
					7 as OfferSlot,
					sfd.Offer7 as IronOfferID
				FROM Relational.SFD_PostUploadAssessmentData sfd
				WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2)
					AND sfd.LionSendID = @LionSendID
			UNION ALL
				SELECT	sfd.[Customer ID] as FanID,
					sfd.LionSendID,
					1 as OfferSlot,
					sfd.Offer1 as IronOfferID
				FROM Relational.SFD_PostUploadAssessmentData sfd
				WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2)
					AND sfd.LionSendID = @LionSendID
			UNION ALL
				SELECT	sfd.[Customer ID] as FanID,
					sfd.LionSendID,
					2 as OfferSlot,
					sfd.Offer2 as IronOfferID
				FROM Relational.SFD_PostUploadAssessmentData sfd
				WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2)
					AND sfd.LionSendID = @LionSendID
			UNION ALL
				SELECT	sfd.[Customer ID] as FanID,
					sfd.LionSendID,
					3 as OfferSlot,
					sfd.Offer3 as IronOfferID
				FROM Relational.SFD_PostUploadAssessmentData sfd
				WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2)
					AND sfd.LionSendID = @LionSendID
			UNION ALL
				SELECT	sfd.[Customer ID] as FanID,
					sfd.LionSendID,
					4 as OfferSlot,
					sfd.Offer4 as IronOfferID
				FROM Relational.SFD_PostUploadAssessmentData sfd
				WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2)
					AND sfd.LionSendID = @LionSendID
			UNION ALL
				SELECT	sfd.[Customer ID] as FanID,
					sfd.LionSendID,
					5 as OfferSlot,
					sfd.Offer5 as IronOfferID
				FROM Relational.SFD_PostUploadAssessmentData sfd
				WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2)
					AND sfd.LionSendID = @LionSendID
			UNION ALL
				SELECT	sfd.[Customer ID] as FanID,
					sfd.LionSendID,
					6 as OfferSlot,
					sfd.Offer6 as IronOfferID
				FROM Relational.SFD_PostUploadAssessmentData sfd
				WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2)
					AND sfd.LionSendID = @LionSendID
				)a
			WHERE a.FanID BETWEEN @Fan AND @Fan+@Chunksize
			ORDER BY a.FanID

			SET @Fan = (@Fan+@Chunksize)+1

		END

	SET @StartRow = @StartRow+1
	SET @LionSendID = (SELECT LionSendID FROM #LionSendsToBeAdded WHERE RowNo = @StartRow)

	END



	ALTER INDEX IDX_FanID ON Relational.SFD_PostUploadAssessmentData_Member REBUILD
	ALTER INDEX IDX_LSID ON Relational.SFD_PostUploadAssessmentData_Member REBUILD
	ALTER INDEX IDX_IOID ON Relational.SFD_PostUploadAssessmentData_Member REBUILD



	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	UPDATE staging.JobLog_Temp
	SET EndDate = GETDATE()
	WHERE	StoredProcedureName = 'Populate_SFDPostUploadAssessmentData_Member' 
		AND TableSchemaName = 'Relational' 
		AND TableName = 'SFD_PostUploadAssessmentData_Member' 
		AND EndDate IS NULL
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	UPDATE staging.JobLog_Temp
	SET TableRowCount = (Select COUNT(1) from Relational.SFD_PostUploadAssessmentData_Member)-@RowCount
	WHERE	StoredProcedureName = 'Populate_SFDPostUploadAssessmentData_Member' 
		AND TableSchemaName = 'Relational' 
		AND TableName = 'SFD_PostUploadAssessmentData_Member' 
		AND TableRowCount IS NULL
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	INSERT INTO staging.JobLog
	SELECT	StoredProcedureName,
		TableSchemaName,
		TableName,
		StartDate,
		EndDate,
		TableRowCount,
		AppendReload
	FROM staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

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

END