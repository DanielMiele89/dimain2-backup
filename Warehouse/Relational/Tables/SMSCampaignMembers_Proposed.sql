CREATE TABLE [Relational].[SMSCampaignMembers_Proposed] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [SMSCampaignID] INT      NULL,
    [FanID]         INT      NOT NULL,
    [Grp]           CHAR (1) NOT NULL,
    CONSTRAINT [pk_SMSCampaignMembers_Proposed] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_SMSCID]
    ON [Relational].[SMSCampaignMembers_Proposed]([SMSCampaignID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[SMSCampaignMembers_Proposed]([FanID] ASC);

