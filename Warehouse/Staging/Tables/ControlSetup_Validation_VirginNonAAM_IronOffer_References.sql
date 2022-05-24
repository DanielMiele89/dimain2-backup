CREATE TABLE [Staging].[ControlSetup_Validation_VirginNonAAM_IronOffer_References] (
    [PublisherType]     VARCHAR (50)   NULL,
    [IronOfferID]       INT            NOT NULL,
    [StartDate]         DATE           NOT NULL,
    [EndDate]           DATE           NOT NULL,
    [ClubID]            INT            NULL,
    [IronOfferCyclesID] INT            NULL,
    [ShopperSegmentID]  INT            NULL,
    [SegmentName]       VARCHAR (50)   NULL,
    [OfferTypeID]       INT            NULL,
    [TypeDescription]   VARCHAR (50)   NULL,
    [CashbackRate]      FLOAT (53)     NULL,
    [SpendStretch]      FLOAT (53)     NULL,
    [SpendStretchRate]  FLOAT (53)     NULL,
    [OfferCyclesID]     INT            NULL,
    [controlgroupid]    INT            NULL,
    [IronOfferName]     NVARCHAR (200) NULL,
    CONSTRAINT [PK_ControlSetup_Validation_VirginNonAAM_IronOffer_References] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

