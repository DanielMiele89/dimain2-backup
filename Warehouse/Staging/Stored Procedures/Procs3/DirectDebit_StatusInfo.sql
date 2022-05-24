
-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 08/06/2016
-- Description: Finds the current status of an OIN in the database
-- ***************************************************************************
CREATE PROCEDURE [Staging].[DirectDebit_StatusInfo]
			(
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



SELECT	o.ID,
	o.OIN,
	o.Narrative,
	s.Status_Description,
	ar.Reason_Description,
	o.AddedDate,
	ci.Category2 as InternalCategoryID,
	ri.Category2 as RBSCategoryID,
	o.StartDate,
	o.EndDate,
	o.DirectDebit_SupplierID,
	ISNULL(ds.SupplierName,'No Supplier Currently Assigned') as SupplierName
FROM Staging.DirectDebit_OINs o
INNER JOIN Staging.DirectDebit_Status s
	ON o.DirectDebit_StatusID = s.ID
INNER JOIN Staging.DirectDebit_AssessmentReason ar
	ON o.DirectDebit_AssessmentReasonID = ar.ID
INNER JOIN Staging.DirectDebit_Categories_Internal ci
	ON o.InternalCategoryID = ci.ID
INNER JOIN Staging.DirectDebit_Categories_Internal ri
	ON o.InternalCategoryID = ri.ID
LEFT OUTER JOIN Relational.DD_DataDictionary_Suppliers ds
	ON o.DirectDebit_SupplierID = ds.SupplierID
INNER JOIN #OIN oi
      ON o.OIN = oi.OIN


END