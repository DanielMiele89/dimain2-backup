CREATE TABLE [Staging].[Homemover] (
    [FanID]       INT         NOT NULL,
    [OldPostCode] VARCHAR (8) NOT NULL,
    [NewPostCode] VARCHAR (8) NOT NULL,
    [LoadDate]    DATE        NOT NULL,
    CONSTRAINT [PK_Homemover] PRIMARY KEY CLUSTERED ([FanID] ASC, [OldPostCode] ASC, [NewPostCode] ASC, [LoadDate] ASC) WITH (FILLFACTOR = 80)
);


GO
GRANT SELECT
    ON OBJECT::[Staging].[Homemover] TO [gas]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Staging].[Homemover] TO [gas]
    AS [dbo];

