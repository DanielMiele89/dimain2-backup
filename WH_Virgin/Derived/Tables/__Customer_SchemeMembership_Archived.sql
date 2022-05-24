CREATE TABLE [Derived].[__Customer_SchemeMembership_Archived] (
    [ID]                     INT     IDENTITY (1, 1) NOT NULL,
    [FanID]                  INT     NOT NULL,
    [SchemeMembershipTypeID] TINYINT NOT NULL,
    [StartDate]              DATE    NOT NULL,
    [EndDate]                DATE    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 100)
);

