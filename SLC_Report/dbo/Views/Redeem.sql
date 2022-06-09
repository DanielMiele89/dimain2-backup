

CREATE VIEW [dbo].[Redeem]
AS
SELECT ID, SupplierID, [Description], [Status], Price, LimitedAvailability, Privatedescription, FulfillmentTypeId, StartDate, EndDate
	, MemberImport, CashbackPercent, ValidityDays, EmailTemplate, IsElectronic, WarningStockThreshold, CurrentStockLevel
FROM SLC_Snapshot.dbo.Redeem
