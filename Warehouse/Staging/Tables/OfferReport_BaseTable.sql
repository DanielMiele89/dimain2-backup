CREATE TABLE [Staging].[OfferReport_BaseTable] (
    [CINID]             INT   NULL,
    [IronOfferID]       INT   NOT NULL,
    [IronOfferCyclesID] INT   NULL,
    [ControlGroupID]    INT   NOT NULL,
    [StartDate]         DATE  NOT NULL,
    [EndDate]           DATE  NOT NULL,
    [Exposed]           BIT   NOT NULL,
    [isWarehouse]       BIT   NULL,
    [PartnerID]         INT   NULL,
    [UpperValue]        MONEY NOT NULL,
    [SpendStretch]      INT   NULL,
    [offerStartDate]    DATE  NOT NULL,
    [offerEndDate]      DATE  NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OR_BaseTable_Customer]
    ON [Staging].[OfferReport_BaseTable]([CINID] ASC, [StartDate] ASC, [EndDate] ASC, [PartnerID] ASC, [UpperValue] ASC, [SpendStretch] ASC);

