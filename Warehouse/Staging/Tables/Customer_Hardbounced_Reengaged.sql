CREATE TABLE [Staging].[Customer_Hardbounced_Reengaged] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [DateWS]    DATE NOT NULL,
    [DateEmail] DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_FanIDDateWS]
    ON [Staging].[Customer_Hardbounced_Reengaged]([FanID] ASC, [DateWS] ASC) WITH (FILLFACTOR = 80);

