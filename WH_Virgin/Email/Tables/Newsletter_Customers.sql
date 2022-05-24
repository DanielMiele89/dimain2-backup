CREATE TABLE [Email].[Newsletter_Customers] (
    [ID]              BIGINT       IDENTITY (1, 1) NOT NULL,
    [LionSendID]      INT          NOT NULL,
    [EmailSendDate]   DATE         NOT NULL,
    [CampaignKey]     VARCHAR (15) NULL,
    [CompositeID]     BIGINT       NULL,
    [FanID]           INT          NOT NULL,
    [ClubID]          INT          NULL,
    [CustomerSegment] VARCHAR (15) NULL,
    [EmailSent]       BIT          CONSTRAINT [dfv_EmailSent] DEFAULT ((0)) NOT NULL,
    [EmailOpened]     BIT          CONSTRAINT [dfv_EmailOpened] DEFAULT ((0)) NOT NULL,
    [EmailOpenedDate] DATE         NULL,
    CONSTRAINT [pk_LionSendID_FanID] PRIMARY KEY CLUSTERED ([LionSendID] ASC, [FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_LionCampaignClubFan]
    ON [Email].[Newsletter_Customers]([LionSendID] ASC, [CampaignKey] ASC, [ClubID] ASC, [FanID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE COLUMNSTORE INDEX [CSX_LionSendCustomers_All]
    ON [Email].[Newsletter_Customers]([LionSendID], [EmailSendDate], [CampaignKey], [CompositeID], [FanID], [ClubID], [CustomerSegment], [EmailSent], [EmailOpened], [EmailOpenedDate]);

