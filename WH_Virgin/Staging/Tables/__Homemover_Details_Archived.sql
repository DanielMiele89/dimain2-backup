CREATE TABLE [Staging].[__Homemover_Details_Archived] (
    [FanID]       INT           NOT NULL,
    [OldPostCode] VARCHAR (8)   NOT NULL,
    [NewPostCode] VARCHAR (8)   NOT NULL,
    [LoadDate]    DATE          NOT NULL,
    [OldAddress1] VARCHAR (100) NULL,
    [OldAddress2] VARCHAR (100) NULL,
    [OldCity]     VARCHAR (100) NULL,
    [OldCounty]   VARCHAR (100) NULL
);

