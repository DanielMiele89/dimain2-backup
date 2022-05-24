

-- *****************************************************************************************************
-- Author: Ijaz Amjad
-- Create date: 21/03/2016
-- Description: IN-PROGRESS
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[SSRS_R0080_UnbrandedCCsToBeExcluded](
			@CC varchar(MAX))
									
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

While @ListOfCCs like '%,%'
Begin
	Insert into #CC
	Select  SUBSTRING(@ListOfCCs,1,CHARINDEX(',',@ListOfCCs)-1)
	Set @ListOfCCs = (Select  SUBSTRING(@ListOfCCs,CHARINDEX(',',@ListOfCCs)+1,Len(@ListOfCCs)))
End
	Insert into #CC
	Select @ListOfCCs

INSERT INTO [Prototype].[SSRS_R0080_Unbranded_CCsToBeExcluded]
SELECT cc.ConsumerCombinationID
FROM #CC cc
LEFT OUTER JOIN [Prototype].[SSRS_R0080_Unbranded_CCsToBeExcluded] ce
	ON cc.ConsumerCombinationID = ce.ConsumerCombinationID
WHERE ce.ConsumerCombinationID IS NULL

DELETE FROM [Warehouse].[Prototype].[SSRS_R0080_Unbranded_BrandSuggestions]
WHERE ConsumerCombinationID IN (SELECT ConsumerCombinationID
								FROM #CC)