CREATE TABLE [Staging].[Campaign_History] (
    [RowNo]        INT          IDENTITY (1, 1) NOT NULL,
    [Compositeid]  BIGINT       NOT NULL,
    [FanID]        INT          NOT NULL,
    [IronOfferID]  INT          NOT NULL,
    [HTMID]        INT          NULL,
    [Grp]          VARCHAR (10) NULL,
    [PartnerID]    INT          NOT NULL,
    [SDate]        DATE         NULL,
    [EDate]        DATE         NULL,
    [Comm Type]    VARCHAR (1)  NULL,
    [IsGasTrigger] BIT          NULL,
    [TriggerBatch] VARCHAR (5)  NULL,
    PRIMARY KEY CLUSTERED ([RowNo] ASC)
);

