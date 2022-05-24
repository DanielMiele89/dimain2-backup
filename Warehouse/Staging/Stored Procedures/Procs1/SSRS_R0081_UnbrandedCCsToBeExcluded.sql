

-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 22/04/2016
-- Description: Excluding CCID's into exclusion table
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0081_UnbrandedCCsToBeExcluded](
			@CC varchar(MAX))
with execute as owner							
AS

	SET NOCOUNT ON;


----------------------------------------------------------------------------------------
----------------Exclude ConsumerCombinationID(s) that is/are 'BAD DATA'-----------------
----------------------------------------------------------------------------------------
Declare @ListOfCCs varchar(MAX)

Set @ListOfCCs = @CC
-- Insert String of CCID's that you want to be excluded in the [Prototype].[SSRS_R0080_Unbranded_CCsToBeExcluded] Table.
-- e.g. '8443424,30499,1347264'

IF OBJECT_ID ('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Create Table #CC (ConsumerCombinationID INT)

--While @ListOfCCs like '%,%'
--Begin
--	Insert into #CC
--	Select  SUBSTRING(@ListOfCCs,1,CHARINDEX(',',@ListOfCCs)-1)
--	Set @ListOfCCs = (Select  SUBSTRING(@ListOfCCs,CHARINDEX(',',@ListOfCCs)+1,Len(@ListOfCCs)))
--End
	Insert into #CC
	Select @ListOfCCs

INSERT INTO [Staging].[BrandSuggestionRejected] (ConsumerCombinationID)
SELECT cc.ConsumerCombinationID
FROM #CC cc
LEFT OUTER JOIN [Staging].[BrandSuggestionRejected] ce
	ON cc.ConsumerCombinationID = ce.ConsumerCombinationID
WHERE ce.ConsumerCombinationID IS NULL

UPDATE [Warehouse].[Staging].[BrandSuggestionRejected]
SET	MID = cc.MID--,
	--BrandID = cc.BrandID
FROM [Warehouse].[Staging].[BrandSuggestionRejected] AS bsr
INNER JOIN Warehouse.Relational.ConsumerCombination AS cc
	ON cc.ConsumerCombinationID = bsr.ConsumerCombinationID
WHERE bsr.MID IS NULL
	--AND bsr.BrandID IS NULL