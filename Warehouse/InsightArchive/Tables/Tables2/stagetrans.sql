CREATE TABLE [InsightArchive].[stagetrans] (
    [MatchID]          INT          NOT NULL,
    [PublisherID]      INT          NOT NULL,
    [FanID]            INT          NOT NULL,
    [TranDate]         DATE         NULL,
    [AddedDate]        DATE         NULL,
    [Spend]            SMALLMONEY   NOT NULL,
    [Investment]       SMALLMONEY   NULL,
    [RetailOutletID]   INT          NULL,
    [SourceUID]        VARCHAR (20) NULL,
    [IronOfferID]      INT          NULL,
    [RetailerCashback] SMALLMONEY   NOT NULL,
    [PanID]            INT          NULL,
    [UpstreamMatchID]  INT          NULL
);

