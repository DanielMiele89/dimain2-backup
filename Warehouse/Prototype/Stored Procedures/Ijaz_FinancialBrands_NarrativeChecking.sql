


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 05/05/2016
-- Description: 
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[Ijaz_FinancialBrands_NarrativeChecking](
			@Narrative varchar(100)
			)
						
			
AS

	SET NOCOUNT ON;

DECLARE @N varchar(100)
SET		@N = @Narrative

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
WHERE		dd.Narrative = @N
GROUP BY	dd.OIN,
			dd.Narrative,
			vl.Narrative,
			vl.AddresseeName,
			vl.PostalName,
			vl.Address1
ORDER BY	TotalAmount DESC

SELECT		*
FROM		Prototype.Ijaz_FinancialBrands_NarrativeTable