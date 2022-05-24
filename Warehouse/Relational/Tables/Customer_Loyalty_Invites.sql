CREATE TABLE [Relational].[Customer_Loyalty_Invites] (
    [ID]       INT     IDENTITY (1, 1) NOT NULL,
    [FanID]    INT     NOT NULL,
    [SendDate] DATE    NOT NULL,
    [Channel]  TINYINT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Customer_Loyalty_Invites_FanID]
    ON [Relational].[Customer_Loyalty_Invites]([FanID] ASC);

