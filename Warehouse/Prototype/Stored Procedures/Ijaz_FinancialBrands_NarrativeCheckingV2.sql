


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 06/05/2016
-- Description: 
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[Ijaz_FinancialBrands_NarrativeCheckingV2](
			@Narrative varchar(MAX)
			)
						
			
AS

	SET NOCOUNT ON;

DECLARE		@NarrativeList varchar(max)
SET			@NarrativeList = @Narrative

/***************************************************************************
********************* Create table of Narrative List ***********************
***************************************************************************/
CREATE TABLE #Narrative (Narrative varchar(max))

WHILE		@NarrativeList LIKE '%,%'
BEGIN
	INSERT	INTO #Narrative
SELECT SUBSTRING(@NarrativeList,1,CHARINDEX(',',@NarrativeList)-1)
	SET		@NarrativeList = (SELECT  SUBSTRING(@NarrativeList,CHARINDEX(',',@NarrativeList)+1,Len(@NarrativeList)))
END
	INSERT	INTO #Narrative
	SELECT	@NarrativeList


/***************************************************************************
**************** Bring back OIN's and transactional data *******************
***************************************************************************/
TRUNCATE TABLE Prototype.Ijaz_FinancialBrands_NarrativeTable

INSERT INTO	Prototype.Ijaz_FinancialBrands_NarrativeTable
SELECT		dd.OIN,
			dd.Narrative,
			SUM(dd.Amount) AS TotalAmount,
			COUNT(dd.Amount) AS TotalTrans,
			MIN(dd.TranDate) AS FirstTranDate,
			MAX(dd.TranDate) AS LastTranDate,
			vl.Narrative AS Narrative_Vocafile,
			vl.AddresseeName,
			vl.PostalName,
			vl.Address1
FROM		Warehouse.InsightArchive.DD_Data_ForBrandInvestigation AS dd
INNER JOIN	Warehouse.Relational.Vocafile_Latest AS vl
	ON		dd.OIN = vl.OIN
INNER JOIN	#Narrative AS n
	ON		dd.Narrative = n.Narrative
--WHERE		dd.Narrative = @NarrativeList
GROUP BY	dd.OIN,
			dd.Narrative,
			vl.Narrative,
			vl.AddresseeName,
			vl.PostalName,
			vl.Address1
ORDER BY	TotalAmount DESC

SELECT		*
FROM		Prototype.Ijaz_FinancialBrands_NarrativeTable
ORDER BY	Narrative,
			TotalAmount DESC