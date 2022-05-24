CREATE TABLE [Relational].[Homemover_Details] (
    [FanID]       INT           NOT NULL,
    [OldPostCode] VARCHAR (8)   NOT NULL,
    [NewPostCode] VARCHAR (8)   NOT NULL,
    [LoadDate]    DATE          NOT NULL,
    [OldAddress1] VARCHAR (100) NULL,
    [OldAddress2] VARCHAR (100) NULL,
    [OldCity]     VARCHAR (100) NULL,
    [OldCounty]   VARCHAR (100) NULL,
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[Homemover_Details]([FanID] ASC);

