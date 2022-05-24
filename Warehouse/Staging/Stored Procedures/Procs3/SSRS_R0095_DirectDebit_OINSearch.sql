
-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 12/08/2015
-- Description: Finds the current status of an OIN in the database
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0095_DirectDebit_OINSearch] (
			@OIN VARCHAR(200)
			)

AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#OIN') IS NOT NULL DROP TABLE #OIN
CREATE TABLE #OIN (OIN INT)

WHILE @OIN LIKE '%,%'
BEGIN
      INSERT INTO #OIN
      SELECT  SUBSTRING(@OIN,1,CHARINDEX(',',@OIN)-1)
      SET @OIN = (SELECT  SUBSTRING(@OIN,CHARINDEX(',',@OIN)+1,LEN(@OIN)))
END
      INSERT INTO #OIN
      SELECT @OIN


SELECT	ddo.OIN,
	ddo.Narrative,
	ddo.Status_Description as [Status],
	AddedDate,
	InternalCategory1,
	InternalCategory2,
	StartDate,
	EndDate,
	SupplierID,
	SupplierName,
	vc.Narrative as Latest_VocafileNarrative,
	AddresseeName,
	PostalName,
	Address1
FROM Warehouse.Relational.DirectDebit_OINs ddo
INNER JOIN Warehouse.Relational.Vocafile_Latest vc
	ON ddo.OIN = vc.OIN
INNER JOIN #OIN o
      ON o.OIN = vc.OIN



END