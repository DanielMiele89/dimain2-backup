CREATE TABLE [Staging].[WRF_654_FanPartner] (
    [FP_ID]     INT IDENTITY (1, 1) NOT NULL,
    [FanID]     INT NOT NULL,
    [PartnerID] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([FP_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Staging].[WRF_654_FanPartner]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PartnerID]
    ON [Staging].[WRF_654_FanPartner]([PartnerID] ASC);

