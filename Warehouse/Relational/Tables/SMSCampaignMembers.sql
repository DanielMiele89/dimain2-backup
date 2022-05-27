CREATE TABLE [Relational].[SMSCampaignMembers] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [SMSCampaignID] INT      NULL,
    [FanID]         INT      NOT NULL,
    [Grp]           CHAR (1) NOT NULL,
    CONSTRAINT [pk_SMSCampaignMembers] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_SMSCID]
    ON [Relational].[SMSCampaignMembers]([SMSCampaignID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[SMSCampaignMembers]([FanID] ASC);

