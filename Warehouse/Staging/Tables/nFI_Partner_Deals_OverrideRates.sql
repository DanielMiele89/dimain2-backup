CREATE TABLE [Staging].[nFI_Partner_Deals_OverrideRates] (
    [PartnerID]    INT  NULL,
    [ClubID]       INT  NULL,
    [OverrideRate] REAL NULL,
    [IsAddition]   BIT  NULL
);


GO
CREATE CLUSTERED INDEX [idx_OverrideRates_PartnerIDClubID]
    ON [Staging].[nFI_Partner_Deals_OverrideRates]([PartnerID] ASC, [ClubID] ASC);

