

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 01/06/2016
-- Description: This stored procedure is used to update the data within the
--		Staging.DirectDebit_OINs table. This table ultimately decides which
--		OINs will be incentivised on the MyRewards scheme to it is vital that
--		any information added to this table be accurate.
-- *******************************************************************************
CREATE PROCEDURE [Staging].[DirectDebit_OIN_Update]
	(
	@OIN INT,
	@StartDate DATE,
	@EndDate DATE,
	@DirectDebit_StatusID TINYINT,
	@SupplierName VARCHAR(150),
	@Ext_SupplierCategory VARCHAR(50),
	@SupplierWildcard VARCHAR(150),
	@InternalCategoryID TINYINT,
	@RBSCategoryID TINYINT,
	@SupplierRefusedByRBSG BIT
	)
	
		
AS
BEGIN
	SET NOCOUNT ON;


/**********************************************************************************/
--**If we are incentivising a New OIN then we need to End Date the previous record
UPDATE Staging.DirectDebit_OINs
SET	EndDate = @EndDate
WHERE	OIN IN (@OIN)
	AND EndDate IS NULL


/**********************************************************************************/
--**Now we need to check if there is already a Supplier in the table for that OIN
--**If not we have to add a new record in the DD_DataDictionary_Suppliers table
IF (SELECT 1 FROM Relational.DD_DataDictionary_Suppliers WHERE	SupplierName IN (@SupplierName)) IS NULL

BEGIN
--**If you want to add a new supplier you can do so using the following script
--**FYI - a supplierID will be autogenorated

/*
Energy
Media
Local Authorities
*/
INSERT INTO Relational.DD_DataDictionary_Suppliers
SELECT	@SupplierName as SupplierName,
	@Ext_SupplierCategory as Ext_SupplierCategory,
	@SupplierRefusedByRBSG as RefusedByRBSG -- If this is set to 1, it will not show up on the Supplier List sent to RBSG


DECLARE @SupplierID SMALLINT
SET @SupplierID = (SELECT TOP 1 SupplierID FROM Relational.DD_DataDictionary_Suppliers ORDER BY SupplierID DESC)

/**********************************************************************************/
--**Now we need to check if there is already a Supplier in the table for that OIN
--**If not we have to add a new record in the DD_DataDictionary_Suppliers table
INSERT INTO Relational.DD_DataDictionary_SupplierLookUp
SELECT	@SupplierID as SupplierID,
	@SupplierWildcard as SupplierWildcard

END


DECLARE @SupplierID_2 SMALLINT
SET @SupplierID_2 = (SELECT SupplierID FROM Relational.DD_DataDictionary_Suppliers WHERE SupplierName = @SupplierName)


INSERT INTO Staging.DirectDebit_OINs
SELECT	OIN,
	Narrative,
	@DirectDebit_StatusID as DirectDebit_StatusID, 
	1 as DirectDebit_AssessmentReasonID, 
	CAST(GETDATE() AS DATE) as AddedDate,
	@InternalCategoryID as InternalCategoryID,
	@RBSCategoryID as RBSCategoryID, 
	@StartDate as StartDate,
	NULL as EndDate,
	@SupplierID_2 as DirectDebit_SupplierID --SupplierID from above
FROM Relational.Vocafile_Latest
WHERE OIN = @OIN


END