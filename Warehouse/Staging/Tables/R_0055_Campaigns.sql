CREATE TABLE [Staging].[R_0055_Campaigns] (
    [RowNo]         BIGINT NULL,
    [LionSendID]    INT    NULL,
    [SendDate]      DATE   NULL,
    [NewOfferRange] DATE   NULL
);


GO
CREATE CLUSTERED INDEX [IDX_LS]
    ON [Staging].[R_0055_Campaigns]([LionSendID] ASC);

