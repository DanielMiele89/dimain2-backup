
CREATE VIEW [dbo].[PartnerCommissionRule]
AS
SELECT ID, PartnerID, TypeID, CommissionRate, [Status], [Priority], CreationDate, CreationStaffID, DeletionDate, DeletionStaffID, StartDate, EndDate
	, RequiredMinimumBasketSize, RequiredMaximumBasketSize, RequiredChannel, RequiredBinRange, RequiredMinimumHourOfDay, RequiredMaximumHourOfDay
	, RequiredMerchantID, RequiredIronOfferID, RequiredRetailOutletID, MaximumUsesPerFan, RequiredNumberOfPriorTransactions, RequiredClubID, RequiredCardholderPresence
FROM SLC_Snapshot.dbo.PartnerCommissionRule

GO
GRANT SELECT
    ON OBJECT::[dbo].[PartnerCommissionRule] TO [virgin_etl_user]
    AS [dbo];

