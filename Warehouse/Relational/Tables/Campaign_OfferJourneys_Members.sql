CREATE TABLE [Relational].[Campaign_OfferJourneys_Members] (
    [OfferJourneyID] INT          NOT NULL,
    [FanID]          INT          NOT NULL,
    [Grp]            VARCHAR (10) NOT NULL,
    CONSTRAINT [pk_OJFan] PRIMARY KEY CLUSTERED ([OfferJourneyID] ASC, [FanID] ASC)
);

