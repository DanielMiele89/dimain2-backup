-- =============================================
-- Author:		<Author,,Ajith Asokan>
-- Create date: <Create Date,,18/07/2018>
-- Description:	<Description,,Using the ID field from the table Warehouse.Relational.DirectDebit_OINs to reject certain OIN & Narrative combos>
-- =============================================
CREATE PROCEDURE  [Staging].[DirectDebit_OIN_Reward_Reject_Status] 
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

/*
SET @OIN =(SELECT  OIN
FROM Warehouse.Staging.DirectDebit_OINs
WHERE ID=@ID)
*/

UPDATE Warehouse.Staging.DirectDebit_OINs
	
	SET EndDate=GETDATE()-1

WHERE OIN=@OIN AND EndDate IS NULL


INSERT INTO Staging.DirectDebit_OINs
SELECT	OIN,
	Narrative,
	2 as DirectDebit_StatusID, 
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
