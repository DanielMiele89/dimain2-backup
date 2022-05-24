CREATE TABLE [Relational].[CardInputMode] (
    [InputModeID]   TINYINT       IDENTITY (0, 1) NOT NULL,
    [CardInputMode] VARCHAR (1)   NOT NULL,
    [ModeDesc]      VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Relational_CardInputMode] PRIMARY KEY CLUSTERED ([InputModeID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[Relational].[CardInputMode] TO [visa_etl_user]
    AS [dbo];

