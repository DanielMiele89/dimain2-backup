CREATE TABLE [iron].[OfferMemberAddition] (
    [ID]          BIGINT   IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME CONSTRAINT [DF_OfferMember_Date] DEFAULT (getdate()) NULL,
    [IsControl]   BIT      CONSTRAINT [DF_OfferMember_IsControl] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_OfferMember] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE),
    CONSTRAINT [IUX_IronOfferStartEndComposite] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW) ON [Warehouse_Indexes]
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [iron].[OfferMemberAddition]([IronOfferID] ASC, [StartDate] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW)
    ON [Warehouse_Indexes];

