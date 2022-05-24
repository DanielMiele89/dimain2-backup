CREATE TABLE [Relational].[Customer_Registered] (
    [ID]         INT  IDENTITY (1, 1) NOT NULL,
    [FanID]      INT  NOT NULL,
    [Registered] BIT  NOT NULL,
    [StartDate]  DATE NOT NULL,
    [EndDate]    DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Customer_Registered_FanID_EndDate]
    ON [Relational].[Customer_Registered]([FanID] ASC, [EndDate] ASC)
    INCLUDE([Registered]);

