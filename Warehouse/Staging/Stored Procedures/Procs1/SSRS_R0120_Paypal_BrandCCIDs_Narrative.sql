


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 15/04/2016
-- Description: Brand ConsumerCombinationID's with respective narrative.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0120_Paypal_BrandCCIDs_Narrative](
			@Narrative varchar(100)
			)
						
			
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @Narrative2 varchar(100)
SET		@Narrative2 = @Narrative

IF OBJECT_ID ('Staging.R_0120_Paypal_Temp_CCIDs') IS NOT NULL DROP TABLE Staging.R_0120_Paypal_Temp_CCIDs
SELECT	ConsumerCombinationID
INTO	Staging.R_0120_Paypal_Temp_CCIDs
FROM	Relational.ConsumerCombination
WHERE	Narrative LIKE @Narrative2

--IF OBJECT_ID ('Staging.R_0120_Paypal_Temp_BrandID') IS NOT NULL DROP TABLE Staging.R_0120_Paypal_Temp_BrandID
TRUNCATE TABLE Staging.R_0120_Paypal_Temp_BrandID

INSERT INTO Staging.R_0120_Paypal_Temp_BrandID
SELECT	DISTINCT b.BrandID, b.BrandName
FROM	Relational.Brand AS b
	INNER JOIN Relational.ConsumerCombination As cc
	ON	b.BrandID = cc.BrandID
WHERE	Brandname LIKE SUBSTRING(@Narrative2,9,3) + '%'

INSERT INTO Staging.R_0120_Paypal_Temp_BrandID
SELECT	DISTINCT b.BrandID, b.BrandName
FROM	Relational.Brand AS b
	INNER JOIN Relational.ConsumerCombination As cc
	ON	b.BrandID = cc.BrandID
WHERE	Brandname LIKE SUBSTRING(@Narrative2,9,4) + '%'

INSERT INTO Staging.R_0120_Paypal_Temp_BrandID
SELECT	DISTINCT b.BrandID, b.BrandName
FROM	Relational.Brand AS b
	INNER JOIN Relational.ConsumerCombination As cc
	ON	b.BrandID = cc.BrandID
WHERE	Brandname LIKE SUBSTRING(@Narrative2,9,5) + '%'

INSERT INTO Staging.R_0120_Paypal_Temp_BrandID
SELECT	DISTINCT b.BrandID, b.BrandName
FROM	Relational.Brand AS b
	INNER JOIN Relational.ConsumerCombination As cc
	ON	b.BrandID = cc.BrandID
WHERE	Brandname LIKE SUBSTRING(@Narrative2,9,6) + '%'

INSERT INTO Staging.R_0120_Paypal_Temp_BrandID
SELECT	DISTINCT b.BrandID, b.BrandName
FROM	Relational.Brand AS b
	INNER JOIN Relational.ConsumerCombination As cc
	ON	b.BrandID = cc.BrandID
WHERE	Brandname LIKE SUBSTRING(@Narrative2,9,7) + '%'

IF OBJECT_ID ('Staging.R_0120_Paypal_Temp_A1') IS NOT NULL DROP TABLE Staging.R_0120_Paypal_Temp_A1
SELECT ID = 1
INTO Staging.R_0120_Paypal_Temp_A1

SELECT	*
FROM	Staging.R_0120_Paypal_Temp_BrandID
ORDER BY BrandName 

--EXEC [Staging].[SSRS_R0120_Paypal_BrandCCIDs_Narrative2]

END
