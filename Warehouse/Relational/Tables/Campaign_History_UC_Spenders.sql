CREATE TABLE [Relational].[Campaign_History_UC_Spenders] (
    [FanID]           INT          NOT NULL,
    [IronOfferID]     INT          NOT NULL,
    [HTMID]           INT          NULL,
    [Grp]             VARCHAR (10) NULL,
    [PartnerID]       INT          NOT NULL,
    [SDate]           DATE         NULL,
    [EDate]           DATE         NULL,
    [QualyfingMID]    INT          NOT NULL,
    [QualyfingAmount] INT          NOT NULL,
    CONSTRAINT [UC_Spenders_FanOfferID] PRIMARY KEY CLUSTERED ([FanID] ASC, [IronOfferID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_PartnerID]
    ON [Relational].[Campaign_History_UC_Spenders]([PartnerID] ASC);

