CREATE TABLE [APW].[DirectLoad_PartnerDeals] (
    [ID]             SMALLINT   IDENTITY (1, 1) NOT NULL,
    [PublisherID]    INT        NOT NULL,
    [PartnerID]      INT        NOT NULL,
    [StartDate]      DATE       NOT NULL,
    [EndDate]        DATE       NOT NULL,
    [Exclude]        BIT        NOT NULL,
    [PublisherShare] FLOAT (53) NOT NULL,
    [RewardShare]    FLOAT (53) NOT NULL,
    CONSTRAINT [PK_APW_PartnerDeals] PRIMARY KEY CLUSTERED ([ID] ASC)
);

