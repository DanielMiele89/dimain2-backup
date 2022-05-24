CREATE TABLE [Relational].[Customer_Loyalty_DD_Nominee] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [Nominee]   BIT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_EndDate]
    ON [Relational].[Customer_Loyalty_DD_Nominee]([EndDate] ASC)
    INCLUDE([ID], [FanID], [Nominee]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_FanID]
    ON [Relational].[Customer_Loyalty_DD_Nominee]([FanID] ASC, [EndDate] ASC)
    INCLUDE([ID], [Nominee]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

