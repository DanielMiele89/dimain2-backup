

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 27/07/2015
-- Description: Shows OINs which need to be assessed
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0092_DirectDebit_OINs_ToBeAssessed] 
									
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
	dci.Category1 as RewardCategory
FROM Warehouse.Staging.DirectDebit_OINs do
INNER JOIN Warehouse.Staging.DirectDebit_Status dds
	ON do.DirectDebit_StatusID = dds.ID
INNER JOIN Warehouse.Staging.DirectDebit_AssessmentReason dda
	ON dda.ID = do.DirectDebit_AssessmentReasonID
INNER JOIN Warehouse.Staging.DirectDebit_Categories_Internal dci
	ON dci.ID = do.InternalCategoryID
WHERE	DirectDebit_StatusID = 1
	AND EndDate IS NULL
ORDER BY OIN


END