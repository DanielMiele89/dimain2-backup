-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Staging].[DirectDebit_OIN_RBS_Submitted_Status] 
	@OIN INT
 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 

    -- Insert statements for procedure here
SELECT DISTINCT *
FROM Warehouse.Staging.DirectDebit_OINs
WHERE OIN=@OIN


UPDATE Warehouse.Staging.DirectDebit_OINs
	
	SET EndDate=GETDATE()-1

WHERE OIN=@OIN AND EndDate IS NULL


INSERT INTO Staging.DirectDebit_OINs
SELECT	OIN,
	Narrative,
	3 as DirectDebit_StatusID, 
	1 as DirectDebit_AssessmentReasonID, 
	CAST(GETDATE() AS DATE) as AddedDate,
	1 as InternalCategoryID,
	1 as RBSCategoryID, 
	GETDATE() as StartDate,
	NULL as EndDate,
	NULL as DirectDebit_SupplierID --SupplierID from above
FROM Relational.Vocafile_Latest
WHERE OIN=@OIN


SELECT DISTINCT *
FROM Warehouse.Staging.DirectDebit_OINs
WHERE OIN=@OIN

END