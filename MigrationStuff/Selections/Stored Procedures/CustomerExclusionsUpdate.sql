CREATE PROCEDURE [Selections].[CustomerExclusionsUpdate]
AS
	BEGIN

		IF OBJECT_ID('tempdb..#ROC_CycleDates') IS NOT NULL DROP TABLE #ROC_CycleDates
		SELECT StartDate, EndDate
		INTO #ROC_CycleDates
		FROM [Warehouse].[Relational].[ROC_CycleDates]
		UNION
		SELECT DATEADD(day, 14, StartDate), DATEADD(day, 14, EndDate)
		FROM [Warehouse].[Relational].[ROC_CycleDates]

		DECLARE @StartDate DATE = (SELECT MIN(StartDate) FROM #ROC_CycleDates WHERE StartDate > GETDATE())
			  , @EndDate DATE = (SELECT MIN(EndDate) FROM #ROC_CycleDates WHERE EndDate > GETDATE())
			  
		UPDATE ce
		SET ce.EndDate = @EndDate
		FROM [Selections].[CustomerExclusions] ce
		WHERE NOT EXISTS (SELECT 1 FROM [Staging].[CustomerExclusions] sel WHERE ce.ClubID = sel.ClubID AND ce.PartnerID = sel.PartnerID AND ce.SourceUID = sel.SourceUID)
		AND ce.EndDate IS NULL
	  
		INSERT INTO [Selections].[CustomerExclusions]
		SELECT PartnerID
			 , ClubID
			 , SourceUID
			 , @StartDate
			 , NULL
		FROM nFI.Staging.[CustomerExclusions] ce
		WHERE NOT EXISTS (SELECT 1 FROM [Selections].[CustomerExclusions] sel WHERE ce.ClubID = sel.ClubID AND ce.PartnerID = sel.PartnerID AND ce.SourceUID = sel.SourceUID AND sel.EndDate IS NULL)

	END