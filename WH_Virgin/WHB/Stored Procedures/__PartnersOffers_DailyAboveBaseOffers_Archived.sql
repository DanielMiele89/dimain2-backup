-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[__PartnersOffers_DailyAboveBaseOffers_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'PartnersOffers_DailyAboveBaseOffers', 'Started'

		DECLARE @OutputCount INT = DATEDIFF(DAY,'Jan 01, 2013',GETDATE())+1
 
		IF OBJECT_ID ('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
		WITH 
			E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n)),
			E2 AS (SELECT n = 0 FROM E1 a, E1 b),
			Numbers AS (SELECT TOP(@OutputCount) n = CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS INT) FROM E2 a, E2 b)
		SELECT ID = [Numbers].[n], StartDate = DATEADD(DAY,1-[Numbers].[n],CAST(GETDATE() AS DATE)) 
		INTO #Calendar 
		FROM Numbers
		OPTION (OPTIMIZE FOR (@OutputCount = 2559));

		CREATE UNIQUE CLUSTERED INDEX ucx_Stuff On #Calendar (StartDate);


		TRUNCATE TABLE Derived.Partner_AboveBaseOffers_PerDay
		INSERT INTO Derived.Partner_AboveBaseOffers_PerDay ([Derived].[Partner_AboveBaseOffers_PerDay].[DayDate], [Derived].[Partner_AboveBaseOffers_PerDay].[PartnerID], [Derived].[Partner_AboveBaseOffers_PerDay].[AboveBaseOffer])
		SELECT 
			DayDate = cp.StartDate,
			cp.PartnerID,
			AboveBaseOffer = ISNULL(x.Abovebase,0)
		FROM (SELECT * FROM Derived.[Partner] p CROSS JOIN #Calendar c) cp
		LEFT JOIN (
			SELECT  
				cp.StartDate, i.PartnerID, i.Abovebase
			FROM Derived.IronOffer i
			INNER JOIN #Calendar cp
				ON cp.StartDate BETWEEN i.StartDate AND i.EndDate 
					AND i.Abovebase = 1 
					AND i.IsTriggerOffer = 0 
					AND i.ironofferName <> '(Demo) special offer'
			GROUP BY cp.StartDate, i.PartnerID, i.Abovebase
		) x ON x.PartnerID = cp.PartnerID AND x.StartDate = cp.StartDate;



		
	EXEC [Monitor].[ProcessLog_Insert] 'PartnersOffers_DailyAboveBaseOffers', 'Finished'


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
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END