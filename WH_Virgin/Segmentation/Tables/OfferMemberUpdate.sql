CREATE TABLE [Segmentation].[OfferMemberUpdate] (
    [ID]          BIGINT   IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NOT NULL,
    [AddedDate]   DATETIME CONSTRAINT [DF_OMU_Date] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_OMU] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [IUX_OMU_IronOfferStartEndComposite] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 70)
);

