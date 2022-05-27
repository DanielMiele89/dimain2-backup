

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 14/07/2015
-- Description: Shows Job Activity Monitor tasks and reports and how long they take on a daily basis

-- Update:	SB 2017-07-03 - Change Percentage from 3% to 2%
-- ***************************************************************************


CREATE PROCEDURE [Staging].[SSRS_R0089_DD_DataDictionary_Suppliers]
									
AS
BEGIN
	SET NOCOUNT ON;


SELECT	*
FROM	(
	SELECT	SupplierID,
		SupplierName,
		'2%' as CashbackRate
	FROM Warehouse.Relational.DD_DataDictionary_Suppliers
	WHERE RefusedByRBSG = 0
UNION ALL
	SELECT	SupplierID+10000,
		SupplierName,
		'2%' as CashbackRate
	FROM Warehouse.Staging.DD_AlternateName_Suppliers
	)a
ORDER BY SupplierID


END