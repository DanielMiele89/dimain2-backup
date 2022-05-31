CREATE TABLE [Zoe].[Customer_SchemeMembershipV2] (
    [ID]                     INT     IDENTITY (1, 1) NOT NULL,
    [FanID]                  INT     NOT NULL,
    [SchemeMembershipTypeID] TINYINT NOT NULL,
    [StartDate]              DATE    NOT NULL,
    [EndDate]                DATE    NULL,
    PRIMARY KEY NONCLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

