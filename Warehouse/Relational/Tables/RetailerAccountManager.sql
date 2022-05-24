CREATE TABLE [Relational].[RetailerAccountManager] (
    [RetailerID]     INT          NOT NULL,
    [AccountManager] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Relational_RetailerAccountManager] PRIMARY KEY CLUSTERED ([RetailerID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[Relational].[RetailerAccountManager] TO [BIDIMAINETLUser]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Relational].[RetailerAccountManager] TO [BIDIMAINETLUser]
    AS [dbo];

