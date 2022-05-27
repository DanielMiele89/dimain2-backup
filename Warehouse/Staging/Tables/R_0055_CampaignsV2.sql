CREATE TABLE [Staging].[R_0055_CampaignsV2] (
    [RowNo]              BIGINT NULL,
    [SendWeekCommencing] DATE   NULL,
    [LionSendID]         INT    NULL,
    [SendDate]           DATE   NULL,
    [NewOfferRange]      DATE   NULL,
    [Last4Weeks]         DATE   NULL,
    [Last8Weeks]         DATE   NULL
);


GO
CREATE CLUSTERED INDEX [IDX_LS]
    ON [Staging].[R_0055_CampaignsV2]([LionSendID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_SW]
    ON [Staging].[R_0055_CampaignsV2]([SendWeekCommencing] ASC);

