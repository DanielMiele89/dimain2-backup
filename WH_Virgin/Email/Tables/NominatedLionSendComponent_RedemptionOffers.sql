CREATE TABLE [Email].[NominatedLionSendComponent_RedemptionOffers] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [LionSendID]  INT      NULL,
    [CompositeID] BIGINT   NOT NULL,
    [TypeID]      INT      NULL,
    [ItemRank]    INT      NULL,
    [ItemID]      INT      NULL,
    [Date]        DATETIME CONSTRAINT [DF_NominatedLionSendComponentRedemptionOffers_Date] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_NominatedLionSendComponent_RedemptionOffers] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [CHK_NominatedLionSendComponentRedemptionOffers_ItemRank] CHECK ([ItemRank]>(0)),
    CONSTRAINT [IUX_LSIDOfferTypeCompRank] UNIQUE NONCLUSTERED ([LionSendID] ASC, [TypeID] ASC, [CompositeID] ASC, [ItemRank] ASC) WITH (FILLFACTOR = 80)
);

