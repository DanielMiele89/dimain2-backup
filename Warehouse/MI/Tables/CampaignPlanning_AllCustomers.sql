CREATE TABLE [MI].[CampaignPlanning_AllCustomers] (
    [CINID]         INT  NOT NULL,
    [FanID]         INT  NOT NULL,
    [ActivatedDate] DATE NULL,
    [MonthofBirth]  INT  NULL,
    [Engaged]       INT  NOT NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_Tactical_FanID]
    ON [MI].[CampaignPlanning_AllCustomers]([FanID] ASC);

