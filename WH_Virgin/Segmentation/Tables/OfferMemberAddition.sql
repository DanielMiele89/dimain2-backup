CREATE TABLE [Segmentation].[OfferMemberAddition] (
    [ID]          BIGINT   IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [AddedDate]   DATETIME CONSTRAINT [DF_OMA_AddedDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_OMA] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [IUX_IronOfferStartEndComposite] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW),
    CONSTRAINT [IUX_OMA_IronOfferStartEndComposite] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 70)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Segmentation].[OfferMemberAddition]([IronOfferID] ASC, [StartDate] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW);

