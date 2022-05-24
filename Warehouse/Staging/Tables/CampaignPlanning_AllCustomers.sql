CREATE TABLE [Staging].[CampaignPlanning_AllCustomers] (
    [AllCustomersID] INT  IDENTITY (1, 1) NOT NULL,
    [CINID]          INT  NOT NULL,
    [FanID]          INT  NOT NULL,
    [ActivatedDate]  DATE NULL,
    [DOB]            DATE NULL,
    [Engaged]        BIT  NULL,
    PRIMARY KEY CLUSTERED ([AllCustomersID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_C]
    ON [Staging].[CampaignPlanning_AllCustomers]([CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_F]
    ON [Staging].[CampaignPlanning_AllCustomers]([FanID] ASC);

