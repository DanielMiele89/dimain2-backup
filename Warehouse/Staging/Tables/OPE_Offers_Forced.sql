CREATE TABLE [Staging].[OPE_Offers_Forced] (
    [ForcedID]    INT     IDENTITY (1, 1) NOT NULL,
    [EmailDate]   DATE    NOT NULL,
    [OfferID]     INT     NOT NULL,
    [HTMID]       INT     NULL,
    [ForcedInTop] BIT     NOT NULL,
    [Score]       TINYINT NOT NULL,
    PRIMARY KEY CLUSTERED ([ForcedID] ASC)
);

