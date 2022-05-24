CREATE TABLE [Relational].[RedemptionCodesVsItems] (
    [ID]                 INT      IDENTITY (1, 1) NOT NULL,
    [RedeemItemID]       INT      NOT NULL,
    [CodeTypeID]         INT      NOT NULL,
    [CodeTypeMultiplier] TINYINT  NOT NULL,
    [AutoAssignment]     BIT      NOT NULL,
    [StartDate]          DATETIME NULL,
    [EndDate]            DATETIME NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_RedemptionCodesVsItems_RedeemItemID]
    ON [Relational].[RedemptionCodesVsItems]([RedeemItemID] ASC);

