CREATE TABLE [Zoe].[Customer_SchemeMembership] (
    [ID]                     INT     NOT NULL,
    [FanID]                  INT     NOT NULL,
    [SchemeMembershipTypeID] TINYINT NOT NULL,
    [StartDate]              DATE    NOT NULL,
    [EndDate]                DATE    NULL,
    PRIMARY KEY NONCLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

