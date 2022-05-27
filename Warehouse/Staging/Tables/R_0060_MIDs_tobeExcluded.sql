CREATE TABLE [Staging].[R_0060_MIDs_tobeExcluded] (
    [ID]         INT          IDENTITY (1, 1) NOT NULL,
    [MerchantID] VARCHAR (20) NULL,
    [PartnerID]  INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    UNIQUE NONCLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_R_0060_MIDs_tobeExcluded_MID_PartnerID]
    ON [Staging].[R_0060_MIDs_tobeExcluded]([MerchantID] ASC, [PartnerID] ASC);

