CREATE TABLE [Relational].[CustomerJourney] (
    [FanID]                 INT          NOT NULL,
    [CustomerJourneyStatus] VARCHAR (24) NULL,
    [LapsFlag]              VARCHAR (11) NOT NULL,
    [Date]                  DATE         NULL,
    [Shortcode]             CHAR (3)     NULL,
    [StartDate]             DATE         NULL,
    [EndDate]               DATE         NULL,
    [CustomerJourneyID]     INT          IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([CustomerJourneyID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[CustomerJourney]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CJS]
    ON [Relational].[CustomerJourney]([Shortcode] ASC);

