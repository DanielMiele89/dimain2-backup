CREATE TABLE [Relational].[Campaign_OfferJourneys] (
    [OfferJourneyID]    INT          IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] VARCHAR (10) NOT NULL,
    [PartnerID]         INT          NOT NULL,
    [IronOfferID]       INT          NOT NULL,
    [StartDate]         DATETIME     NOT NULL,
    [EndDate]           DATETIME     NULL,
    [isJourneyLive]     BIT          NULL,
    CONSTRAINT [pk_OfferJourneyID] PRIMARY KEY CLUSTERED ([OfferJourneyID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_IID]
    ON [Relational].[Campaign_OfferJourneys]([IronOfferID] ASC);

