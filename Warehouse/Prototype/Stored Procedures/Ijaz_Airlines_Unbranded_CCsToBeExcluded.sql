


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 13/06/2016
-- Description: Excluding CCID's into exclusion table
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[Ijaz_Airlines_Unbranded_CCsToBeExcluded](
			@CC varchar(MAX))
									
AS

	SET NOCOUNT ON;


DECLARE @ListOfCCs varchar(MAX)
SET		@ListOfCCs = @CC
/************************************************************
********* Brands the required ConsumerCombinationID *********
************************************************************/
IF OBJECT_ID ('tempdb..#CC') IS NOT NULL DROP TABLE #CC
CREATE TABLE #CC (ConsumerCombinationID INT)

	INSERT INTO #CC
	SELECT @ListOfCCs

INSERT INTO	[Staging].[BrandSuggestionRejected] (ConsumerCombinationID)
SELECT		cc.ConsumerCombinationID
FROM		#CC cc
LEFT OUTER JOIN [Staging].[BrandSuggestionRejected] ce
	ON			cc.ConsumerCombinationID = ce.ConsumerCombinationID
WHERE		ce.ConsumerCombinationID IS NULL

UPDATE		[Warehouse].[Staging].[BrandSuggestionRejected]
SET			MID = cc.MID
FROM		[Warehouse].[Staging].[BrandSuggestionRejected] AS bsr
INNER JOIN	Warehouse.Relational.ConsumerCombination AS cc
	ON		cc.ConsumerCombinationID = bsr.ConsumerCombinationID
WHERE		bsr.MID IS NULL

--EXEC [Prototype].[Ijaz_Airlines_Unbranded_CCsToBeExcluded] 2563855