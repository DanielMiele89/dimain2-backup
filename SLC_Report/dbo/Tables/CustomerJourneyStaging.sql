CREATE TABLE [dbo].[CustomerJourneyStaging] (
    [FanID]                 INT          NOT NULL,
    [CustomerJourneyStatus] VARCHAR (50) NOT NULL,
    [Date]                  DATE         NOT NULL,
    CONSTRAINT [PK_CustomerJourneyStaging] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

