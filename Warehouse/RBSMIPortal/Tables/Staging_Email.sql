CREATE TABLE [RBSMIPortal].[Staging_Email] (
    [ID]             INT          NOT NULL,
    [CampaignKey]    NVARCHAR (8) NOT NULL,
    [FanID]          INT          NOT NULL,
    [SendDate]       DATE         NOT NULL,
    [IsDelivered]    INT          NOT NULL,
    [IsOpened]       INT          NOT NULL,
    [IsUnsubscribed] INT          NOT NULL,
    [IsClicked]      INT          NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_Staging_Email] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
);

