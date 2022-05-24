CREATE TABLE [APW].[RetailerPotentialValue_Monthly_BaseSpend] (
    [ID]         INT   IDENTITY (1, 1) NOT NULL,
    [StartDate]  DATE  NULL,
    [EndDate]    DATE  NULL,
    [RetailerID] INT   NULL,
    [Spend]      MONEY NULL,
    CONSTRAINT [PK_RetailerPotentialValue_Monthly_BaseSpend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

