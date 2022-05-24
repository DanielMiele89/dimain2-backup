CREATE TABLE [Staging].[__Customer_Hardbounced_Reengaged_Archived] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [DateWS]    DATE NOT NULL,
    [DateEmail] DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

