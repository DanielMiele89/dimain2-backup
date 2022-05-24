

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 27/07/2015
-- Description: Shows OINs which need to be assessed
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0092_DirectDebit_OINs_ToBeAssessed_V1_1] @Type int
									
AS
BEGIN
	SET NOCOUNT ON;


SELECT	OIN,
	Narrative,
	dds.Status_Description as DirectDebitStatus,
	dda.Reason_Description as AssessmentReason,
	AddedDate,
	StartDate,
	EndDate,
	Case
		When dci.Category2 is NULL then dci.Category1
		Else dci.Category1+ ' - '+dci.Category2
	End as RewardCategory,
	Case
		When RBS.Category2 is NULL then RBS.Category1
		Else RBS.Category1+ ' - '+RBS.Category2
	End as RBSCategory
FROM Warehouse.Staging.DirectDebit_OINs do
INNER JOIN Warehouse.Staging.DirectDebit_Status dds
	ON do.DirectDebit_StatusID = dds.ID
INNER JOIN Warehouse.Staging.DirectDebit_AssessmentReason dda
	ON dda.ID = do.DirectDebit_AssessmentReasonID
INNER JOIN Warehouse.Staging.DirectDebit_Categories_Internal dci
	ON dci.ID = do.InternalCategoryID
INNER JOIN Warehouse.Staging.DirectDebit_Categories_RBS RBS
	ON RBS.ID = do.InternalCategoryID

WHERE	DirectDebit_StatusID = @Type
	AND EndDate IS NULL
ORDER BY OIN


END