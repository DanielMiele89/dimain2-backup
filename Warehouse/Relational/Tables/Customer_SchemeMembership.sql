CREATE TABLE [Relational].[Customer_SchemeMembership] (
    [ID]                     INT     IDENTITY (1, 1) NOT NULL,
    [FanID]                  INT     NOT NULL,
    [SchemeMembershipTypeID] TINYINT NOT NULL,
    [StartDate]              DATE    NOT NULL,
    [EndDate]                DATE    NULL,
    PRIMARY KEY NONCLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE CLUSTERED INDEX [cx_FanID]
    ON [Relational].[Customer_SchemeMembership]([FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

