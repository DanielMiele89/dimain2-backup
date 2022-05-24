Create Procedure staging.R_0104_Rejected_OINs_NonBulk
with execute as owner
as
SELECT	o.OIN,
	o.Narrative,
	ISNULL(dd.SupplierName,'No Supplier Name') as SupplierName,
	ISNULL(Ext_SupplierCategory,'No Supplier Category') as SupplierCategory,
	o.StartDate,
	EndDate
FROM Warehouse.Staging.DirectDebit_OINs o
LEFT OUTER JOIN Warehouse.Relational.DD_DataDictionary_Suppliers dd
	ON o.DirectDebit_SupplierID = dd.SupplierID
Left Outer join Warehouse.Staging.RBSGRemovalsBulk as b
	on	o.OIN = b.OIN and
		o.StartDate = b.RemovalDate
WHERE DirectDebit_StatusID = 5 and
		b.OIN is null
ORDER BY Ext_SupplierCategory, SupplierName, StartDate