-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[Customer_GenderNameDictionary]
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	
	DECLARE @StoredProcedureName VARCHAR(100) = OBJECT_NAME(@@PROCID)
		,	@msg VARCHAR(200)
		,	@RowsAffected INT
		,	@Query VARCHAR(MAX)

	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Started'

	BEGIN TRY

		/*******************************************************************************************************************************************
			1.	Use the MyRewards customers to infer the most likely gender for every name
		*******************************************************************************************************************************************/

			DECLARE @Boundary FLOAT = 0.8

			IF OBJECT_ID('tempdb..#NameGender') IS NOT NULL DROP TABLE #NameGender;
			WITH
			NameGenderCounts AS (	SELECT	FirstName
										,	SUM(CASE WHEN Gender = 'M' THEN 1 ELSE 0 END) AS Males
										,	SUM(CASE WHEN Gender = 'F' THEN 1 ELSE 0 END) AS Females
										,	SUM(CASE WHEN Gender NOT IN ('M', 'F') THEN 1 ELSE 0 END) AS Unknowns
										,	COUNT(*) AS Total
									FROM [Warehouse].[Relational].[Customer]
									GROUP BY FirstName)
			SELECT	FirstName
				,	Males
				,	Females
				,	Unknowns
				,	Total
				,	Males * 1.0 / Total AS PercentageMale
				,	Females * 1.0 / Total AS PercentageFemale
				,	CASE
						WHEN @Boundary <= Males * 1.0 / Total THEN 'M'
						WHEN @Boundary <= Females * 1.0 / Total THEN 'F'
						ELSE 'U'
					END AS InferredGender
			INTO #NameGender
			FROM NameGenderCounts

			CREATE CLUSTERED INDEX CIX_FirstName ON #NameGender (FirstName)


		/*******************************************************************************************************************************************
			2.	Populate table
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				2.1. Update EndDate of First Name entries which have changed gender
			***********************************************************************************************************************/
				
				DECLARE @EndDate DATE = DATEADD(DAY, -1, GETDATE())

				UPDATE ngd
				SET ngd.EndDate = @EndDate
				FROM #NameGender ng
				INNER JOIN [Derived].[NameGenderDictionary] ngd
					ON ng.FirstName = ngd.FirstName
					AND ng.InferredGender != ngd.InferredGender

			/***********************************************************************************************************************
				2.2. Insert new entries for First Name entries which have changed gender or have appeared for the first time
			***********************************************************************************************************************/
				
				DECLARE @StartDate DATE = GETDATE()

				INSERT INTO [Derived].[NameGenderDictionary]
				SELECT	FirstName
					,	InferredGender
					,	@StartDate
					,	NULL
				FROM #NameGender ng
				WHERE NOT EXISTS (	SELECT 1
									FROM [Derived].[NameGenderDictionary] ngd
									WHERE ng.FirstName = ngd.FirstName
									AND ngd.EndDate IS NULL)
				ORDER BY FirstName

			EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'

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
			INSERT INTO [Monitor].[ErrorLog] (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END