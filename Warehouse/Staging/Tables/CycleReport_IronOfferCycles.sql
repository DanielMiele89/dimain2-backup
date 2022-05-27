CREATE TABLE [Staging].[CycleReport_IronOfferCycles] (
    [ID]                 INT          IDENTITY (1, 1) NOT NULL,
    [RetailerAnalysisID] INT          NOT NULL,
    [RetailerID]         INT          NOT NULL,
    [StartDate]          DATE         NOT NULL,
    [EndDate]            DATE         NOT NULL,
    [IsBespoke]          BIT          NOT NULL,
    [IronOfferID]        INT          NOT NULL,
    [IronOfferCyclesID]  INT          NULL,
    [PublisherGroupName] VARCHAR (40) NULL,
    CONSTRAINT [PK_CycleReport_IronOfferCycles] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [AK_CycleReport_IronOfferCycles] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [IronOfferCyclesID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CycleReport_IronOfferCycles]
    ON [Staging].[CycleReport_IronOfferCycles]([IronOfferID] ASC, [IronOfferCyclesID] ASC, [PublisherGroupName] ASC);

