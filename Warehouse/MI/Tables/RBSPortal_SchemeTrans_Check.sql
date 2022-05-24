CREATE TABLE [MI].[RBSPortal_SchemeTrans_Check] (
    [MatchID]        INT      NOT NULL,
    [FanID]          INT      NOT NULL,
    [Spend]          MONEY    NOT NULL,
    [Earnings]       MONEY    NOT NULL,
    [AddedDate]      DATE     NOT NULL,
    [BrandID]        SMALLINT NOT NULL,
    [OfferAboveBase] BIT      NOT NULL,
    CONSTRAINT [MI_RBSPortal_SchemeTrans_Check] PRIMARY KEY CLUSTERED ([MatchID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

