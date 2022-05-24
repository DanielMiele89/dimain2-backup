CREATE TABLE [Email].[Newsletter_Offers] (
    [ID]            BIGINT IDENTITY (1, 1) NOT NULL,
    [LionSendID]    INT    NOT NULL,
    [EmailSendDate] DATE   NOT NULL,
    [CompositeID]   BIGINT NOT NULL,
    [FanID]         INT    NOT NULL,
    [TypeID]        INT    NOT NULL,
    [ItemID]        INT    NOT NULL,
    [OfferSlot]     INT    NOT NULL,
    CONSTRAINT [pk_ID] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 100)
);


GO
CREATE COLUMNSTORE INDEX [CSX_LionSendOffers_All]
    ON [Email].[Newsletter_Offers]([LionSendID], [EmailSendDate], [CompositeID], [FanID], [TypeID], [ItemID], [OfferSlot]);

