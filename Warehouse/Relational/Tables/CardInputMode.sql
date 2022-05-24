CREATE TABLE [Relational].[CardInputMode] (
    [InputModeID]   TINYINT       IDENTITY (0, 1) NOT NULL,
    [CardInputMode] VARCHAR (1)   NOT NULL,
    [ModeDesc]      VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Relational_CardInputMode] PRIMARY KEY CLUSTERED ([InputModeID] ASC)
);

