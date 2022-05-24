CREATE TABLE [Lion].[LionSend_Customers] (
    [ID]              BIGINT       IDENTITY (1, 1) NOT NULL,
    [LionSendID]      INT          NOT NULL,
    [EmailSendDate]   DATE         NOT NULL,
    [CampaignKey]     VARCHAR (15) NULL,
    [CompositeID]     BIGINT       NULL,
    [FanID]           INT          NOT NULL,
    [ClubID]          INT          NULL,
    [IsLoyalty]       BIT          NULL,
    [EmailSent]       BIT          CONSTRAINT [dfv_EmailSent] DEFAULT ((0)) NOT NULL,
    [EmailOpened]     BIT          CONSTRAINT [dfv_EmailOpened] DEFAULT ((0)) NOT NULL,
    [EmailOpenedDate] DATE         NULL,
    CONSTRAINT [pk_LionSendID_FanID] PRIMARY KEY CLUSTERED ([LionSendID] ASC, [FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_LionSendCustomers_LionCampaignClubLoyaltyFan]
    ON [Lion].[LionSend_Customers]([LionSendID] ASC, [CampaignKey] ASC, [ClubID] ASC, [IsLoyalty] ASC, [FanID] ASC) WITH (FILLFACTOR = 90)
    ON [Warehouse_Indexes];

